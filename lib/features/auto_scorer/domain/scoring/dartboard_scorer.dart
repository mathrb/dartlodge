import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/homography.dart';

/// Dartboard geometry + BDO-standard segment scoring, ported to pure Dart from
/// the probe's `src/dartprobe/dartboard.py` (#379). Given four calibration
/// points and dart-tip positions, warps to a face-on frame and classifies each
/// dart into a [ScoredDart].
///
/// **Segment-string convention.** The probe emits `'S20'` for singles and
/// `'B'` for the outer bull; DartLodge's canonical form (CLAUDE.md "Segment
/// Format Convention") uses the bare number `'20'` and `'SB'`. This port emits
/// the **DartLodge** form directly so its output drops straight into the
/// `DartThrown` payload via the `(baseNumber, multiplier)` pair — no second
/// translation step, and `Segment.parse` accepts it.
///
/// Pure domain logic: only `dart:math`, no Flutter / drift / dio / platform CV.

// Board geometry — only the ratios matter (units cancel after warping).
const double kRadiusDouble = 0.170;
const double kRadiusTreble = 0.1074;
const double kRadiusOuterBull = 0.0159;
const double kRadiusInnerBull = 0.00635;

/// Width of the double / treble ring (probe `W_DT`).
const double kRingWidth = 0.01;

/// Sector number at each 18° angle bin (measured CCW from +x). After canonical
/// rectification, segment 20 lands in bin 4 (72–90°). Mirrors `BOARD_DICT`.
const Map<int, int> kBoardSectors = {
  0: 13, 1: 4, 2: 18, 3: 1, 4: 20, 5: 5, 6: 12, 7: 9, 8: 14, 9: 11, //
  10: 8, 11: 16, 12: 7, 13: 19, 14: 3, 15: 17, 16: 2, 17: 15, 18: 10, 19: 6,
};

/// A classified dart: the DartLodge canonical [segment] string plus the numeric
/// `(baseNumber, multiplier)` pair used by `DartThrown` event payloads.
class ScoredDart {
  /// Canonical string: `'20'`, `'D20'`, `'T20'`, `'SB'`, `'DB'`, `'MISS'`.
  final String segment;

  /// Board value: 1–20 for numbered sectors, 25 for bull, 0 for a miss.
  final int baseNumber;

  /// 1 = single, 2 = double, 3 = triple. (Bull: 1 = `SB`, 2 = `DB`.)
  final int multiplier;

  const ScoredDart._(this.segment, this.baseNumber, this.multiplier);

  factory ScoredDart.miss() => const ScoredDart._('MISS', 0, 1);
  factory ScoredDart.doubleBull() => const ScoredDart._('DB', 25, 2);
  factory ScoredDart.singleBull() => const ScoredDart._('SB', 25, 1);
  factory ScoredDart.single(int number) => ScoredDart._('$number', number, 1);
  factory ScoredDart.double_(int number) =>
      ScoredDart._('D$number', number, 2);
  factory ScoredDart.triple(int number) => ScoredDart._('T$number', number, 3);

  /// Points scored: T20→60, D20→40, single 20→20, DB→50, SB→25, MISS→0.
  int get value {
    if (baseNumber == 25) return multiplier == 2 ? 50 : 25;
    return baseNumber * multiplier;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ScoredDart && other.segment == segment);

  @override
  int get hashCode => segment.hashCode;

  @override
  String toString() => segment;
}

/// Classify a single dart given its position relative to the board centre, in
/// the warped frame. [rDouble] is the double-ring radius in the same units.
/// Mirrors `dartboard.score_dart` exactly.
ScoredDart scoreDartAt(double x, double y, double rDouble) {
  final rTreble = rDouble * (kRadiusTreble / kRadiusDouble);
  final rOuterBull = rDouble * (kRadiusOuterBull / kRadiusDouble);
  final rInnerBull = rDouble * (kRadiusInnerBull / kRadiusDouble);
  final ringWidth = kRingWidth * (rDouble / kRadiusDouble);

  final dist = math.sqrt(x * x + y * y);
  if (dist > rDouble) return ScoredDart.miss();
  if (dist <= rInnerBull) return ScoredDart.doubleBull();
  if (dist <= rOuterBull) return ScoredDart.singleBull();

  var angle = _degrees(math.atan2(-y, x));
  if (angle < 0) angle += 360;
  final bin = (angle ~/ 18) % 20;
  final number = kBoardSectors[bin]!;

  if (dist > rDouble - ringWidth && dist <= rDouble) {
    return ScoredDart.double_(number);
  }
  if (dist > rTreble - ringWidth && dist <= rTreble) {
    return ScoredDart.triple(number);
  }
  return ScoredDart.single(number);
}

double _degrees(double radians) => radians * 180.0 / math.pi;

/// High-level scorer: warp cal points + dart tips to canonical space and
/// classify each dart. Mirrors the probe's `score_photo` pipeline.
class DartboardScorer {
  const DartboardScorer();

  /// Score every dart in [darts] given the four [calPoints] (cal1..cal4 order).
  ///
  /// Returns one [ScoredDart] per input dart, in the same order. Returns an
  /// empty list when [darts] is empty. Throws [ArgumentError] when [calPoints]
  /// is not exactly four points or they are degenerate.
  List<ScoredDart> scoreDarts({
    required List<BoardPoint> calPoints,
    required List<BoardPoint> darts,
  }) {
    if (calPoints.length != 4) {
      throw ArgumentError('Exactly 4 calibration points required (cal1..cal4).');
    }
    if (darts.isEmpty) return const [];

    final warped = transformToCanonical(calPoints, [...calPoints, ...darts]);
    final cals = warped.sublist(0, 4);
    final cx = cals.map((p) => p.x).reduce((a, b) => a + b) / 4;
    final cy = cals.map((p) => p.y).reduce((a, b) => a + b) / 4;
    final rDouble = cals
            .map((p) => math.sqrt(_sq(p.x - cx) + _sq(p.y - cy)))
            .reduce((a, b) => a + b) /
        4;

    return [
      for (var i = 4; i < warped.length; i++)
        scoreDartAt(warped[i].x - cx, warped[i].y - cy, rDouble),
    ];
  }
}

double _sq(double v) => v * v;
