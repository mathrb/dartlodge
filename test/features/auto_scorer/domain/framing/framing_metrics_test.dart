import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/framing_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isCalArrangementUpright', () {
    test('a proper upright diamond (cal1 top, 2 bottom, 3 left, 4 right)', () {
      expect(
          isCalArrangementUpright(const <BoardPoint?>[
            (x: 0.5, y: 0.15), // cal1 top
            (x: 0.5, y: 0.85), // cal2 bottom
            (x: 0.15, y: 0.5), // cal3 left
            (x: 0.85, y: 0.5), // cal4 right
          ]),
          isTrue);
    });

    test('rejects the real degenerate capture (cal4 not rightmost)', () {
      // From the portrait t8-d2 sidecar: cal3≈cal4 both on the left → not a
      // valid board, must be rejected (the bug this guards against).
      expect(
          isCalArrangementUpright(const <BoardPoint?>[
            (x: 0.55, y: 0.14),
            (x: 0.56, y: 0.75),
            (x: 0.28, y: 0.48),
            (x: 0.30, y: 0.59),
          ]),
          isFalse);
    });

    test('rejects upside-down (cal1 below cal2)', () {
      expect(
          isCalArrangementUpright(const <BoardPoint?>[
            (x: 0.5, y: 0.85), // cal1 at bottom → not upright
            (x: 0.5, y: 0.15),
            (x: 0.15, y: 0.5),
            (x: 0.85, y: 0.5),
          ]),
          isFalse);
    });

    test('rejects a degenerate cluster below the min span', () {
      expect(
          isCalArrangementUpright(const <BoardPoint?>[
            (x: 0.50, y: 0.48),
            (x: 0.50, y: 0.52),
            (x: 0.48, y: 0.50),
            (x: 0.52, y: 0.50),
          ]),
          isFalse);
    });

    test('rejects an incomplete set', () {
      expect(
          isCalArrangementUpright(const <BoardPoint?>[
            (x: 0.5, y: 0.15),
            null,
            (x: 0.15, y: 0.5),
            (x: 0.85, y: 0.5),
          ]),
          isFalse);
    });
  });

  group('frameFillRatio', () {
    test('full-frame square cals → ratio ≈ 1.0', () {
      // Cal order is cal1..cal4 (top, bottom, left, right) — deliberately NOT in
      // hull order, to prove the angular sort handles it.
      final pts = <BoardPoint?>[
        (x: 0.5, y: 0.0), // top
        (x: 0.5, y: 1.0), // bottom
        (x: 0.0, y: 0.5), // left
        (x: 1.0, y: 0.5), // right
      ];
      // The diamond through frame-edge midpoints has area 0.5 of the unit frame.
      expect(frameFillRatio(pts), closeTo(0.5, 1e-9));
    });

    test('a board filling the frame scores higher than a small/far one', () {
      List<BoardPoint?> diamond(double r) => [
            (x: 0.5, y: 0.5 - r),
            (x: 0.5, y: 0.5 + r),
            (x: 0.5 - r, y: 0.5),
            (x: 0.5 + r, y: 0.5),
          ];
      final big = frameFillRatio(diamond(0.45));
      final small = frameFillRatio(diamond(0.15));
      expect(big, greaterThan(small));
      expect(small, lessThan(kGoodFillRatio));
      expect(big, greaterThan(kGoodFillRatio));
    });

    test('rotation-invariant: rotating the cals keeps the ratio', () {
      final axis = <BoardPoint?>[
        (x: 0.5, y: 0.2),
        (x: 0.5, y: 0.8),
        (x: 0.2, y: 0.5),
        (x: 0.8, y: 0.5),
      ];
      // Same square rotated ~45° (corners on the diagonals), same span.
      const d = 0.3 * 0.70710678; // 0.3 / sqrt(2) per axis
      final rotated = <BoardPoint?>[
        (x: 0.5 + d, y: 0.5 - d),
        (x: 0.5 - d, y: 0.5 + d),
        (x: 0.5 - d, y: 0.5 - d),
        (x: 0.5 + d, y: 0.5 + d),
      ];
      expect(frameFillRatio(axis), closeTo(frameFillRatio(rotated), 1e-9));
    });

    test('fewer than three cals → 0 (no area)', () {
      expect(frameFillRatio(const [null, null, null, null]), 0.0);
      expect(
          frameFillRatio(<BoardPoint?>[(x: 0.4, y: 0.4), null, null, null]), 0.0);
      expect(
          frameFillRatio(<BoardPoint?>[
            (x: 0.4, y: 0.4),
            (x: 0.6, y: 0.6),
            null,
            null,
          ]),
          0.0);
    });

    test('three present cals still yield a positive area', () {
      final pts = <BoardPoint?>[
        (x: 0.2, y: 0.2),
        (x: 0.8, y: 0.2),
        (x: 0.5, y: 0.8),
        null,
      ];
      expect(frameFillRatio(pts), greaterThan(0.0));
    });
  });
}
