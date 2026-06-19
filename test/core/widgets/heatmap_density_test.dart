import 'package:dart_lodge/core/widgets/heatmap_density.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeHeatGrid — binning', () {
    test('empty input yields an all-zero, isEmpty grid', () {
      final grid = computeHeatGrid(const []);
      expect(grid.resolution, kHeatGridResolution);
      expect(grid.isEmpty, isTrue);
      expect(grid.values.every((v) => v == 0), isTrue);
    });

    test('a single centre point peaks at the centre cell', () {
      // No blur so the peak is exactly the binned cell.
      final grid = computeHeatGrid(
        const [(x: 0.0, y: 0.0)],
        resolution: 64,
        kernelRadiusCells: 0,
      );
      expect(grid.isEmpty, isFalse);
      // (0,0) maps to col=row=32 for a 64-grid over [-1.1,1.1].
      final mid = grid.resolution ~/ 2;
      expect(grid.at(mid, mid), 1.0);
    });

    test('"20 at top" maps to upper-half (row < mid)', () {
      // A point near the top of the board has negative y in canvas-like coords.
      final grid = computeHeatGrid(
        const [(x: 0.0, y: -0.8)],
        kernelRadiusCells: 0,
      );
      final mid = grid.resolution ~/ 2;
      // Find the hot cell.
      var hotRow = -1, hotCol = -1;
      for (var r = 0; r < grid.resolution; r++) {
        for (var c = 0; c < grid.resolution; c++) {
          if (grid.at(c, r) > 0) {
            hotRow = r;
            hotCol = c;
          }
        }
      }
      expect(hotRow, lessThan(mid)); // top half
      expect(hotCol, mid); // centred horizontally
    });

    test('points beyond the noise radius are dropped', () {
      final grid = computeHeatGrid(
        const [(x: 5.0, y: 0.0)], // r=5 >> kHeatNoiseRadius
        kernelRadiusCells: 0,
      );
      expect(grid.isEmpty, isTrue);
    });

    test('off-board miss inside grid extent still bins', () {
      // r ≈ 1.05, within extent 1.1 and below noise radius 1.5.
      final grid = computeHeatGrid(
        const [(x: 1.05, y: 0.0)],
        kernelRadiusCells: 0,
      );
      expect(grid.isEmpty, isFalse);
    });
  });

  group('computeHeatGrid — gaussian smoothing', () {
    test('blur spreads a single point to its neighbours', () {
      final grid = computeHeatGrid(
        const [(x: 0.0, y: 0.0)],
        resolution: 64,
        kernelRadiusCells: 3,
      );
      final mid = grid.resolution ~/ 2;
      // Peak remains at centre (normalised to 1.0)...
      expect(grid.at(mid, mid), closeTo(1.0, 1e-9));
      // ...and neighbours are now non-zero.
      expect(grid.at(mid + 1, mid), greaterThan(0));
      expect(grid.at(mid, mid + 1), greaterThan(0));
      // Density falls off away from the peak.
      expect(grid.at(mid + 1, mid), lessThan(grid.at(mid, mid)));
    });

    test('density is symmetric about a centred point', () {
      final grid = computeHeatGrid(
        const [(x: 0.0, y: 0.0)],
        resolution: 64,
        kernelRadiusCells: 4,
      );
      final mid = grid.resolution ~/ 2;
      expect(grid.at(mid + 2, mid), closeTo(grid.at(mid - 2, mid), 1e-9));
      expect(grid.at(mid, mid + 2), closeTo(grid.at(mid, mid - 2), 1e-9));
    });
  });

  group('computeHeatGrid — normalisation', () {
    test('max cell is exactly 1.0 and all cells within 0..1', () {
      final grid = computeHeatGrid(
        const [
          (x: 0.0, y: 0.0),
          (x: 0.0, y: 0.0),
          (x: 0.0, y: 0.0),
          (x: 0.5, y: 0.5),
        ],
      );
      var max = 0.0;
      for (final v in grid.values) {
        expect(v, inInclusiveRange(0.0, 1.0));
        if (v > max) max = v;
      }
      expect(max, closeTo(1.0, 1e-9));
    });
  });

  group('heatColor — colormap stops', () {
    test('t=0 is blue and fully transparent', () {
      final c = heatColor(0.0);
      expect((c.r, c.g, c.b), (0, 0, 255));
      expect(c.a, 0);
    });

    test('t=1 is red and near-opaque', () {
      final c = heatColor(1.0);
      expect((c.r, c.g, c.b), (255, 0, 0));
      expect(c.a, greaterThan(200));
    });

    test('mid ramp passes through cyan-ish then yellow-ish', () {
      final cyan = heatColor(0.40);
      expect((cyan.r, cyan.g, cyan.b), (0, 255, 255));
      final yellow = heatColor(0.65);
      expect((yellow.r, yellow.g, yellow.b), (255, 255, 0));
    });

    test('alpha is monotonically non-decreasing with density', () {
      var prev = -1;
      for (var i = 0; i <= 10; i++) {
        final a = heatColor(i / 10).a;
        expect(a, greaterThanOrEqualTo(prev));
        prev = a;
      }
    });

    test('out-of-range t is clamped', () {
      expect(heatColor(-1.0).a, heatColor(0.0).a);
      final hi = heatColor(2.0);
      expect((hi.r, hi.g, hi.b), (255, 0, 0));
    });
  });

  group('heatGridToRgba', () {
    test('produces a tightly packed resolution²×4 RGBA buffer', () {
      final grid = computeHeatGrid(const [(x: 0.0, y: 0.0)], resolution: 16);
      final rgba = heatGridToRgba(grid);
      expect(rgba.length, 16 * 16 * 4);
    });

    test('empty grid produces a fully transparent buffer', () {
      final grid = computeHeatGrid(const [], resolution: 8);
      final rgba = heatGridToRgba(grid);
      // Every 4th byte (alpha) is 0.
      for (var i = 3; i < rgba.length; i += 4) {
        expect(rgba[i], 0);
      }
    });
  });
}
