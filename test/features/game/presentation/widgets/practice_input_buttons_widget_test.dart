// Regression tests for #322: in ATC Doubles Only mode the S-N and T-N
// cells must reject taps in addition to rendering dimmed. Prior to the
// fix the dim was purely cosmetic — taps still fired onDartThrown and
// silently wasted a dart because the engine accepted the throw but did
// not advance the target.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_input_buttons_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('PracticeInputButtonsWidget — ATC Doubles Only (#322)', () {
    testWidgets('S-N tap is rejected when doublesOnly is true',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(PracticeInputButtonsWidget(
        gameType: GameType.aroundTheClock,
        currentTarget: 5,
        doublesOnly: true,
        enabled: true,
        onDartThrown: thrown.add,
      )));

      await tester.tap(find.text('S-5'), warnIfMissed: false);
      await tester.pump();
      expect(thrown, isEmpty,
          reason: 'S-5 is dimmed in Doubles Only — tap should be ignored');
    });

    testWidgets('T-N tap is rejected when doublesOnly is true',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(PracticeInputButtonsWidget(
        gameType: GameType.aroundTheClock,
        currentTarget: 5,
        doublesOnly: true,
        enabled: true,
        onDartThrown: thrown.add,
      )));

      await tester.tap(find.text('T-5'), warnIfMissed: false);
      await tester.pump();
      expect(thrown, isEmpty,
          reason: 'T-5 is dimmed in Doubles Only — tap should be ignored');
    });

    testWidgets('D-N and MISS still fire in Doubles Only', (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(PracticeInputButtonsWidget(
        gameType: GameType.aroundTheClock,
        currentTarget: 5,
        doublesOnly: true,
        enabled: true,
        onDartThrown: thrown.add,
      )));

      await tester.tap(find.text('D-5'));
      await tester.pump();
      await tester.tap(find.text('MISS'));
      await tester.pump();
      expect(thrown, ['D5', 'MISS']);
    });

    testWidgets('S-N and T-N fire when doublesOnly is false (standard ATC)',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(PracticeInputButtonsWidget(
        gameType: GameType.aroundTheClock,
        currentTarget: 5,
        doublesOnly: false,
        enabled: true,
        onDartThrown: thrown.add,
      )));

      await tester.tap(find.text('S-5'));
      await tester.pump();
      await tester.tap(find.text('T-5'));
      await tester.pump();
      expect(thrown, ['5', 'T5']);
    });
  });

  // #500: in correction mode the sheet must offer the FULL board picker for
  // every target-scoped practice type, so a false-positive advance can be
  // corrected to the segment actually thrown — not just the (already advanced)
  // live target's segments.
  group('PracticeInputButtonsWidget — correction mode full picker (#500)', () {
    for (final gameType in [
      GameType.aroundTheClock,
      GameType.shanghai,
      GameType.bobs27,
    ]) {
      testWidgets('$gameType correction sheet shows the full grid, not the bar',
          (tester) async {
        final thrown = <String>[];
        await tester.pumpWidget(_wrap(PracticeInputButtonsWidget(
          gameType: gameType,
          currentTarget: 19, // live (advanced) target
          enabled: true,
          isCorrection: true,
          onDartThrown: thrown.add,
        )));

        // The full board picker replaces the restricted target bar entirely.
        expect(find.byType(DartInputGridWidget), findsOneWidget);
        expect(find.text('D-19'), findsNothing);

        // Single Bull (text '25') is a segment the restricted ATC/Bob's bars
        // never offer — tapping it proves the full picker is wired through.
        await tester.tap(find.text('25'));
        await tester.pump();
        expect(thrown, ['SB']);
      });
    }

    testWidgets('live (non-correction) ATC entry keeps the target-scoped bar',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(PracticeInputButtonsWidget(
        gameType: GameType.aroundTheClock,
        currentTarget: 19,
        enabled: true,
        onDartThrown: thrown.add,
      )));

      // The restricted bar shows S-19; the full grid never would.
      expect(find.text('S-19'), findsOneWidget);
      expect(find.bySemanticsLabel('Single 1'), findsNothing);
    });
  });
}
