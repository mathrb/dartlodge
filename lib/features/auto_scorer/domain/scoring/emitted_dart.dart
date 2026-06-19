import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';

/// A dart the session emits to the active game: the classified [score] plus the
/// dart's normalised canonical impact position (#572).
///
/// [x]/[y] are in the stable heatmap frame (origin = board centre, radius `1.0`
/// at the double ring, "20 at top"). They are `null` when no usable position is
/// available — detection noise past [kDartNoiseRadius] (the segment is still
/// emitted). The position is carried as plain doubles so the cross-feature
/// `DartInputSink` seam (SI-2, #573) never has to depend on the auto_scorer's
/// `BoardPoint` type.
class EmittedDart {
  final ScoredDart score;
  final double? x;
  final double? y;

  const EmittedDart({required this.score, this.x, this.y});

  /// Convenience accessor mirroring the previous `ScoredDart`-only shape.
  String get segment => score.segment;

  @override
  String toString() =>
      'EmittedDart(${score.segment}${x == null ? '' : ' @($x,$y)'})';
}
