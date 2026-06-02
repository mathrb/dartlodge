import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/homography.dart';
import 'package:flutter_test/flutter_test.dart';

/// Port of the probe's `tests/test_dartboard.py` to the pure-Dart scorer
/// (#379), plus an end-to-end pipeline check that a perspective-tilted board is
/// rectified back to the correct segments.
///
/// Note the segment-convention difference (see `dartboard_scorer.dart`): the
/// probe emits `'S20'` / `'B'`, this port emits the DartLodge canonical `'20'`
/// / `'SB'`. The positions and classifications are otherwise identical.
void main() {
  /// Point at radius [r] and score-frame angle [deg] (where
  /// `ang = atan2(-y, x)`), relative to centre [cx],[cy].
  BoardPoint polar(double r, double deg, {double cx = 0, double cy = 0}) {
    final rad = deg * math.pi / 180.0;
    return (x: cx + r * math.cos(rad), y: cy - r * math.sin(rad));
  }

  group('ScoredDart.value (numeric mapping)', () {
    test('mirrors dartboard.numeric', () {
      expect(ScoredDart.triple(20).value, 60);
      expect(ScoredDart.double_(20).value, 40);
      expect(ScoredDart.single(20).value, 20);
      expect(ScoredDart.doubleBull().value, 50);
      expect(ScoredDart.singleBull().value, 25);
      expect(ScoredDart.miss().value, 0);
    });

    test('canonical strings use DartLodge convention', () {
      expect(ScoredDart.single(20).segment, '20'); // not 'S20'
      expect(ScoredDart.singleBull().segment, 'SB'); // not 'B'
      expect(ScoredDart.double_(20).segment, 'D20');
      expect(ScoredDart.triple(20).segment, 'T20');
      expect(ScoredDart.doubleBull().segment, 'DB');
      expect(ScoredDart.miss().segment, 'MISS');
    });
  });

  group('scoreDartAt — bull and miss', () {
    const rD = kRadiusDouble;
    test('dead centre is DB', () {
      expect(scoreDartAt(0, 0, rD).segment, 'DB');
    });
    test('outer-bull ring is SB', () {
      expect(scoreDartAt(0.011, 0, rD).segment, 'SB');
    });
    test('beyond the double is MISS', () {
      expect(scoreDartAt(rD * 1.5, 0, rD).segment, 'MISS');
    });
  });

  group('scoreDartAt — single/double/treble at segment 20', () {
    const rD = kRadiusDouble;
    test('single band', () {
      final p = polar(0.05, 81);
      expect(scoreDartAt(p.x, p.y, rD).segment, '20');
    });
    test('treble ring', () {
      final p = polar(0.105, 81);
      expect(scoreDartAt(p.x, p.y, rD).segment, 'T20');
    });
    test('double ring', () {
      final p = polar(0.165, 81);
      expect(scoreDartAt(p.x, p.y, rD).segment, 'D20');
    });
  });

  group('transformToCanonical', () {
    test('preserves a centred square (~identity)', () {
      const c = 0.5;
      const r = 0.2;
      final cals = <BoardPoint>[
        (x: c, y: c - r),
        (x: c, y: c + r),
        (x: c - r, y: c),
        (x: c + r, y: c),
      ];
      final all = [...cals, (x: c, y: c)];
      final warped = transformToCanonical(cals, all);
      expect(warped[4].x, closeTo(c, 1e-4));
      expect(warped[4].y, closeTo(c, 1e-4));
      expect(warped[0].x, closeTo(c, 1e-4));
      expect(warped[0].y, closeTo(c - r, 1e-4));
    });

    test('rectifies a skewed quad into a square', () {
      final cals = <BoardPoint>[
        (x: 0.5, y: 0.2),
        (x: 0.45, y: 0.8),
        (x: 0.2, y: 0.55),
        (x: 0.85, y: 0.5),
      ];
      final warped = transformToCanonical(cals, cals);
      final cx = warped.map((p) => p.x).reduce((a, b) => a + b) / 4;
      final cy = warped.map((p) => p.y).reduce((a, b) => a + b) / 4;
      final dists =
          warped.map((p) => math.sqrt(_sq(p.x - cx) + _sq(p.y - cy))).toList();
      final mean = dists.reduce((a, b) => a + b) / 4;
      final std = math.sqrt(
          dists.map((d) => _sq(d - mean)).reduce((a, b) => a + b) / 4);
      expect(std, closeTo(0.0, 1e-3)); // all four equidistant ⇒ a square
    });
  });

  group('Homography', () {
    test('round-trips its own correspondences', () {
      final src = <BoardPoint>[
        (x: 0.1, y: 0.1),
        (x: 0.9, y: 0.15),
        (x: 0.05, y: 0.95),
        (x: 0.92, y: 0.88),
      ];
      final dst = <BoardPoint>[
        (x: 0.0, y: 0.0),
        (x: 1.0, y: 0.0),
        (x: 0.0, y: 1.0),
        (x: 1.0, y: 1.0),
      ];
      final h = Homography.fromCorrespondences(src, dst);
      for (var i = 0; i < 4; i++) {
        final mapped = h.apply(src[i]);
        expect(mapped.x, closeTo(dst[i].x, 1e-9));
        expect(mapped.y, closeTo(dst[i].y, 1e-9));
      }
    });

    test('throws on degenerate (collinear) calibration points', () {
      final collinear = <BoardPoint>[
        (x: 0.1, y: 0.1),
        (x: 0.2, y: 0.2),
        (x: 0.3, y: 0.3),
        (x: 0.4, y: 0.4),
      ];
      final dst = <BoardPoint>[
        (x: 0.0, y: 0.0),
        (x: 1.0, y: 0.0),
        (x: 0.0, y: 1.0),
        (x: 1.0, y: 1.0),
      ];
      expect(() => Homography.fromCorrespondences(collinear, dst),
          throwsArgumentError);
    });
  });

  group('DartboardScorer — 11 synthetic darts through a tilted board', () {
    const scorer = DartboardScorer();

    // Canonical board: centre (0.5,0.5), double radius 0.30.
    const cx = 0.5, cy = 0.5, rD = 0.30;

    // Canonical cal points in [top, bottom, left, right] order (cal1=12 o'clock
    // / 5–20 wire). These ARE a centred square, so warping recovers identity.
    final canonicalCals = <BoardPoint>[
      (x: cx, y: cy - rD),
      (x: cx, y: cy + rD),
      (x: cx - rD, y: cy),
      (x: cx + rD, y: cy),
    ];

    /// Canonical point for sector [number] at radius [r] (placed at the centre
    /// of that sector's 18° angle bin to stay clear of wire boundaries).
    BoardPoint sector(int number, double r) {
      final bin = kBoardSectors.entries.firstWhere((e) => e.value == number).key;
      final deg = bin * 18 + 9;
      return polar(r, deg.toDouble(), cx: cx, cy: cy);
    }

    // Ring radii in canonical units (double-radius = 0.30).
    const rSingle = 0.10; // inner single band, clear of bull and treble
    const rTreble = 0.180; // within the treble ring
    const rDoubleRing = 0.291; // within the double ring
    const rOuterBull = 0.020; // outer-bull band

    final cases = <({BoardPoint p, String expected})>[
      (p: sector(20, rDoubleRing), expected: 'D20'),
      (p: sector(20, rTreble), expected: 'T20'),
      (p: sector(20, rSingle), expected: '20'),
      (p: sector(11, rTreble), expected: 'T11'),
      (p: sector(6, rTreble), expected: 'T6'),
      (p: sector(3, rSingle), expected: '3'),
      (p: sector(1, rDoubleRing), expected: 'D1'),
      (p: sector(13, rSingle), expected: '13'),
      (p: (x: cx, y: cy), expected: 'DB'),
      (p: polar(rOuterBull, 81, cx: cx, cy: cy), expected: 'SB'),
      (p: polar(0.35, 81, cx: cx, cy: cy), expected: 'MISS'),
    ];

    test('scores correctly in canonical space (identity warp)', () {
      final result = scorer.scoreDarts(
        calPoints: canonicalCals,
        darts: cases.map((c) => c.p).toList(),
      );
      expect(result.map((d) => d.segment).toList(),
          cases.map((c) => c.expected).toList());
    });

    test('recovers the same segments through a perspective tilt', () {
      // Map the centred-square cals onto a skewed quad to simulate an
      // off-axis phone photo, then apply that same transform to every dart.
      final skewedImageCals = <BoardPoint>[
        (x: 0.52, y: 0.18),
        (x: 0.48, y: 0.86),
        (x: 0.15, y: 0.46),
        (x: 0.83, y: 0.55),
      ];
      final toImage =
          Homography.fromCorrespondences(canonicalCals, skewedImageCals);

      final imageDarts = cases.map((c) => toImage.apply(c.p)).toList();
      final result =
          scorer.scoreDarts(calPoints: skewedImageCals, darts: imageDarts);

      // A homography fixing 4 general-position points is the identity, so the
      // rectification must recover every original segment despite the tilt.
      expect(result.map((d) => d.segment).toList(),
          cases.map((c) => c.expected).toList());
    });

    test('preserves (baseNumber, multiplier) for event emission', () {
      final result = scorer.scoreDarts(
        calPoints: canonicalCals,
        darts: [sector(20, rTreble), (x: cx, y: cy)],
      );
      expect(result[0].baseNumber, 20);
      expect(result[0].multiplier, 3); // T20
      expect(result[1].baseNumber, 25);
      expect(result[1].multiplier, 2); // DB
    });

    test('empty dart list yields empty result', () {
      expect(scorer.scoreDarts(calPoints: canonicalCals, darts: const []),
          isEmpty);
    });

    test('rejects a wrong cal-point count', () {
      expect(
        () => scorer.scoreDarts(
            calPoints: canonicalCals.take(3).toList(),
            darts: [(x: cx, y: cy)]),
        throwsArgumentError,
      );
    });
  });
}

double _sq(double v) => v * v;
