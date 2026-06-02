import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';

/// A physical dart the tracker has confirmed on the board.
///
/// [boardPosition] is in **canonical** (rectified) coordinates, so it stays
/// comparable frame-to-frame while the homography is held stable — this is the
/// key on which the tracker matches a jittering detection back to the same
/// physical dart instead of manufacturing a phantom.
///
/// [handle] is a stable, monotonic, per-tracker id. Captures and corrections
/// key on this handle, **not** on the `DartThrown.eventId`, which churns when
/// per-dart correction rewinds-and-replays the tail (#376 §3.1, #381). Binding
/// a handle to its emitted event id is the emission/capture layer's job
/// (#381/#382), deliberately kept out of this pure tracker.
class TrackedDart {
  final int handle;
  final BoardPoint boardPosition;
  final ScoredDart score;

  /// `false` when the dart was confirmed but **not** emitted because the turn
  /// already held [DartTrackerConfig.maxDartsPerTurn] (the 3-dart cap). It is
  /// still tracked physically so it does not re-trigger detection.
  final bool emitted;

  const TrackedDart({
    required this.handle,
    required this.boardPosition,
    required this.score,
    required this.emitted,
  });

  @override
  String toString() =>
      'TrackedDart(#$handle ${score.segment}${emitted ? '' : ' [unemitted]'})';
}
