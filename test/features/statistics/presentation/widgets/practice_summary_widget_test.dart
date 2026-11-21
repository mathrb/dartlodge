import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/practice_summary_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  group('PracticeSummaryWidget', () {
    testWidgets('Around the Clock (solo) renders turns + darts', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.aroundTheClock(
          competitors: [
            AtcCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              turnsCompleted: 12,
              totalDarts: 35,
              lastTargetHit: 20,
              finished: true,
            ),
          ],
          winnerCompetitorId: 'c1',
          doublesOnly: false,
        ),
      )));

      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text('Around the Clock'), findsOneWidget);
      expect(find.text('TURNS'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('DARTS'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      // No doubles-only tag when variant is standard.
      expect(find.text('DOUBLES ONLY'), findsNothing);
      // Solo drill: no per-player breakdown grid.
      expect(find.text('Finished'), findsNothing);
    });

    testWidgets('Around the Clock doubles-only shows tag', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.aroundTheClock(
          competitors: [
            AtcCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              turnsCompleted: 12,
              totalDarts: 35,
              lastTargetHit: 20,
              finished: true,
            ),
          ],
          winnerCompetitorId: 'c1',
          doublesOnly: true,
        ),
      )));

      expect(find.text('DOUBLES ONLY'), findsOneWidget);
    });

    testWidgets(
        'Around the Clock solo COMPLETED game keeps hero-only chrome (no breakdown)',
        (tester) async {
      // Regression for the CR4 finding: a solo ATC drill that the lone
      // player completes sets winnerCompetitorId on the result, so the
      // isSolo guard must key off competitors.length, not winnerId.
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.aroundTheClock(
          competitors: [
            AtcCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              turnsCompleted: 8,
              totalDarts: 23,
              lastTargetHit: 20,
              finished: true,
            ),
          ],
          winnerCompetitorId: 'c1',
          doublesOnly: false,
        ),
      )));

      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text('TURNS'), findsOneWidget);
      // No breakdown grid — single-player completion uses hero-only chrome.
      expect(find.text('LAST TARGET HIT'), findsNothing);
      expect(find.text('FINISHED'), findsNothing);
      expect(find.text('WINNER'), findsNothing);
    });

    testWidgets('Around the Clock multi-player renders winner hero + per-player breakdown',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.aroundTheClock(
          competitors: [
            AtcCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              turnsCompleted: 8,
              totalDarts: 23,
              lastTargetHit: 20,
              finished: true,
            ),
            AtcCompetitorResult(
              competitorId: 'c2',
              competitorName: 'Bob',
              turnsCompleted: 8,
              totalDarts: 24,
              lastTargetHit: 13,
              finished: false,
            ),
            AtcCompetitorResult(
              competitorId: 'c3',
              competitorName: 'Carol',
              turnsCompleted: 8,
              totalDarts: 24,
              lastTargetHit: 4,
              finished: false,
            ),
          ],
          winnerCompetitorId: 'c1',
          doublesOnly: false,
        ),
      )));

      // Hero shows the winner's data.
      expect(find.text('ALICE'), findsOneWidget);
      // Breakdown surfaces all 3 competitors (Alice carries the WINNER tag).
      // Bob appears at minimum in the breakdown column header.
      expect(find.text('Bob'), findsWidgets);
      expect(find.text('Carol'), findsWidgets);
      expect(find.text('WINNER'), findsOneWidget);
      // Per-player rows are present — category labels are uppercased
      // by the breakdown chrome (#230).
      expect(find.text('LAST TARGET HIT'), findsOneWidget);
      expect(find.text('FINISHED'), findsOneWidget);
      // Non-winners' highest-target values surface.
      expect(find.text('13'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('Catch 40 renders score/120 and targets/40', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.catch40(
          competitorName: 'Alice',
          score: 78,
          targetsCleared: 26,
        ),
      )));

      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text('Catch 40'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('78 / 120'), findsOneWidget);
      expect(find.text('TARGETS'), findsOneWidget);
      expect(find.text('26 / 40'), findsOneWidget);
    });

    testWidgets("Bob's 27 (not busted) shows final score + round",
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.bobs27(
          competitorName: 'Alice',
          finalScore: 162,
          roundReached: 21,
          bustedToZero: false,
        ),
      )));

      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text("Bob's 27"), findsOneWidget);
      expect(find.text('FINAL SCORE'), findsOneWidget);
      expect(find.text('162'), findsOneWidget);
      expect(find.text('ROUND'), findsOneWidget);
      // 21 rounds incl. the Double-Bull finale (#588).
      expect(find.text('21 / 21'), findsOneWidget);
      expect(find.text('BUSTED'), findsNothing);
    });

    testWidgets("Bob's 27 busted shows BUSTED tag + muted style",
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.bobs27(
          competitorName: 'Alice',
          finalScore: 0,
          roundReached: 8,
          bustedToZero: true,
        ),
      )));

      expect(find.text('BUSTED'), findsOneWidget);
      expect(find.text("Bob's 27: drill ended"), findsOneWidget);
    });

    testWidgets(
        'Around the Clock abandoned (no winner, no darts) shows ENDED EARLY (#335)',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.aroundTheClock(
          competitors: [
            AtcCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              turnsCompleted: 0,
              totalDarts: 0,
              lastTargetHit: 0,
              finished: false,
            ),
            AtcCompetitorResult(
              competitorId: 'c2',
              competitorName: 'Bob',
              turnsCompleted: 0,
              totalDarts: 0,
              lastTargetHit: 0,
              finished: false,
            ),
          ],
          winnerCompetitorId: null,
          doublesOnly: false,
        ),
      )));

      // Pre-fix: Alice rendered as the hero "winner" with 0/0 stats.
      // Post-fix: a generic "no winner" hero with the ENDED EARLY badge.
      expect(find.text('ENDED EARLY'), findsOneWidget);
      expect(find.text('NO WINNER'), findsOneWidget,
          reason: 'PostGameHeroCard uppercases the headline');
      expect(find.text('ALICE'), findsNothing,
          reason: 'Alice must not appear as the hero headline');
      // The hero's WINNER subtitle column should not appear when no winner
      // (the breakdown table below still shows zeroed stats per player).
      expect(find.text('WINNER'), findsNothing);
    });

    group('drill ended early from the menu', () {
      Color onSurface() => AppTheme.light().colorScheme.onSurface;

      testWidgets(
          'Around the Clock, 3 players with darts thrown: no player is '
          'presented as the winner', (tester) async {
        await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
          result: GameResult.aroundTheClock(
            competitors: [
              AtcCompetitorResult(
                competitorId: 'c1',
                competitorName: 'Alexandra',
                turnsCompleted: 1,
                totalDarts: 3,
                lastTargetHit: 3,
                finished: false,
              ),
              AtcCompetitorResult(
                competitorId: 'c3',
                competitorName: 'Bo',
                turnsCompleted: 1,
                totalDarts: 2,
                lastTargetHit: 2,
                finished: false,
              ),
              AtcCompetitorResult(
                competitorId: 'c2',
                competitorName: 'Jean-Baptiste',
                turnsCompleted: 1,
                totalDarts: 3,
                lastTargetHit: 0,
                finished: false,
              ),
            ],
            winnerCompetitorId: null,
            doublesOnly: false,
          ),
        )));

        expect(find.text('ENDED EARLY'), findsOneWidget);
        expect(find.text('NO WINNER'), findsOneWidget);
        // The hero uppercases its headline; the breakdown keeps names as-is.
        expect(find.text('ALEXANDRA'), findsNothing,
            reason: 'the first-listed player must not headline the hero');
        expect(find.text('Alexandra'), findsOneWidget);
        expect(find.text('WINNER'), findsNothing);
        // Each player's progress is still in the breakdown.
        expect(find.text('LAST TARGET HIT'), findsOneWidget);
      });

      testWidgets(
          'Around the Clock solo with darts thrown: badge, muted stats, '
          'player still named', (tester) async {
        await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
          result: GameResult.aroundTheClock(
            competitors: [
              AtcCompetitorResult(
                competitorId: 'c1',
                competitorName: 'Alice',
                turnsCompleted: 4,
                totalDarts: 12,
                lastTargetHit: 7,
                finished: false,
              ),
            ],
            winnerCompetitorId: null,
            doublesOnly: true,
          ),
        )));

        expect(find.text('ENDED EARLY'), findsOneWidget);
        expect(find.text('DOUBLES ONLY'), findsNothing,
            reason: 'one badge slot: ended early wins');
        expect(find.text('ALICE'), findsOneWidget);
        final turns = tester.widget<Text>(find.text('4'));
        expect(turns.style?.color, onSurface(),
            reason: 'the turns stat must not be accent-emphasised');
      });

      testWidgets("Bob's 27 ended at round 1: badge, no green emphasis",
          (tester) async {
        await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
          result: GameResult.bobs27(
            competitorName: 'Alexandra',
            finalScore: 27,
            roundReached: 1,
            bustedToZero: false,
            endedEarly: true,
          ),
        )));

        expect(find.text('ENDED EARLY'), findsOneWidget);
        expect(find.text('BUSTED'), findsNothing);
        expect(find.text("Bob's 27"), findsOneWidget);
        final score = tester.widget<Text>(find.text('27'));
        expect(score.style?.color, onSurface());
      });

      testWidgets("Bob's 27 finished naturally keeps the emphasised score",
          (tester) async {
        await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
          result: GameResult.bobs27(
            competitorName: 'Alexandra',
            finalScore: 162,
            roundReached: 21,
            bustedToZero: false,
          ),
        )));

        expect(find.text('ENDED EARLY'), findsNothing);
        final score = tester.widget<Text>(find.text('162'));
        expect(score.style?.color, isNot(onSurface()));
      });

      testWidgets('Catch 40 ended early: badge, no emphasis', (tester) async {
        await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
          result: GameResult.catch40(
            competitorName: 'Alice',
            score: 3,
            targetsCleared: 1,
            endedEarly: true,
          ),
        )));

        expect(find.text('ENDED EARLY'), findsOneWidget);
        final score = tester.widget<Text>(find.text('3 / 120'));
        expect(score.style?.color, onSurface());
      });
    });

    testWidgets("Bob's 27 negative final score renders in error colour (#339)",
        (tester) async {
      const lightTheme = AppTheme.light;
      final errorColor = lightTheme().colorScheme.error;
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.bobs27(
          competitorName: 'Alice',
          finalScore: -3,
          roundReached: 5,
          bustedToZero: true,
        ),
      )));

      // The final-score Text renders the literal "-3"; its colour should
      // be the theme's error colour, not the standard accent.
      final scoreText = tester.widget<Text>(find.text('-3'));
      expect(scoreText.style?.color, errorColor);
    });

    testWidgets('170 Checkout single attempt success shows "Checked out!"',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.checkoutPractice(
          competitorName: 'Alice',
          attempts: 1,
          successes: 1,
          dartsThrown: 9,
          fromScore: 170,
        ),
      )));

      expect(find.text('CHECKED OUT!'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('DARTS'), findsOneWidget);
      expect(find.text('FROM'), findsOneWidget);
      expect(find.text('170'), findsOneWidget);
      // #636: darts-per-checkout side-stat (9 darts / 1 checkout = 9), so "9"
      // now appears twice (DARTS total + DARTS/CHECKOUT).
      expect(find.text('DARTS/CHECKOUT'), findsOneWidget);
      expect(find.text('9'), findsNWidgets(2));
    });

    testWidgets('170 Checkout single attempt failure shows "Not checked out"',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.checkoutPractice(
          competitorName: 'Alice',
          attempts: 1,
          successes: 0,
          dartsThrown: 9,
          fromScore: 170,
        ),
      )));

      expect(find.text('NOT CHECKED OUT'), findsOneWidget);
      expect(find.text('170'), findsOneWidget);
      expect(find.text('CHECKED OUT'), findsNothing);
    });

    testWidgets(
        '170 Checkout quota not met: header denominator is the quota (#603)',
        (tester) async {
      // quota 2, 1 success over 3 turns → "1 OF 2" (quota), not "1 OF 3"
      // (attempts). The SUCCESS RATE side-stat stays successes/attempts.
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.checkoutPractice(
          competitorName: 'Alice',
          attempts: 3,
          successes: 1,
          dartsThrown: 9,
          fromScore: 170,
          targetSuccesses: 2,
        ),
      )));

      expect(find.text('1 OF 2 CHECKOUTS'), findsOneWidget);
      expect(find.text('1 OF 3 CHECKOUTS'), findsNothing);
      expect(find.text('SUCCESS RATE'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('DARTS'), findsOneWidget);
      // #636: DARTS/CHECKOUT side-stat (9 / 1 = 9) → "9" appears twice.
      expect(find.text('DARTS/CHECKOUT'), findsOneWidget);
      expect(find.text('9'), findsNWidgets(2));
      expect(find.text('CHECKED OUT'), findsNothing);
    });

    testWidgets(
        '170 Checkout quota met with a busted turn still shows the badge (#603)',
        (tester) async {
      // quota 2 met (2 successes) but 3 turns (one busted), so successes <
      // attempts — the old `successes == attempts` badge condition wrongly
      // hid the badge. New condition is "quota met".
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.checkoutPractice(
          competitorName: 'Alice',
          attempts: 3,
          successes: 2,
          dartsThrown: 9,
          fromScore: 170,
          targetSuccesses: 2,
        ),
      )));

      expect(find.text('CHECKED OUT'), findsOneWidget);
      expect(find.text('2 OF 2 CHECKOUTS'), findsOneWidget);
    });

    testWidgets('170 Checkout ∞ mode shows a plain checkout count (#603)',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.checkoutPractice(
          competitorName: 'Alice',
          attempts: 5,
          successes: 3,
          dartsThrown: 15,
          fromScore: 170,
          targetSuccesses: null,
        ),
      )));

      expect(find.text('3 CHECKOUTS'), findsOneWidget);
      expect(find.text('CHECKED OUT'), findsNothing);
    });

    testWidgets('170 Checkout no success shows "Not checked out" (#603)',
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.checkoutPractice(
          competitorName: 'Alice',
          attempts: 2,
          successes: 0,
          dartsThrown: 6,
          fromScore: 170,
          targetSuccesses: 2,
        ),
      )));

      expect(find.text('NOT CHECKED OUT'), findsOneWidget);
      expect(find.text('CHECKED OUT'), findsNothing);
    });
  });
}
