// Regression tests for #322: in ATC Doubles Only mode the S-N and T-N
// cells must reject taps in addition to rendering dimmed. Prior to the
// fix the dim was purely cosmetic — taps still fired onDartThrown and
// silently wasted a dart because the engine accepted the throw but did
// not advance the target.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/settings/simplified_input_provider.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_input_buttons_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/simplified_dart_input_grid_widget.dart';

/// Forces the simplified keypad on without touching SharedPreferences.
class _FakeSimplifiedInputEnabled extends SimplifiedInputEnabled {
  @override
  Future<bool> build() async => true;
}

Widget _wrap(Widget child, {bool simplified = false}) {
  return ProviderScope(
    overrides: [
      if (simplified)
        simplifiedInputEnabledProvider
            .overrideWith(() => _FakeSimplifiedInputEnabled()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    ),
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

  // #500 / #799: camera-first sheets (correction AND missed-dart entry) must
  // offer the FULL board picker for every target-scoped practice type, so a
  // false-positive advance can be corrected to the segment actually thrown,
  // and a missed dart on another number isn't forced to MISS.
  group('PracticeInputButtonsWidget — fullBoard picker (#500, #799)', () {
    for (final gameType in [
      GameType.aroundTheClock,
      GameType.shanghai,
      GameType.bobs27,
    ]) {
      testWidgets('$gameType fullBoard shows the full grid, not the bar',
          (tester) async {
        final thrown = <String>[];
        await tester.pumpWidget(_wrap(PracticeInputButtonsWidget(
          gameType: gameType,
          currentTarget: 19, // live (advanced) target
          enabled: true,
          fullBoard: true,
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

    testWidgets('fullBoard overrides doublesOnly (full grid, not the bar)',
        (tester) async {
      final thrown = <String>[];
      await tester.pumpWidget(_wrap(PracticeInputButtonsWidget(
        gameType: GameType.aroundTheClock,
        currentTarget: 19,
        doublesOnly: true, // would dim/disable S & T on the bar (#322)
        enabled: true,
        fullBoard: true,
        onDartThrown: thrown.add,
      )));

      // The full grid is shown regardless of doublesOnly; a single fires.
      expect(find.byType(DartInputGridWidget), findsOneWidget);
      expect(find.text('S-19'), findsNothing);
      await tester.tap(find.text('25')); // Single Bull
      await tester.pump();
      expect(thrown, ['SB']);
    });

    testWidgets('manual ATC entry keeps the target-scoped bar',
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

  // #799: every full-board picker follows the Simplified scoring keypad
  // setting; the target-scoped bars are not keypads and never change.
  group('PracticeInputButtonsWidget — simplified keypad setting (#799)', () {
    testWidgets('fullBoard renders the simplified keypad when the setting is on',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PracticeInputButtonsWidget(
          gameType: GameType.aroundTheClock,
          currentTarget: 5,
          enabled: true,
          fullBoard: true,
          onDartThrown: (_) {},
        ),
        simplified: true,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SimplifiedDartInputGridWidget), findsOneWidget);
      expect(find.byType(DartInputGridWidget), findsNothing);
    });

    for (final gameType in [GameType.catch40, GameType.checkoutPractice]) {
      testWidgets('$gameType live entry follows the setting', (tester) async {
        await tester.pumpWidget(_wrap(
          PracticeInputButtonsWidget(
            gameType: gameType,
            currentTarget: 40,
            enabled: true,
            onDartThrown: (_) {},
          ),
          simplified: true,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(SimplifiedDartInputGridWidget), findsOneWidget);
      });
    }

    for (final gameType in [
      GameType.aroundTheClock,
      GameType.shanghai,
      GameType.bobs27,
    ]) {
      testWidgets('$gameType manual entry keeps its bar with the setting on',
          (tester) async {
        await tester.pumpWidget(_wrap(
          PracticeInputButtonsWidget(
            gameType: gameType,
            currentTarget: 5,
            enabled: true,
            onDartThrown: (_) {},
          ),
          simplified: true,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(SimplifiedDartInputGridWidget), findsNothing);
        expect(find.byType(DartInputGridWidget), findsNothing);
        expect(find.text('MISS'), findsOneWidget);
      });
    }
  });
}
