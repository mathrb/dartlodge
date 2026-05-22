import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/widgets/game_summary_section_widget.dart';
import 'package:dart_lodge/core/widgets/post_game_hero_card_widget.dart';
import 'package:dart_lodge/core/widgets/post_game_stats_breakdown_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

GameStats _statsForX01() => GameStats(
      gameId: 'g1',
      gameType: GameType.x01.name,
      byCompetitor: [
        CompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          byPlayer: const [],
          threeDartAverage: 75.5,
          legsWon: 1,
          totalDartsThrown: 21,
          checkoutPercentage: 50.0,
          highestCheckout: 64,
          oneEightyTurns: 1,
        ),
        CompetitorStats(
          competitorId: 'c2',
          competitorName: 'Bob',
          byPlayer: const [],
          threeDartAverage: 60.0,
          legsWon: 0,
          totalDartsThrown: 27,
        ),
      ],
    );

GameStats _statsForCricket() => GameStats(
      gameId: 'g1',
      gameType: GameType.cricket.name,
      byCompetitor: [
        CompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          byPlayer: const [],
          threeDartAverage: 0,
          marksPerRound: 2.5,
          legsWon: 1,
          totalDartsThrown: 30,
        ),
      ],
    );

void main() {
  group('GameSummarySectionWidget — extracted-chrome regression', () {
    testWidgets('x01 multi-competitor renders hero, opponents, breakdown',
        (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: _statsForX01(),
      )));

      // Hero card (winner)
      expect(find.byType(PostGameHeroCard), findsOneWidget);
      expect(find.text('WINNER'), findsWidgets);
      expect(find.text('ALICE'), findsWidgets);
      // "AVG PPR" / "DARTS" appear in the hero card, opponent card, and
      // breakdown table — just assert presence.
      expect(find.text('AVG PPR'), findsWidgets);
      expect(find.text('DARTS'), findsWidgets);

      // Breakdown table
      expect(find.byType(PostGameStatsBreakdown), findsOneWidget);
      expect(find.text('STATISTICS BREAKDOWN'), findsOneWidget);
      // X01 rows present
      expect(find.text('AVG PPR'), findsWidgets);
      expect(find.text('CHECKOUT'), findsOneWidget);
      expect(find.text('BEST OUT'), findsOneWidget);
      expect(find.text('180S'), findsOneWidget);
    });

    testWidgets('cricket hero uses AVG MPR label', (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: _statsForCricket(),
      )));

      expect(find.text('AVG MPR'), findsWidgets);
      expect(find.text('AVG PPR'), findsNothing);
      // Cricket-specific breakdown rows
      expect(find.text('FIRST 9 MPR'), findsOneWidget);
      expect(find.text('5 MARKS'), findsOneWidget);
      expect(find.text('9 MARKS'), findsOneWidget);
    });

    testWidgets('count-up omits LEGS WON subline on winner card',
        (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: GameStats(
          gameId: 'g1',
          gameType: GameType.countUp.name,
          byCompetitor: [
            CompetitorStats(
              competitorId: 'c1',
              competitorName: 'Alice',
              byPlayer: const [],
              threeDartAverage: 80.0,
              legsWon: 1,
              totalDartsThrown: 24,
            ),
          ],
        ),
      )));

      expect(find.text('1 LEG WON'), findsNothing);
      expect(find.text('ALICE'), findsWidgets);
    });

    testWidgets('no winner (no legs won) hides the hero card',
        (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: GameStats(
          gameId: 'g1',
          gameType: GameType.x01.name,
          byCompetitor: [
            CompetitorStats(
              competitorId: 'c1',
              competitorName: 'Alice',
              byPlayer: const [],
              threeDartAverage: 0,
              legsWon: 0,
              totalDartsThrown: 0,
            ),
            CompetitorStats(
              competitorId: 'c2',
              competitorName: 'Bob',
              byPlayer: const [],
              threeDartAverage: 0,
              legsWon: 0,
              totalDartsThrown: 0,
            ),
          ],
        ),
      )));

      expect(find.byType(PostGameHeroCard), findsNothing);
      expect(find.text('WINNER'), findsNothing);
      // Breakdown still rendered.
      expect(find.byType(PostGameStatsBreakdown), findsOneWidget);
    });

    // Regression for #261: runner-ups on Count-Up were all labelled
    // "OPPONENT" with no rank distinction. They're now sorted by PPR
    // descending (proxy for total score, since count-up always plays the
    // same dart count per competitor) and labelled 2ND / 3RD.
    testWidgets('count-up ranks runner-ups 2ND / 3RD instead of OPPONENT',
        (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: GameStats(
          gameId: 'g1',
          gameType: GameType.countUp.name,
          byCompetitor: [
            // Winner.
            CompetitorStats(
              competitorId: 'c1',
              competitorName: 'Alice',
              byPlayer: const [],
              threeDartAverage: 90.0,
              legsWon: 1,
              totalDartsThrown: 24,
            ),
            // 3rd by score.
            CompetitorStats(
              competitorId: 'c3',
              competitorName: 'Cara',
              byPlayer: const [],
              threeDartAverage: 50.0,
              legsWon: 0,
              totalDartsThrown: 24,
            ),
            // 2nd by score.
            CompetitorStats(
              competitorId: 'c2',
              competitorName: 'Bob',
              byPlayer: const [],
              threeDartAverage: 75.0,
              legsWon: 0,
              totalDartsThrown: 24,
            ),
          ],
        ),
      )));

      // Both the opponent card AND the breakdown column subtitle use
      // ordinal labels — expect at least one of each, none of "OPPONENT".
      expect(find.text('2ND'), findsWidgets);
      expect(find.text('3RD'), findsWidgets);
      expect(find.text('OPPONENT'), findsNothing);
      // Bob (75 PPR) and Cara (50 PPR) both render on the page. Ordering
      // is implied by the ordinal labels above — explicit positional
      // assertions are brittle against table-layout changes.
      expect(find.text('BOB'), findsOneWidget);
      expect(find.text('CARA'), findsOneWidget);
    });
  });
}
