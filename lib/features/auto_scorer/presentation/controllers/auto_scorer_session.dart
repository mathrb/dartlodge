import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/predicted_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';

/// Result of feeding one camera frame through the session.
class SessionFrameResult {
  /// Darts newly confirmed+emitted this frame, to submit to the active game.
  final List<ScoredDart> emittedDarts;
  final TrackerStatus status;

  const SessionFrameResult({required this.emittedDarts, required this.status});
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

  TrackerStatus get status => TrackerStatus(
        phase: _tracker.confirmedDarts.isEmpty
            ? TrackerPhase.idle
            : TrackerPhase.tracking,
        dartsOnBoard: _tracker.confirmedDarts.length,
        dartsThisTurn: _tracker.dartsThisTurn,
      );

  /// Load the model. Returns true on success (false on the web stub).
  Future<bool> start() => _detector.load();

  /// Feed one raw camera frame. [turnOrdinal] is the current 1-based turn; when
  /// [collectData] is set and a capture store is present, each emitted dart's
  /// frame + sidecar is stored keyed by `(turn, dart-in-turn)`.
  Future<SessionFrameResult> onFrame(
    Uint8List frameBytes, {
    required int turnOrdinal,
    required String gameId,
    bool collectData = false,
  }) async {
    final frame = await _detector.detect(frameBytes);
    final update = _tracker.processFrame(frame);

    if (collectData && _captureStore != null && update.newDarts.isNotEmpty) {
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
    );
  }

  /// Manual next-turn pressed: reset the per-turn cap counter.
  void onTurnAdvanced() => _tracker.onTurnAdvanced();

  /// Manual "remove darts": re-baseline the tracker.
  void removeDarts() => _tracker.removeDarts();

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
