import 'dart:math' as math;

import 'package:dart_lodge/core/widgets/heatmap_dartboard_widget.dart';
import 'package:dart_lodge/core/widgets/heatmap_density.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 200, height: 200, child: child)),
      ),
    );

void main() {
  group('heatmap orientation (#697)', () {
    // Centre angle of the wedge at [index] in the stored canonical frame.
    double centreAngle(int index) =>
        heatmapSegmentStartAngle(index) + kHeatmapSegmentSweep / 2;

    test('stored frame: segment 20 sits just clockwise of vertical (5/20 wire '
        'at top)', () {
      // The scorer anchors cal1 (5/20 wire) at the top (-π/2), so the 20 wedge
      // starts there and its centre is half a sweep clockwise.
      expect(heatmapSegmentStartAngle(0), closeTo(-math.pi / 2, 1e-9));
      expect(centreAngle(0), closeTo(-math.pi / 2 + kHeatmapSegmentSweep / 2,
          1e-9));
    });

    test('display rotation brings segment 20 to the vertical top', () {
      // Rotating the wedge layout by the display rotation must put the 20
      // centre straight up (-π/2) — a standard "20 at the top" board.
      expect(centreAngle(0) + kHeatmapDisplayRotation,
          closeTo(-math.pi / 2, 1e-9));
    });

    test('display rotation is minus half a segment (~9° CCW)', () {
      expect(kHeatmapDisplayRotation, closeTo(-kHeatmapSegmentSweep / 2, 1e-12));
      // After rotation the 5/20 wire (stored at top) sits ~9° left of vertical.
      expect(heatmapSegmentStartAngle(0) + kHeatmapDisplayRotation,
          closeTo(-math.pi / 2 - kHeatmapSegmentSweep / 2, 1e-9));
    });
  });

  testWidgets('empty input renders nothing (SizedBox.shrink)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: HeatmapDartboardWidget(points: const [])),
        ),
      ),
    );
    // No board face is rendered (the AspectRatio wrapper is absent) and the
    // widget collapses to zero size via SizedBox.shrink.
    expect(find.byType(AspectRatio), findsNothing);
    expect(tester.getSize(find.byType(HeatmapDartboardWidget)), Size.zero);
  });

  testWidgets('empty input with placeholder renders the placeholder',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const HeatmapDartboardWidget(
          points: [],
          placeholder: Text('no data'),
        ),
      ),
    );
    expect(find.text('no data'), findsOneWidget);
  });

  testWidgets('non-empty input renders the board CustomPaint', (tester) async {
    const points = <HeatPoint>[
      (x: 0.0, y: 0.0),
      (x: 0.1, y: -0.2),
      (x: -0.3, y: 0.4),
    ];
    await tester.pumpWidget(
      _host(const HeatmapDartboardWidget(points: points)),
    );
    // Board face paints synchronously even before the async image resolves.
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Let the async ui.Image decode + setState complete.
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('switching points rebuilds without throwing', (tester) async {
    await tester.pumpWidget(
      _host(const HeatmapDartboardWidget(points: [(x: 0.0, y: 0.0)])),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _host(
        const HeatmapDartboardWidget(
          points: [(x: 0.5, y: 0.5), (x: -0.5, y: -0.5)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('kHeatmapClockOrder matches a regulation board (20 at top)', () {
    expect(kHeatmapClockOrder.first, 20);
    expect(kHeatmapClockOrder.length, 20);
    expect(kHeatmapClockOrder.toSet().length, 20); // all distinct 1..20
  });
}
