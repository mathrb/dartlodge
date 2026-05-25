// Regression tests for #324: Catch 40 must surface which of the 2 visits
// the player is on, so they know whether they still have a 2nd visit
// available or are on their final 3 darts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_target_display_widget.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));

void main() {
  group('PracticeTargetDisplayWidget — Catch 40 visit indicator (#324)', () {
    Widget makeWidget({required int dartsOnTarget, int round = 1, int score = 0}) {
      return _wrap(PracticeTargetDisplayWidget(
        gameType: GameType.catch40,
        currentTarget: 60 + round,
        practiceRound: round,
        totalRounds: 40,
        score: score,
        practiceAttempts: 0,
        practiceSuccesses: 0,
        catch40DartsOnTarget: dartsOnTarget,
      ));
    }

    testWidgets('shows "Visit 1/2" at start of round (0 darts)',
        (tester) async {
      await tester.pumpWidget(makeWidget(dartsOnTarget: 0));
      expect(find.text('Score: 0 | Visit 1/2'), findsOneWidget);
    });

    testWidgets('shows "Visit 1/2" mid-visit-1 (2 darts)', (tester) async {
      await tester.pumpWidget(makeWidget(dartsOnTarget: 2));
      expect(find.text('Score: 0 | Visit 1/2'), findsOneWidget);
    });

    testWidgets('shows "Visit 2/2" at start of visit 2 (3 darts after auto-advance)',
        (tester) async {
      await tester.pumpWidget(makeWidget(dartsOnTarget: 3));
      expect(find.text('Score: 0 | Visit 2/2'), findsOneWidget);
    });

    testWidgets('shows "Visit 2/2" mid-visit-2 (5 darts)', (tester) async {
      await tester.pumpWidget(makeWidget(dartsOnTarget: 5));
      expect(find.text('Score: 0 | Visit 2/2'), findsOneWidget);
    });

    testWidgets('non-Catch-40 game types do not show a visit indicator',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeTargetDisplayWidget(
        gameType: GameType.bobs27,
        currentTarget: 1,
        practiceRound: 1,
        totalRounds: 20,
        score: 27,
        practiceAttempts: 0,
        practiceSuccesses: 0,
      )));
      expect(find.textContaining('Visit'), findsNothing);
    });
  });
}
