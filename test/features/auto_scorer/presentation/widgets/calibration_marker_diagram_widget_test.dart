import 'dart:math' as math;

import 'package:dart_lodge/core/widgets/dartboard_face_painter.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/calibration_marker_diagram_widget.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double size = 240}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: size, height: size, child: child),
        ),
      ),
    );

void main() {
  group('calibrationMarkerAngle', () {
    // In the stored canonical frame the four cal points are exactly cardinal:
    // this is the `cal1 → top, cal2 → bottom, cal3 → left, cal4 → right`
    // mapping canonicalTransform() is built on (domain/scoring/homography.dart).
    test('cal1 (20|5) is at the top', () {
      expect(calibrationMarkerAngle(0), closeTo(-math.pi / 2, 1e-9));
    });

    test('cal2 (3|17) is at the bottom', () {
      expect(calibrationMarkerAngle(1), closeTo(math.pi / 2, 1e-9));
    });

    test('cal3 (8|11) is at the left', () {
      expect(calibrationMarkerAngle(2), closeTo(math.pi, 1e-9));
    });

    test('cal4 (13|6) is at the right', () {
      expect(calibrationMarkerAngle(3), closeTo(0, 1e-9));
    });

    test('the four markers are a quarter-turn apart', () {
      for (var i = 0; i < 4; i++) {
        final next = calibrationMarkerAngle((i + 1) % 4);
        final delta = (next - calibrationMarkerAngle(i)) % (2 * math.pi);
        // cal order walks top → bottom → left → right, i.e. half a turn, then
        // a quarter, then a half: every hop is a multiple of π/2.
        expect((delta / (math.pi / 2)) % 1, closeTo(0, 1e-9));
      }
    });
  });

  test('the wire pairs are four distinct adjacent segment pairs', () {
    expect(kCalibrationMarkerWires.length, 4);
    final used = <int>{};
    for (final (a, b) in kCalibrationMarkerWires) {
      final ia = kBoardFaceClockOrder.indexOf(a);
      final ib = kBoardFaceClockOrder.indexOf(b);
      expect(ia, isNot(-1));
      expect(ib, isNot(-1));
      // Adjacent either way round the clock.
      expect((ia + 1) % 20 == ib || (ib + 1) % 20 == ia, isTrue,
          reason: '$a and $b are not neighbours');
      used
        ..add(a)
        ..add(b);
    }
    expect(used.length, 8); // no segment reused across the four wires
  });

  testWidgets('renders a square diagram with an accessible description',
      (tester) async {
    await tester.pumpWidget(
      _host(const CalibrationMarkerDiagram(semanticsLabel: 'four markers')),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.getSize(find.byType(AspectRatio)), const Size(240, 240));
    expect(
      find.bySemanticsLabel('four markers'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('paints without overflowing at a tiny size', (tester) async {
    // The labels are clamped into the canvas, so even a cramped diagram paints.
    await tester.pumpWidget(
      _host(const CalibrationMarkerDiagram(semanticsLabel: 'markers'),
          size: 60),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the setup-tips diagram stays the static one (#759)',
      (tester) async {
    // The aim view now shares this widget through a `.live` constructor. The
    // tips screen was validated as it is, so it must keep the labelled,
    // stateless drawing: `markers == null` is what selects it.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 260,
          child: CalibrationMarkerDiagram(semanticsLabel: 'diagram'),
        ),
      ),
    ));

    final diagram = tester
        .widget<CalibrationMarkerDiagram>(find.byType(CalibrationMarkerDiagram));
    expect(diagram.markers, isNull);
    expect(diagram.foreground, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the live diagram paints at banner size without complaint',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 44,
          height: 44,
          child: CalibrationMarkerDiagram.live(
            semanticsLabel: 'live diagram',
            markers: [
              MarkerRecognition.found,
              MarkerRecognition.weak,
              MarkerRecognition.missing,
              MarkerRecognition.found,
            ],
            foreground: Colors.white,
          ),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('live diagram'), findsOneWidget);
  });
}
