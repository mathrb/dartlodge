import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/predicted_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/diagnostics/pipeline_timings.dart';
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
  /// filled in by the camera caller). Surfaced only by the diagnostics HUD.
  final PipelineTimings timings;

  const SessionFrameResult({
    required this.emittedDarts,
    required this.status,
    this.timings = const PipelineTimings(),
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
    required DartDetector detector,
    DartTracker? tracker,
    CaptureStore? captureStore,
    String modelVersion = 'unknown',
  })  : _detector = detector,
        _tracker = tracker ?? DartTracker(),
        _captureStore = captureStore,
        _modelVersion = modelVersion;

  final DartDetector _detector;
  final DartTracker _tracker;
  final CaptureStore? _captureStore;
  final String _modelVersion;

  /// Physical darts currently tracked on the board.
  int get dartsOnBoard => _tracker.confirmedDarts.length;

  /// Default storage cap for captured frames (#381 §6): keep the data set
  /// bounded; corrected/emitted frames are pruned last (see [RetentionPolicy]).
  static const int _retentionBytes = 250 * 1024 * 1024; // 250 MB

  /// Load the model and prune old captures to stay within the storage cap.
  /// Returns true on success (false on the web stub).
  Future<bool> start() async {
    final loaded = await _detector.load();
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
  }) async {
    final detectWatch = Stopwatch()..start();
    final frame = await _detector.detect(frameBytes);
    detectWatch.stop();
    final trackWatch = Stopwatch()..start();
    final update = _tracker.processFrame(frame);
    trackWatch.stop();

    if (collectData && _captureStore != null && update.newDarts.isNotEmpty) {
      // Store the raw frame the detector saw: detections are normalised to it,
      // so image + sidecar coords share one frame (the alignment invariant of
      // #390 — only now the shared frame is the raw one, since inference no
      // longer crops to 800×800). The training pipeline resizes; normalised
      // coords are resolution-independent.
      // The dart-in-turn ordinal of the first new dart this frame (1-based).
      final firstOrdinal = _tracker.dartsThisTurn - update.newDarts.length + 1;
      for (var i = 0; i < update.newDarts.length; i++) {
        await _captureStore.save(
          _recordFor(
            frame,
            gameId,
            CaptureHandle(
                turnOrdinal: turnOrdinal, dartInTurnOrdinal: firstOrdinal + i),
          ),
          frameBytes,
        );
      }
    }

    return SessionFrameResult(
      emittedDarts: [for (final d in update.newDarts) d.score],
      status: update.status,
      timings: PipelineTimings(
        detect: detectWatch.elapsed,
        track: trackWatch.elapsed,
      ),
    );
  }

  /// Force-capture the current frame for training data (#382) — for darts the
  /// model **missed** (no emission), the highest-value samples. Stores the raw
  /// frame + whatever the detector found this frame (often empty), under a
  /// manual handle. Out-of-band: does not touch the tracker or emit. No-op
  /// without a capture store. Returns true if a frame was stored.
  Future<bool> captureCurrentFrame(
    Uint8List frameBytes, {
    required int turnOrdinal,
    required String gameId,
  }) async {
    final store = _captureStore;
    if (store == null) return false;
    final frame = await _detector.detect(frameBytes);
    _manualSequence += 1;
    await store.save(
      _recordFor(frame, gameId,
          CaptureHandle.manual(turnOrdinal: turnOrdinal, sequence: _manualSequence)),
      frameBytes,
    );
    return true;
  }

  int _manualSequence = 0;

  /// Manual next-turn pressed: reset the per-turn cap counter.
  void onTurnAdvanced() => _tracker.onTurnAdvanced();

  /// Manual "remove darts": re-baseline the tracker; returns the resulting
  /// status (phase `rebaselined`) so the caller can refresh the chip.
  TrackerStatus removeDarts() => _tracker.removeDarts().status;

  Future<void> dispose() => _detector.dispose();

  CaptureRecord _recordFor(DetectionFrame frame, String gameId,
          CaptureHandle handle) =>
      CaptureRecord(
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
      );
}
