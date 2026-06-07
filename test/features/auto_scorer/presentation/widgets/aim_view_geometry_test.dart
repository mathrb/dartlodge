import 'package:dart_lodge/features/auto_scorer/presentation/widgets/aim_view_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('coverScale', () {
    test('matching aspects need no scaling', () {
      expect(coverScale(1.0, 1.0), closeTo(1.0, 1e-12));
      // Genuine match: a 16:9 preview on a 16:9 screen already covers.
      expect(coverScale(16 / 9, 16 / 9), closeTo(1.0, 1e-12));
    });

    test('portrait screen + landscape camera scales up to cover the long axis',
        () {
      // Portrait 1080x2340 screen (sa≈0.4615), 16:9 landscape preview (pa≈1.778).
      // Cover scale = pa/sa, not the product (the old, buggy formula gave ~1.22
      // which left black bars).
      const sa = 1080 / 2340;
      const pa = 16 / 9;
      expect(coverScale(sa, pa), closeTo(pa / sa, 1e-9));
      expect(coverScale(sa, pa), greaterThan(3.0)); // genuinely fills, not ~1.2
    });

    test('portrait 9:16 screen + 16:9 camera → (16/9)/(9/16)', () {
      expect(coverScale(9 / 16, 16 / 9), closeTo((16 / 9) / (9 / 16), 1e-12));
    });

    test('landscape screen wider than the camera scales by sa/pa', () {
      // 19.5:9 landscape screen (sa≈2.167), 16:9 preview (pa≈1.778) → sa/pa.
      const sa = 19.5 / 9;
      const pa = 16 / 9;
      expect(coverScale(sa, pa), closeTo(sa / pa, 1e-9));
      expect(coverScale(sa, pa), greaterThan(1.0));
    });

    test('is symmetric in its two arguments', () {
      expect(coverScale(0.46, 1.78), closeTo(coverScale(1.78, 0.46), 1e-12));
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
