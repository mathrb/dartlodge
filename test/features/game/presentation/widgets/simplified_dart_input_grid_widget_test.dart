// Tests for the opt-in simplified scoring keypad (#720): four rows (1–7, 8–14,
// 15–20 + an arm-aware Bull cell, then MISS / Double / Triple). The Bull cell
// follows the armed multiplier — single bull by default, double bull when
// Double is armed, non-selectable when Triple is armed. The widget must emit the
// same segment strings as the full grid so the engine is unchanged.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dot_row_widget.dart';
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

    testWidgets('all three number rows are present (1–7, 8–14, 15–20)',
        (tester) async {
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: (_) {})));

      // One representative number from each row plus the Bull cell.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('25'), findsOneWidget); // Bull, single by default
    });

    testWidgets('MISS emits MISS', (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('MISS'));
      await tester.pump();

      expect(thrown, ['MISS']);
    });

    testWidgets('Bull with nothing armed emits single bull', (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('25'));
      await tester.pump();

      expect(thrown, ['SB']);
    });

    testWidgets('Double armed, Bull emits double bull then disarms',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('DOUBLE'));
      await tester.pump();
      // The Bull cell now reads 50; tapping it scores a double bull.
      await tester.tap(find.text('50'));
      await tester.pump();
      // Arm should have cleared: the next number is a plain single.
      await tester.tap(find.text('20'));
      await tester.pump();

      expect(thrown, ['DB', '20']);
    });

    testWidgets('Triple armed makes the Bull cell non-selectable',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: thrown.add)));

      await tester.tap(find.text('TRIPLE'));
      await tester.pump();
      // Bull is disabled (there is no triple bull): the tap does nothing…
      await tester.tap(find.text('BULL'), warnIfMissed: false);
      await tester.pump();
      // …and the arm is still set, so the next number is a triple.
      await tester.tap(find.text('20'));
      await tester.pump();

      expect(thrown, ['T20']);
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

    // The multiplier dots under each cell reflect the armed multiplier live:
    // 1 dot single (default), 2 double, 3 triple. 20 numbers + the Bull cell all
    // carry dots, except the Bull cell when Triple is armed (no triple bull).
    Finder dotsWithCount(int n) =>
        find.byWidgetPredicate((w) => w is DotRow && w.count == n);

    testWidgets('nothing armed shows one dot on every cell (numbers + Bull)',
        (tester) async {
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: (_) {})));

      // 20 numbers (1–20) + the single-bull cell.
      expect(dotsWithCount(1), findsNWidgets(21));
      expect(dotsWithCount(2), findsNothing);
      expect(dotsWithCount(3), findsNothing);
    });

    testWidgets('arming Double shows two dots on every cell (numbers + Bull)',
        (tester) async {
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: (_) {})));

      await tester.tap(find.text('DOUBLE'));
      await tester.pump();

      // 20 numbers + the double-bull cell.
      expect(dotsWithCount(2), findsNWidgets(21));
      expect(dotsWithCount(1), findsNothing);
    });

    testWidgets('arming Triple shows three dots on numbers and none on Bull',
        (tester) async {
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: (_) {})));

      await tester.tap(find.text('TRIPLE'));
      await tester.pump();

      // 20 numbers only — the Bull cell is inert (no triple bull) and dot-free.
      expect(dotsWithCount(3), findsNWidgets(20));
      expect(dotsWithCount(1), findsNothing);
      expect(dotsWithCount(2), findsNothing);
    });

    testWidgets('dots revert to one after a number tap disarms', (tester) async {
      await tester.pumpWidget(_wrap(
          SimplifiedDartInputGridWidget(onSegmentTapped: (_) {})));

      await tester.tap(find.text('TRIPLE'));
      await tester.pump();
      await tester.tap(find.text('20'));
      await tester.pump();

      expect(dotsWithCount(1), findsNWidgets(21));
      expect(dotsWithCount(3), findsNothing);
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
