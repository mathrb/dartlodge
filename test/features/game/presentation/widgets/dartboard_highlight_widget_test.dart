import 'dart:math' as math;

import 'package:dart_lodge/features/game/presentation/widgets/dartboard_highlight_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 200, height: 200, child: child)),
      ),
    );

void main() {
  group('dartboard orientation (#700)', () {
    const sweep = math.pi / 10; // 18° per segment

    // Centre angle of the wedge at [index].
    double centreAngle(int index) =>
        dartboardSegmentStartAngle(index) + sweep / 2;

    test('segment 20 wedge straddles vertical (starts half a segment left)', () {
      expect(
        dartboardSegmentStartAngle(0),
        closeTo(-math.pi / 2 - sweep / 2, 1e-9),
      );
    });

    test('segment 20 is centred at the top (−π/2)', () {
      // The whole point of #700: 20 centred at top, not 9° clockwise of it.
      expect(centreAngle(0), closeTo(-math.pi / 2, 1e-9));
    });

    test('segment 20 wedge spans symmetrically around the top', () {
      final start = dartboardSegmentStartAngle(0);
      final end = start + sweep;
      expect(start, closeTo(-math.pi / 2 - sweep / 2, 1e-9));
      expect(end, closeTo(-math.pi / 2 + sweep / 2, 1e-9));
    });

    test('each segment centre advances one sweep clockwise', () {
      for (var i = 0; i < kDartboardClockOrder.length; i++) {
        expect(centreAngle(i), closeTo(-math.pi / 2 + i * sweep, 1e-9));
      }
    });
  });

  test('kDartboardClockOrder matches a regulation board (20 at top)', () {
    expect(kDartboardClockOrder.first, 20);
    expect(kDartboardClockOrder.length, 20);
    expect(kDartboardClockOrder.toSet().length, 20); // all distinct 1..20
  });

  testWidgets('renders without a highlight target', (tester) async {
    await tester.pumpWidget(
      _host(
        const DartboardHighlightWidget(
          currentTarget: 20,
          doublesOnly: false,
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the bull (null target) without throwing', (tester) async {
    await tester.pumpWidget(
      _host(
        const DartboardHighlightWidget(
          currentTarget: null,
          doublesOnly: true,
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
