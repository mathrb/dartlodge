// Regression tests for #324: Catch 40 must surface which of the 2 visits
// the player is on, so they know whether they still have a 2nd visit
// available or are on their final 3 darts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/presentation/widgets/hero_metric_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_target_display_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  group('PracticeTargetDisplayWidget — Catch 40 visit indicator (#324)', () {
    Widget makeWidget({
      required int dartsOnTarget,
      int round = 1,
      int score = 0,
      int? remaining,
    }) {
      return _wrap(PracticeTargetDisplayWidget(
        gameType: GameType.catch40,
        currentTarget: 60 + round,
        practiceRound: round,
        totalRounds: 40,
        score: score,
        practiceAttempts: 0,
        practiceSuccesses: 0,
        catch40DartsOnTarget: dartsOnTarget,
        catch40TargetRemaining: remaining ?? (60 + round),
      ));
    }

    testWidgets('shows "Visit 1/2" at start of round (0 darts)',
        (tester) async {
      await tester.pumpWidget(makeWidget(dartsOnTarget: 0));
      expect(find.text('Target 61 | Visit 1/2 | Score 0'), findsOneWidget);
    });

    testWidgets('shows "Visit 1/2" mid-visit-1 (2 darts)', (tester) async {
      await tester.pumpWidget(makeWidget(dartsOnTarget: 2));
      expect(find.text('Target 61 | Visit 1/2 | Score 0'), findsOneWidget);
    });

    testWidgets('shows "Visit 2/2" at start of visit 2 (3 darts after auto-advance)',
        (tester) async {
      await tester.pumpWidget(makeWidget(dartsOnTarget: 3));
      expect(find.text('Target 61 | Visit 2/2 | Score 0'), findsOneWidget);
    });

    testWidgets('shows "Visit 2/2" mid-visit-2 (5 darts)', (tester) async {
      await tester.pumpWidget(makeWidget(dartsOnTarget: 5));
      expect(find.text('Target 61 | Visit 2/2 | Score 0'), findsOneWidget);
    });

    testWidgets('central display shows current remaining, not original target',
        (tester) async {
      // Round 1 (target 61), player has thrown enough to bring remaining to 16.
      await tester.pumpWidget(makeWidget(
        dartsOnTarget: 1,
        round: 1,
        remaining: 16,
      ));
      // The big central text reflects what's LEFT, not the static target.
      expect(find.text('16'), findsOneWidget);
      expect(find.text('61'), findsNothing,
          reason: 'big number should NOT show the original target (#326)');
      // The secondary line still surfaces the round's target for context.
      expect(find.text('Target 61 | Visit 1/2 | Score 0'), findsOneWidget);
    });

    testWidgets('central display shows reset value after bust', (tester) async {
      // After a bust the engine resets remaining to currentTarget.
      await tester.pumpWidget(makeWidget(
        dartsOnTarget: 1,
        round: 1,
        remaining: 61,
      ));
      expect(find.text('61'), findsOneWidget);
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

  group('PracticeTargetDisplayWidget — heroSize (#445)', () {
    testWidgets('heroSize renders the target via HeroMetricWidget',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeTargetDisplayWidget(
        gameType: GameType.aroundTheClock,
        currentTarget: 14,
        practiceRound: 1,
        totalRounds: null,
        score: 0,
        practiceAttempts: 0,
        practiceSuccesses: 0,
        heroSize: true,
      )));

      expect(find.byType(HeroMetricWidget), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    });

    testWidgets('default (no heroSize) keeps the inline target, no hero',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeTargetDisplayWidget(
        gameType: GameType.aroundTheClock,
        currentTarget: 14,
        practiceRound: 1,
        totalRounds: null,
        score: 0,
        practiceAttempts: 0,
        practiceSuccesses: 0,
      )));

      expect(find.byType(HeroMetricWidget), findsNothing);
      expect(find.text('14'), findsOneWidget);
    });
  });
}
