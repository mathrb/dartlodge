import 'dart:ui';

import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_cal_overlay_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapDetectionToRect', () {
    const rect = Size(200, 400);

    test('skip mode maps raw-frame-normalised coords linearly', () {
      final o = mapDetectionToRect((x: 0.5, y: 0.25),
          rect: rect, skipPreprocess: true);
      expect(o, isNotNull);
      expect(o!.dx, closeTo(100, 1e-9));
      expect(o.dy, closeTo(100, 1e-9));
    });

    test('skip mode ignores rawFrameSize (direct map)', () {
      final o = mapDetectionToRect((x: 1.0, y: 1.0),
          rect: rect, skipPreprocess: true, rawFrameSize: const Size(1280, 720));
      expect(o, const Offset(200, 400));
    });

    test('non-skip inverts the letterbox to recover the raw centre', () {
      // 1200x800 landscape → fills width, padded top/bottom. The letterbox
      // centre (0.5,0.5) is also the raw centre → maps to the rect centre.
      final o = mapDetectionToRect((x: 0.5, y: 0.5),
          rect: rect, skipPreprocess: false, rawFrameSize: const Size(1200, 800));
      expect(o, isNotNull);
      expect(o!.dx, closeTo(100, 1e-9));
      expect(o.dy, closeTo(200, 1e-9));
    });

    test('non-skip recovers a real edge point from inside the padded square', () {
      // 1200x800 → sH = 800/1200 = 0.6667. A letterbox-y of 0.5 - 0.6667/2 =
      // 0.16665 is the top edge of the real frame → raw y ≈ 0 → rect y ≈ 0.
      const rawSize = Size(1200, 800);
      final sH = 800 / 1200;
      final topV = 0.5 - sH / 2;
      final o = mapDetectionToRect((x: 0.5, y: topV),
          rect: rect, skipPreprocess: false, rawFrameSize: rawSize);
      expect(o, isNotNull);
      expect(o!.dy, closeTo(0, 1e-6));
    });

    test('non-skip returns null for a point in the grey pad', () {
      // y just above the top of the real frame → inside the pad → skipped.
      const rawSize = Size(1200, 800);
      final sH = 800 / 1200;
      final padV = (0.5 - sH / 2) - 0.05; // above the real-frame top edge
      final o = mapDetectionToRect((x: 0.5, y: padV),
          rect: rect, skipPreprocess: false, rawFrameSize: rawSize);
      expect(o, isNull);
    });

    test('non-skip with a portrait frame pads left/right', () {
      // 800x1200 portrait → sW = 800/1200, x padded. Letterbox centre maps back
      // to the raw centre (rect centre).
      final o = mapDetectionToRect((x: 0.5, y: 0.5),
          rect: rect, skipPreprocess: false, rawFrameSize: const Size(800, 1200));
      expect(o, isNotNull);
      expect(o!.dx, closeTo(100, 1e-9));
      expect(o.dy, closeTo(200, 1e-9));
    });
  });
}
