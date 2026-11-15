// The heatmap plots positions in the auto-scorer's canonical frame over the
// shared core board face. A dart the scorer classifies into a ring must render
// over that same ring of the painted face, so the face proportions and the
// canonical-to-pixel mapping have to agree with `dartboard_scorer.dart`.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dart_lodge/core/widgets/dartboard_face_painter.dart';
import 'package:dart_lodge/core/widgets/heatmap_dartboard_widget.dart';
import 'package:dart_lodge/core/widgets/heatmap_density.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const double _size = 400;

/// Canonical point on segment 20's centre line at radius [r] (scorer frame:
/// `atan2(-y, x)`, bin 4 = 72-90 degrees = segment 20).
HeatPoint _on20(double r) {
  const a = 81 * math.pi / 180;
  return (x: r * math.cos(a), y: -r * math.sin(a));
}

Future<Uint8List> _render(WidgetTester tester, List<HeatPoint> pts) async {
  final key = GlobalKey();
  await tester.pumpWidget(MaterialApp(
    home: Center(
      child: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: _size,
          height: _size,
          child: HeatmapDartboardWidget(points: pts, kernelRadiusCells: 1),
        ),
      ),
    ),
  ));
  // decodeImageFromPixels completes on the engine side, outside fake async.
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
  late Uint8List bytes;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 1);
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    bytes = bd!.buffer.asUint8List();
  });
  return bytes;
}

/// Radius, as a fraction of the widget radius, of the pixel where [a] differs
/// most from [b], searched in the upper half (where segment 20 is displayed).
double _hotRadiusFraction(Uint8List a, Uint8List b) {
  var best = -1;
  var bestIdx = 0;
  final n = _size.toInt();
  for (var row = 0; row < n ~/ 2; row++) {
    for (var col = 0; col < n; col++) {
      final i = (row * n + col) * 4;
      final d = (a[i] - b[i]).abs() +
          (a[i + 1] - b[i + 1]).abs() +
          (a[i + 2] - b[i + 2]).abs();
      if (d > best) {
        best = d;
        bestIdx = row * n + col;
      }
    }
  }
  final row = bestIdx ~/ n;
  final col = bestIdx % n;
  final dx = col + 0.5 - n / 2;
  final dy = row + 0.5 - n / 2;
  return math.sqrt(dx * dx + dy * dy) / (n / 2);
}

void main() {
  group('face ring radii match the scorer geometry', () {
    // The scorer classifies with radii normalised to the double ring (1.0);
    // the face draws the double ring at kBoardRDoubleOuter of its radius.
    double scaled(double scorerRadius) =>
        kBoardRDoubleOuter * scorerRadius / kRadiusDouble;

    test('treble ring', () {
      expect(kBoardRTripleOuter, closeTo(scaled(kRadiusTreble), 1e-9));
      expect(kBoardRTripleInner,
          closeTo(scaled(kRadiusTreble - kRingWidth), 1e-9));
    });

    test('double ring', () {
      expect(kBoardRDoubleInner,
          closeTo(scaled(kRadiusDouble - kRingWidth), 1e-9));
    });

    test('bull', () {
      expect(kBoardRSingleBull, closeTo(scaled(kRadiusOuterBull), 1e-9));
      expect(kBoardRDoubleBull, closeTo(scaled(kRadiusInnerBull), 1e-9));
    });
  });

  group('a scored dart renders over its painted ring', () {
    // Reference render: the same number of points on the opposite side.
    List<HeatPoint> far(int k) =>
        List.filled(k, (x: -_on20(0.6).x, y: -_on20(0.6).y));

    Future<double> hotSpot(WidgetTester tester, HeatPoint p) async {
      final a = await _render(tester, List.filled(40, p));
      final b = await _render(tester, far(40));
      return _hotRadiusFraction(a, b);
    }

    testWidgets('T20 lands on the treble ring', (tester) async {
      final p = _on20(0.6024); // middle of the scorer's treble band
      expect(scoreDartAt(p.x, p.y, 1.0).segment, 'T20');
      expect(await hotSpot(tester, p),
          inInclusiveRange(kBoardRTripleInner, kBoardRTripleOuter));
    });

    testWidgets('D20 lands on the double ring', (tester) async {
      final p = _on20(0.97);
      expect(scoreDartAt(p.x, p.y, 1.0).segment, 'D20');
      expect(await hotSpot(tester, p),
          inInclusiveRange(kBoardRDoubleInner, kBoardRDoubleOuter));
    });

    testWidgets('inner single 20 lands between the bull and the treble',
        (tester) async {
      final p = _on20(0.50);
      expect(scoreDartAt(p.x, p.y, 1.0).segment, '20');
      expect(await hotSpot(tester, p),
          inInclusiveRange(kBoardRSingleBull, kBoardRTripleInner));
    });

    testWidgets('outer single 20 lands between the treble and the double',
        (tester) async {
      final p = _on20(0.80);
      expect(scoreDartAt(p.x, p.y, 1.0).segment, '20');
      expect(await hotSpot(tester, p),
          inInclusiveRange(kBoardRTripleOuter, kBoardRDoubleInner));
    });
  });

  group('the density overlay leaves dart-free areas untouched', () {
    // Pixel at [fraction] of the widget radius, [deg] degrees clockwise from
    // the top of the displayed board (20 at top, so 90 = 6, 180 = 3, 270 = 11).
    String pixelAt(Uint8List bytes, double fraction, double deg) {
      final a = deg * math.pi / 180;
      const c = _size / 2;
      final col = (c + fraction * c * math.sin(a)).floor();
      final row = (c - fraction * c * math.cos(a)).floor();
      final i = (row * _size.toInt() + col) * 4;
      return [bytes[i], bytes[i + 1], bytes[i + 2]]
          .map((v) => v.toRadixString(16).padLeft(2, '0'))
          .join();
    }

    testWidgets('outer singles far from a T20 cluster keep the face colour',
        (tester) async {
      final bytes = await _render(tester, List.filled(40, _on20(0.6024)));
      // Middle of the outer single band, in wedge centres away from the 20.
      final r = (kBoardRTripleOuter + kBoardRDoubleInner) / 2;
      const faceColours = {'212121', 'e0d5c1'}; // segment black / cream
      for (final deg in [90.0, 180.0, 270.0]) {
        expect(faceColours, contains(pixelAt(bytes, r, deg)),
            reason: 'pixel at $deg degrees');
      }
    });
  });
}
