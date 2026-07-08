// Tests for the opt-in simplified scoring keypad (#720): numbers plus an
// "armed" Double/Triple multiplier, keeping the MISS / 25 / 50 specials. The
// widget must emit the same segment strings as the full grid so the engine is
// unchanged.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/simplified_dart_input_grid_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('SimplifiedDartInputGridWidget', () {
    testWidgets('number tap with nothing armed emits a single', (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('20'));
      await tester.pump();

      expect(thrown, ['20']);
    });

    testWidgets('Double arms, next number is a double, then disarms',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('DOUBLE'));
      await tester.pump();
      await tester.tap(find.text('20'));
      await tester.pump();
      // Multiplier should have disarmed: the next number is a plain single.
      await tester.tap(find.text('19'));
      await tester.pump();

      expect(thrown, ['D20', '19']);
    });

    testWidgets('Triple arms, next number is a triple', (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('TRIPLE'));
      await tester.pump();
      await tester.tap(find.text('20'));
      await tester.pump();

      expect(thrown, ['T20']);
    });

    testWidgets('re-tapping the armed multiplier disarms it', (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('DOUBLE'));
      await tester.pump();
      await tester.tap(find.text('DOUBLE'));
      await tester.pump();
      await tester.tap(find.text('20'));
      await tester.pump();

      expect(thrown, ['20']);
    });

    testWidgets('specials emit MISS / SB / DB', (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('MISS'));
      await tester.pump();
      await tester.tap(find.text('25'));
      await tester.pump();
      await tester.tap(find.text('50'));
      await tester.pump();

      expect(thrown, ['MISS', 'SB', 'DB']);
    });

    testWidgets('tapping a special while armed emits the special and clears arm',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('TRIPLE'));
      await tester.pump();
      await tester.tap(find.text('MISS'));
      await tester.pump();
      // Arm cleared → next number is a plain single.
      await tester.tap(find.text('20'));
      await tester.pump();

      expect(thrown, ['MISS', '20']);
    });

    testWidgets('an armed multiplier is cleared when the keypad is disabled',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      // Arm Double but never throw, then the turn ends (enabled → false)…
      await tester.tap(find.text('DOUBLE'));
      await tester.pump();
      await tester.pumpWidget(_wrap(SimplifiedDartInputGridWidget(
        onSegmentTapped: thrown.add,
        enabled: false,
      )));
      // …and the next turn begins (enabled → true).
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      // The stale arm must not carry over: the first number is a plain single.
      await tester.tap(find.text('20'));
      await tester.pump();

      expect(thrown, ['20']);
    });

    testWidgets('disabled swallows all taps', (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(SimplifiedDartInputGridWidget(
        onSegmentTapped: thrown.add,
        enabled: false,
      )));

      await tester.tap(find.text('20'), warnIfMissed: false);
      await tester.tap(find.text('DOUBLE'), warnIfMissed: false);
      await tester.tap(find.text('MISS'), warnIfMissed: false);
      await tester.pump();

      expect(thrown, isEmpty);
    });
  });
}
