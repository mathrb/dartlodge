import 'package:dart_lodge/features/auto_scorer/presentation/widgets/aim_view_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('coverScale', () {
    test('matching aspects need no scaling', () {
      expect(coverScale(1.0, 1.0), closeTo(1.0, 1e-12));
      // A 16:9 preview on a 16:9 screen: screenAspect 1.778, preview 0.5625 →
      // product 1.0 → already covers.
      expect(coverScale(16 / 9, 9 / 16), closeTo(1.0, 1e-12));
    });

    test('portrait screen + landscape camera scales up (>1)', () {
      // Portrait 1080x2340 screen, 16:9 landscape preview.
      final scale = coverScale(1080 / 2340, 16 / 9);
      expect(scale, greaterThan(1.0));
    });

    test('formula is symmetric: product<1 inverts to product>1', () {
      const screen = 0.46; // portrait
      const preview = 1.0; // square-ish
      final s = coverScale(screen, preview); // product 0.46 → 1/0.46
      expect(s, closeTo(1 / (screen * preview), 1e-12));
      expect(s, greaterThan(1.0));
    });

    test('product>=1 is returned as-is', () {
      // 1.5 * 1.0 = 1.5 (>=1) → returned unchanged.
      expect(coverScale(1.5, 1.0), closeTo(1.5, 1e-12));
    });

    test('degenerate inputs fall back to 1.0', () {
      expect(coverScale(0, 1.78), 1.0);
      expect(coverScale(0.46, 0), 1.0);
      expect(coverScale(double.nan, 1.78), 1.0);
      expect(coverScale(double.infinity, 1.78), 1.0);
      expect(coverScale(-0.5, 1.78), 1.0);
    });
  });
}
