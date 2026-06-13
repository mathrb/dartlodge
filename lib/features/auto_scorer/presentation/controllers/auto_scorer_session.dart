import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/predicted_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/diagnostics/pipeline_timings.dart';
import 'package:dart_lodge/features/auto_scorer/domain/preprocessing/frame_preprocessor.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_recorder.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';

/// Result of feeding one camera frame through the session.
class SessionFrameResult {
  /// Darts newly confirmed+emitted this frame, to submit to the active game.
  final List<ScoredDart> emittedDarts;
  final TrackerStatus status;

  /// Stage timings for this frame (detect + track measured here; capture is
  /// filled in by the camera caller). Currently unread — the diagnostics HUD
  /// that surfaced them was removed; kept on the result for now to avoid
  /// churning the session's public shape.
  final PipelineTimings timings;

  /// Best confidence per cal class `[cal1..cal4]` this frame (null = absent),
  /// for the calibration overlay's per-cal confidence readout.
  final List<double?> calConfidences;

  /// The dart-in-turn ordinal (1-based) of the FIRST dart emitted this frame, or
  /// null when none emitted. Captured synchronously at emission time so the
  /// async capture path ([persistEmittedDarts]) labels handles correctly even if
  /// another frame advances the tracker before its `capturePhoto()` resolves.
  final int? firstEmittedDartOrdinal;

  const SessionFrameResult({
    required this.emittedDarts,
    required this.status,
    this.timings = const PipelineTimings(),
    this.calConfidences = const [null, null, null, null],
    this.firstEmittedDartOrdinal,
  });
}

/// Orchestrates the assist-mode pipeline (#382): a camera frame → [DartDetector]
/// → [DartTracker] → emitted darts, plus per-dart training capture. Pure glue
/// over the (web-stubbed) detector and the pure tracker, so it is unit-testable
/// with a fake detector; the camera plumbing lives in the capture page.
///
/// The session never advances the turn and never talks to the game directly —
/// it returns the darts to emit; the caller submits them via the core
/// `DartInputSink`. Turn ownership / ordinals are supplied by the caller.
class AutoScorerSession {
  AutoScorerSession({
    DartDetector? detector,
    FramePreprocessor? preprocessor,
    DartTracker? tracker,
    CaptureStore? captureStore,
    String modelVersion = 'unknown',
    SessionTraceStore? traceStore,
    String? recordingSessionId,
    String recordingGameId = '',
    DateTime? recordingStartedAt,
  })  : _detector = detector,
        _tracker = tracker ?? DartTracker(),
        _captureStore = captureStore,
        _preprocessor = preprocessor,
        _modelVersion = modelVersion,
        // The detector-backed path ([onFrame]/[captureCurrentFrame]) letterboxes
        // via the preprocessor, so the two must be provided together.
        assert(detector == null || preprocessor != null,
            'a detector-backed session also needs a preprocessor') {
    // Session-trace recording (#490) is opt-in: only wired when the caller
    // supplies a store + session id. The recorder captures the tracker's config
    // (the same instance this session drives) so a replay reconstructs it.
    if (traceStore != null && recordingSessionId != null) {
      _recordingStore = traceStore;
      _recordingSessionId = recordingSessionId;
      _recorder = SessionRecorder(
        header: SessionTraceHeader(
          modelVersion: modelVersion,
          gameId: recordingGameId,
          startedAt: recordingStartedAt ?? DateTime.now(),
        ),
        config: _tracker.config,
      );
    }
  }

  /// Predict-detector path (takePicture → [DartDetector.detect]). Null for the
  /// YOLOView streaming path, which computes [DetectionFrame]s natively and feeds
  /// them via [processDetectionFrame] — so no predict model is loaded. The
  /// detector-backed methods ([onFrame]/[detectOnly]/[captureCurrentFrame])
  /// require it to be non-null.
  final DartDetector? _detector;
  final DartTracker _tracker;
  final CaptureStore? _captureStore;
  final FramePreprocessor? _preprocessor;
  final String _modelVersion;

  /// Session-trace recording (#490), null unless opt-in is on. Accumulates the
  /// per-frame detection stream in memory; flushed to [_recordingStore] on
  /// [dispose].
  SessionRecorder? _recorder;
  SessionTraceStore? _recordingStore;
  String? _recordingSessionId;

  /// Keep the most recent N recorded sessions on the device (#490).
  static const int _sessionRetention = 20;

  /// Physical darts currently tracked on the board.
  int get dartsOnBoard => _tracker.confirmedDarts.length;

  /// Default storage cap for captured frames (#381 §6): keep the data set
  /// bounded; corrected/emitted frames are pruned last (see [RetentionPolicy]).
  static const int _retentionBytes = 250 * 1024 * 1024; // 250 MB

  /// Load the model and prune old captures to stay within the storage cap.
  /// Returns true on success (false on the web stub).
  Future<bool> start() async {
    // YOLOView path has no predict detector (it loads its own model natively),
    // so a null detector is "loaded": we still prune captures to the cap.
    final loaded = await _detector?.load() ?? true;
    if (loaded) {
      await _captureStore
          ?.enforceRetention(const RetentionPolicy(maxBytes: _retentionBytes));
    }
    return loaded;
  }

  /// Feed one raw camera frame. [turnOrdinal] is the current 1-based turn; when
  /// [collectData] is set and a capture store is present, each emitted dart's
  /// frame + sidecar is stored keyed by `(turn, dart-in-turn)`.
  Future<SessionFrameResult> onFrame(
    Uint8List frameBytes, {
    required int turnOrdinal,
    required String gameId,
    bool collectData = false,
    bool skipPreprocess = false,
    double calConfidence = 0.25,
    double dartConfidence = 0.25,
  }) async {
    final detectWatch = Stopwatch()..start();
    final frame = await _detector!.detect(
      frameBytes,
      skipPreprocess: skipPreprocess,
      calConfidence: calConfidence,
      dartConfidence: dartConfidence,
    );
    detectWatch.stop();
    final trackWatch = Stopwatch()..start();
    final update = _tracker.processFrame(frame);
    trackWatch.stop();

    if (collectData && _captureStore != null && update.newDarts.isNotEmpty) {
      // Store the image in the SAME space the detector's coords are normalised
      // to (raw-capture brief): in skip mode the plugin maps detections to the
      // raw frame, so store `frameBytes` verbatim (no re-encode); otherwise
      // store our 800×800 letterbox. The sidecar's frameSpace/dims record which.
      // Null when no aligned capture is possible (see [_captureFor]).
      final capture = _captureFor(frameBytes, skipPreprocess: skipPreprocess);
      if (capture != null) {
        // The dart-in-turn ordinal of the first new dart this frame (1-based).
        final firstOrdinal = _tracker.dartsThisTurn - update.newDarts.length + 1;
        for (var i = 0; i < update.newDarts.length; i++) {
          await _captureStore.save(
            _recordFor(
              frame,
              gameId,
              CaptureHandle(
                  turnOrdinal: turnOrdinal, dartInTurnOrdinal: firstOrdinal + i),
              capture,
              trigger: CaptureTrigger.auto,
            ),
            capture.bytes,
          );
        }
      }
    }

    return SessionFrameResult(
      emittedDarts: [for (final d in update.newDarts) d.score],
      status: update.status,
      timings: PipelineTimings(
        detect: detectWatch.elapsed,
        track: trackWatch.elapsed,
      ),
      calConfidences: frame.calConfidences,
    );
  }

  /// Detection-only pass for the aim/framing overlay: runs the model and returns
  /// its raw [DetectionFrame] (cal points + per-cal best positions/confidences +
  /// candidates) WITHOUT touching the tracker, emitting darts, or capturing
  /// frames. The single detection entry point the aim view uses so the widget
  /// never imports the detector. [skipPreprocess]/[calConfidence]/
  /// [dartConfidence] thread through exactly as [onFrame].
  Future<DetectionFrame> detectOnly(
    Uint8List frameBytes, {
    bool skipPreprocess = false,
    double calConfidence = 0.25,
    double dartConfidence = 0.25,
  }) {
    return _detector!.detect(
      frameBytes,
      skipPreprocess: skipPreprocess,
      calConfidence: calConfidence,
      dartConfidence: dartConfidence,
    );
  }

  /// Force-capture the current frame for training data (#382) — for darts the
  /// model **missed** (no emission), the highest-value samples. Stores the frame
  /// in the detector's coordinate space (raw in skip mode, 800×800 letterbox
  /// otherwise — see [onFrame]) + whatever the detector found this frame (often
  /// empty), under a manual handle. Out-of-band: does not touch the tracker or
  /// emit. No-op without a capture store. Returns true if a frame was stored.
  Future<bool> captureCurrentFrame(
    Uint8List frameBytes, {
    required int turnOrdinal,
    required String gameId,
    bool skipPreprocess = false,
    double calConfidence = 0.25,
    double dartConfidence = 0.25,
  }) async {
    final store = _captureStore;
    if (store == null) return false;
    final frame = await _detector!.detect(
      frameBytes,
      skipPreprocess: skipPreprocess,
      calConfidence: calConfidence,
      dartConfidence: dartConfidence,
    );
    final capture = _captureFor(frameBytes, skipPreprocess: skipPreprocess);
    if (capture == null) return false;
    _manualSequence += 1;
    await store.save(
      _recordFor(
        frame,
        gameId,
        CaptureHandle.manual(turnOrdinal: turnOrdinal, sequence: _manualSequence),
        capture,
        trigger: CaptureTrigger.manual,
      ),
      capture.bytes,
    );
    return true;
  }

  int _manualSequence = 0;
  int _correctionSequence = 0;

  /// Manual next-turn pressed: reset the per-turn cap counter. Recorded so a
  /// replay resets the cap at the same point (#491).
  void onTurnAdvanced() {
    _tracker.onTurnAdvanced();
    _recorder?.recordSignal(TrackerSignalKind.turnAdvanced);
  }

  /// Manual "remove darts": re-baseline the tracker; returns the resulting
  /// status (phase `rebaselined`) so the caller can refresh the chip. Recorded
  /// so a replay re-baselines at the same point (#491).
  TrackerStatus removeDarts() {
    final status = _tracker.removeDarts().status;
    _recorder?.recordSignal(TrackerSignalKind.removeDarts);
    return status;
  }

  /// YOLOView path: feed an already-computed [DetectionFrame] (native streaming
  /// inference) through the tracker — no predict detector. Returns the darts to
  /// emit + status + cal confidences. Capture is separate ([persistEmittedDarts])
  /// so `capturePhoto()` is only grabbed on emission, off the hot path.
  SessionFrameResult processDetectionFrame(
    DetectionFrame frame, {
    List<RawDetection> rawDetections = const [],
    double calConfidence = 0.25,
    double dartConfidence = 0.25,
  }) {
    final trackWatch = Stopwatch()..start();
    final update = _tracker.processFrame(frame);
    trackWatch.stop();
    // Record the raw (pre-filter) detections + thresholds + outcome for replay
    // (#490). recordFrame is an O(1) in-memory append — no I/O on the hot path;
    // a null recorder (recording off) makes this a no-op.
    _recorder?.recordFrame(
      detections: rawDetections,
      calMinConfidence: calConfidence,
      dartMinConfidence: dartConfidence,
      update: update,
    );
    final emitted = update.newDarts.length;
    return SessionFrameResult(
      emittedDarts: [for (final d in update.newDarts) d.score],
      status: update.status,
      timings: PipelineTimings(track: trackWatch.elapsed),
      calConfidences: frame.calConfidences,
      // Snapshot the ordinal NOW (synchronously), before any async capture.
      firstEmittedDartOrdinal:
          emitted == 0 ? null : _tracker.dartsThisTurn - emitted + 1,
    );
  }

  /// Store training frames for the [count] darts emitted on the just-processed
  /// [frame] (YOLOView path): [bytes] is the clean full-resolution still from
  /// `YOLOViewController.capturePhoto(withOverlays: false)` — no baked-in
  /// overlay, no preview-crop. Tagged `FrameSpace.raw` with dims 0 — coord-space
  /// alignment for YOLOView captures is an open question (lab precedent). No-op
  /// without a capture store or when [count] <= 0. Mirrors the dart-in-turn
  /// ordinal math in [onFrame].
  Future<void> persistEmittedDarts(
    DetectionFrame frame,
    Uint8List bytes, {
    required int turnOrdinal,
    required int firstDartOrdinal,
    required String gameId,
    required int count,
  }) async {
    final store = _captureStore;
    if (store == null || count <= 0) return;
    // [firstDartOrdinal] is snapshotted at emission time (SessionFrameResult)
    // rather than re-read from the tracker here, which could have advanced
    // during the caller's async capturePhoto() await.
    final capture =
        _Capture(bytes: bytes, space: FrameSpace.raw, width: 0, height: 0);
    for (var i = 0; i < count; i++) {
      await store.save(
        _recordFor(
          frame,
          gameId,
          CaptureHandle(
              turnOrdinal: turnOrdinal, dartInTurnOrdinal: firstDartOrdinal + i),
          capture,
          trigger: CaptureTrigger.auto,
        ),
        bytes,
      );
    }
  }

  /// Manual training capture for the YOLOView path (the "capture photo" button):
  /// stores [bytes] + the current [frame]'s detections under a manual handle.
  /// `FrameSpace.raw`, dims 0 (as [persistEmittedDarts]). Returns false without a
  /// capture store.
  Future<bool> persistManualCapture(
    DetectionFrame frame,
    Uint8List bytes, {
    required int turnOrdinal,
    required String gameId,
  }) async {
    final store = _captureStore;
    if (store == null) return false;
    _manualSequence += 1;
    await store.save(
      _recordFor(
        frame,
        gameId,
        CaptureHandle.manual(turnOrdinal: turnOrdinal, sequence: _manualSequence),
        _Capture(bytes: bytes, space: FrameSpace.raw, width: 0, height: 0),
        trigger: CaptureTrigger.manual,
      ),
      bytes,
    );
    return true;
  }

  /// Propagate a user dart-correction (#456) into the matching capture: flip
  /// its sidecar's `was_corrected` and record the corrected [segment]. Keyed by
  /// the dart handle `t<turnOrdinal>-d<dartInTurnOrdinal>` — corrections only
  /// target the current turn, so [turnOrdinal] is the overlay's live counter.
  /// No-op without a capture store, and `applyCorrection` itself no-ops if no
  /// sidecar matches the handle. The corrected dart carries no position (the
  /// game knows only the segment); the model's detected positions remain in the
  /// sidecar's `predicted_darts`.
  Future<void> applyDartCorrection({
    required String gameId,
    required int turnOrdinal,
    required int dartInTurnOrdinal,
    required String segment,
  }) async {
    final store = _captureStore;
    if (store == null) return;
    await store.applyCorrection(
      gameId,
      CaptureHandle(
          turnOrdinal: turnOrdinal, dartInTurnOrdinal: dartInTurnOrdinal),
      [CorrectedDart(x: 0, y: 0, segment: segment)],
    );
  }

  /// Partial capture-mode (#457): save a NEW corrected capture at correction
  /// time. Used when nothing was persisted at emission, so there is no sidecar
  /// for [applyDartCorrection] to rewrite — instead we store the current [frame]
  /// + [bytes] already flagged `was_corrected` with the corrected [segment].
  /// `trigger: auto` (the dart was auto-detected; the correction is separate
  /// metadata). No-op without a capture store.
  ///
  /// Keyed by a monotonic per-session correction sequence (`t<turn>-c<seq>`),
  /// NOT `(turn, dart)`: the overlay's turn proxy doesn't track the game's
  /// internal turn advances, so a `(turn, dart)` key collides across real turns
  /// and `save` overwrites — every correction must yield its own frame (#468
  /// follow-up). [turnOrdinal] is kept only as a label/context on the key.
  Future<void> persistCorrectedCapture({
    required DetectionFrame frame,
    required Uint8List bytes,
    required int turnOrdinal,
    required String gameId,
    required String segment,
  }) async {
    final store = _captureStore;
    if (store == null) return;
    _correctionSequence += 1;
    final capture =
        _Capture(bytes: bytes, space: FrameSpace.raw, width: 0, height: 0);
    final record = _recordFor(
      frame,
      gameId,
      CaptureHandle.corrected(
          turnOrdinal: turnOrdinal, sequence: _correctionSequence),
      capture,
      trigger: CaptureTrigger.auto,
    ).withCorrection([CorrectedDart(x: 0, y: 0, segment: segment)]);
    await store.save(record, bytes);
  }

  Future<void> dispose() async {
    await _flushRecording();
    await _detector?.dispose();
  }

  /// Persist the recorded session trace (#490), then prune to the retention cap.
  /// Best-effort + guarded: a failed write must never disrupt teardown or
  /// scoring. No-op when recording is off or nothing was recorded.
  Future<void> _flushRecording() async {
    final store = _recordingStore;
    final id = _recordingSessionId;
    final recorder = _recorder;
    if (store == null || id == null || recorder == null) return;
    if (recorder.frameCount == 0) return;
    try {
      await store.save(id, recorder.build());
      await store.enforceRetention(keepLast: _sessionRetention);
    } catch (_) {
      // Swallow: recording is a debugging aid, never a scoring dependency.
    }
  }

  /// Resolve the bytes to store + their coordinate space/dims for the sidecar,
  /// or null when no capture can be stored with coords that align to the image.
  /// skip → raw frame verbatim (`raw`); otherwise our 800×800 letterbox
  /// (`letterbox800`). In non-skip mode the detector's coords are normalised to
  /// the 800 letterbox, so if the frame can't be re-encoded we return null
  /// rather than store the raw bytes under a `letterbox800` label (the coords
  /// would misalign — the very corruption this path avoids). Dims come from the
  /// codec via the [FramePreprocessor] contract.
  _Capture? _captureFor(Uint8List frameBytes, {required bool skipPreprocess}) {
    if (skipPreprocess) {
      final dims = _preprocessor!.dimensionsOf(frameBytes);
      return _Capture(
        bytes: frameBytes,
        space: FrameSpace.raw,
        width: dims?.width ?? 0,
        height: dims?.height ?? 0,
      );
    }
    final letterboxed = _preprocessor!.preprocessEncoded(frameBytes);
    if (letterboxed == null) return null;
    final dims = _preprocessor.dimensionsOf(letterboxed);
    return _Capture(
      bytes: letterboxed,
      space: FrameSpace.letterbox800,
      width: dims?.width ?? 800,
      height: dims?.height ?? 800,
    );
  }

  CaptureRecord _recordFor(DetectionFrame frame, String gameId,
          CaptureHandle handle, _Capture capture,
          {required CaptureTrigger trigger}) =>
      CaptureRecord(
        trigger: trigger,
        // Per-detection confidence isn't propagated through the tracker path,
        // so captures record candidate positions with conf 1.0 (a known
        // refinement — the training value is the corrected segment, #381).
        predictedDarts: [
          for (final c in frame.dartCandidates)
            PredictedDart(x: c.x, y: c.y, conf: 1.0)
        ],
        calPoints: frame.calPoints,
        modelVersion: _modelVersion,
        gameId: gameId,
        handle: handle,
        timestamp: DateTime.now(),
        frameSpace: capture.space,
        frameWidth: capture.width,
        frameHeight: capture.height,
      );
}

/// The bytes to persist for a capture plus the sidecar metadata describing
/// their coordinate space and pixel dims.
class _Capture {
  final Uint8List bytes;
  final FrameSpace space;
  final int width;
  final int height;
  const _Capture({
    required this.bytes,
    required this.space,
    required this.width,
    required this.height,
  });
}
