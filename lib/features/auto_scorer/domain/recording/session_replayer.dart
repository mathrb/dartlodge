import 'dart:convert';

import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_recorder.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';

/// One replayed frame: the recorded device outcome alongside what a fresh
/// tracker produced from the same inputs. [matches] is the fidelity check.
class ReplayedFrame {
  final int frameIndex;
  final RecordedOutcome recorded;
  final RecordedOutcome replayed;

  const ReplayedFrame({
    required this.frameIndex,
    required this.recorded,
    required this.replayed,
  });

  /// True when the replay reproduced the device outcome exactly. Compared via
  /// canonical JSON (the trace's own wire form), so emissions (incl. handle and
  /// the cap-blocked `emitted` flag) and status must all match.
  bool get matches =>
      jsonEncode(recorded.toJson()) == jsonEncode(replayed.toJson());

  @override
  String toString() => 'frame $frameIndex: '
      '${matches ? 'ok' : 'DIVERGED\n  recorded=${jsonEncode(recorded.toJson())}'
          '\n  replayed=${jsonEncode(replayed.toJson())}'}';
}

/// The result of replaying a whole trace.
class SessionReplayResult {
  final List<ReplayedFrame> frames;

  const SessionReplayResult(this.frames);

  /// True when every replayed frame matches its recording — the proof that the
  /// replay reconstructed the device session bit-for-bit.
  bool get isFaithful => frames.every((f) => f.matches);

  /// The frames where the replay diverged from the recording (empty when
  /// faithful) — the starting point for diagnosing a tracker bug.
  List<ReplayedFrame> get divergences =>
      [for (final f in frames) if (!f.matches) f];
}

/// Replays a recorded [SessionTrace] through a fresh [DartTracker], reproducing
/// the device session deterministically in a plain `flutter test` (epic #488,
/// sub-issue #491).
///
/// The tracker pipeline (`buildDetectionFrame → DartTracker.processFrame`) is
/// pure and has no time/random dependency, so feeding the same raw detections +
/// thresholds + out-of-band signals (turn advance / remove darts) into a fresh
/// tracker yields the same emissions, phases and handles — which is what
/// [SessionReplayResult.isFaithful] asserts.
class SessionReplayer {
  const SessionReplayer();

  SessionReplayResult replay(SessionTrace trace) {
    DartTracker? tracker;
    final replayed = <ReplayedFrame>[];

    for (final line in trace.lines) {
      switch (line) {
        case TrackerSegment(:final config):
          // A (re)created tracker instance — start fresh from its config.
          tracker = DartTracker(config: config);
        case TrackerSignal(:final kind):
          switch (kind) {
            case TrackerSignalKind.turnAdvanced:
              tracker?.onTurnAdvanced();
            case TrackerSignalKind.removeDarts:
              tracker?.removeDarts();
          }
        case TraceFrame(
            :final frameIndex,
            :final detections,
            :final calMinConfidence,
            :final dartMinConfidence,
            :final outcome,
          ):
          final t = tracker;
          // A well-formed trace always opens with a TrackerSegment; skip frames
          // that precede one rather than throwing.
          if (t == null) continue;
          final frame = buildDetectionFrame(
            detections,
            calMinConfidence: calMinConfidence,
            dartMinConfidence: dartMinConfidence,
          );
          final update = t.processFrame(frame);
          replayed.add(ReplayedFrame(
            frameIndex: frameIndex,
            recorded: outcome,
            replayed: outcomeFromUpdate(update),
          ));
      }
    }

    return SessionReplayResult(replayed);
  }
}
