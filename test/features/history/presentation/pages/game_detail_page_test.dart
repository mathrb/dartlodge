// Widget tests for GameDetailPage's per-gameType stats branching (#255).
// Asserts that x01/cricket/countUp games render the X01-shaped chrome
// (GameSummarySectionWidget) while shanghai + the four practice drills
// route through gameResultProvider to ShanghaiSummaryWidget /
// PracticeSummaryWidget respectively.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/providers/statistics_providers.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/widgets/game_summary_section_widget.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/features/history/presentation/pages/game_detail_page.dart';
import 'package:dart_lodge/features/history/presentation/providers/game_detail_provider.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:dart_lodge/features/history/presentation/state/game_detail_state.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/practice_summary_widget.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/shanghai_summary_widget.dart';

class _StubGameDetailNotifier extends GameDetailNotifier {
  _StubGameDetailNotifier(this._state);
  final GameDetailState? _state;

  @override
  Future<GameDetailState?> build(String gameId) async => _state;
}

Game _makeGame(GameType type) {
  final GameConfig config = switch (type) {
    GameType.x01 => const GameConfig.x01(
        startingScore: 501,
        inStrategy: 'straight',
        outStrategy: 'double',
      ),
    GameType.cricket => const GameConfig.cricket(),
    GameType.shanghai => const GameConfig.shanghai(),
    GameType.aroundTheClock => const GameConfig.aroundTheClock(),
    GameType.bobs27 => const GameConfig.bobs27(),
    GameType.catch40 => const GameConfig.catch40(),
    GameType.checkoutPractice => const GameConfig.checkoutPractice(),
    GameType.countUp => const GameConfig.countUp(),
  };
  return Game(
    gameId: 'game-1',
    gameType: type,
    config: config,
    startTime: DateTime(2024),
    endTime: DateTime(2024, 1, 1, 12),
    isComplete: true,
  );
}

Competitor _competitor() => const Competitor(
      competitorId: 'c1',
      gameId: 'game-1',
      type: CompetitorType.solo,
      name: 'Alice',
      players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
    );

GameStats _stats(GameType type) => GameStats(
      gameId: 'game-1',
      byCompetitor: [
        CompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          byPlayer: const [],
          threeDartAverage: 60.0,
          legsWon: 1,
          totalDartsThrown: 21,
        ),
      ],
      gameType: type.name,
    );

GameDetailState _detail(GameType type, {GameStats? stats}) => GameDetailState(
      game: _makeGame(type),
      competitors: [_competitor()],
      gameStats: stats ?? _stats(type),
    );

Widget _pump({
  required GameType type,
  GameResult? gameResult,
}) {
  return ProviderScope(
    overrides: [
      gameDetailProvider('game-1')
          .overrideWith(() => _StubGameDetailNotifier(_detail(type))),
      if (gameResult != null)
        gameResultProvider('game-1').overrideWith((_) async => gameResult),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: const GameDetailPage(gameId: 'game-1'),
    ),
  );
}

void main() {
  group('GameDetailPage stats branching (#255)', () {
    testWidgets('X01 renders GameSummarySectionWidget', (tester) async {
      await tester.pumpWidget(_pump(type: GameType.x01));
      await tester.pumpAndSettle();

      expect(find.byType(GameSummarySectionWidget), findsOneWidget);
      expect(find.byType(PracticeSummaryWidget), findsNothing);
      expect(find.byType(ShanghaiSummaryWidget), findsNothing);
    });

    testWidgets('Cricket renders GameSummarySectionWidget', (tester) async {
      await tester.pumpWidget(_pump(type: GameType.cricket));
      await tester.pumpAndSettle();

      expect(find.byType(GameSummarySectionWidget), findsOneWidget);
      expect(find.byType(PracticeSummaryWidget), findsNothing);
      expect(find.byType(ShanghaiSummaryWidget), findsNothing);
    });

    testWidgets('Count-up renders GameSummarySectionWidget', (tester) async {
      await tester.pumpWidget(_pump(type: GameType.countUp));
      await tester.pumpAndSettle();

      expect(find.byType(GameSummarySectionWidget), findsOneWidget);
      expect(find.byType(PracticeSummaryWidget), findsNothing);
    });

    testWidgets(
        'Shanghai renders ShanghaiSummaryWidget (no X01 chrome)',
        (tester) async {
      await tester.pumpWidget(_pump(
        type: GameType.shanghai,
        gameResult: const GameResult.shanghai(
          competitors: [
            ShanghaiCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              totalScore: 120,
              shanghaiBonuses: 2,
              bestRound: 60,
              roundsPlayed: 7,
            ),
          ],
          winnerCompetitorId: null,
          totalRounds: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ShanghaiSummaryWidget), findsOneWidget);
      expect(find.byType(GameSummarySectionWidget), findsNothing);
    });

    testWidgets('Around the Clock renders PracticeSummaryWidget',
        (tester) async {
      await tester.pumpWidget(_pump(
        type: GameType.aroundTheClock,
        gameResult: const GameResult.aroundTheClock(
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
          winnerCompetitorId: null,
          doublesOnly: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeSummaryWidget), findsOneWidget);
      expect(find.byType(GameSummarySectionWidget), findsNothing);
      expect(find.text('TURNS'), findsOneWidget);
    });

    testWidgets("Bob's 27 renders PracticeSummaryWidget", (tester) async {
      await tester.pumpWidget(_pump(
        type: GameType.bobs27,
        gameResult: const GameResult.bobs27(
          competitorName: 'Alice',
          finalScore: 87,
          roundReached: 20,
          bustedToZero: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeSummaryWidget), findsOneWidget);
      expect(find.byType(GameSummarySectionWidget), findsNothing);
      expect(find.text('FINAL SCORE'), findsOneWidget);
    });

    testWidgets('Catch 40 renders PracticeSummaryWidget', (tester) async {
      await tester.pumpWidget(_pump(
        type: GameType.catch40,
        gameResult: const GameResult.catch40(
          competitorName: 'Alice',
          score: 80,
          targetsCleared: 30,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeSummaryWidget), findsOneWidget);
      expect(find.byType(GameSummarySectionWidget), findsNothing);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('TARGETS'), findsOneWidget);
      // Practice drills don't play in legs — the "Leg Breakdown / No legs
      // completed" section must be hidden (#294).
      expect(find.text('Leg Breakdown'), findsNothing);
    });

    testWidgets(
        "Practice drills don't render the empty 'Leg Breakdown' footer (#294)",
        (tester) async {
      for (final type in const [
        GameType.aroundTheClock,
        GameType.bobs27,
        GameType.catch40,
        GameType.checkoutPractice,
        GameType.shanghai,
      ]) {
        final result = switch (type) {
          GameType.aroundTheClock => const GameResult.aroundTheClock(
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
              winnerCompetitorId: null,
              doublesOnly: false,
            ),
          GameType.bobs27 => const GameResult.bobs27(
              competitorName: 'Alice',
              finalScore: 87,
              roundReached: 20,
              bustedToZero: false,
            ),
          GameType.catch40 => const GameResult.catch40(
              competitorName: 'Alice',
              score: 80,
              targetsCleared: 30,
            ),
          GameType.checkoutPractice => const GameResult.checkoutPractice(
              competitorName: 'Alice',
              attempts: 1,
              successes: 1,
              dartsThrown: 9,
              fromScore: 170,
            ),
          GameType.shanghai => const GameResult.shanghai(
              competitors: [
                ShanghaiCompetitorResult(
                  competitorId: 'c1',
                  competitorName: 'Alice',
                  totalScore: 120,
                  shanghaiBonuses: 2,
                  bestRound: 60,
                  roundsPlayed: 7,
                ),
              ],
              winnerCompetitorId: null,
              totalRounds: 7,
            ),
          _ => throw StateError('unreachable: $type'),
        };

        await tester.pumpWidget(_pump(type: type, gameResult: result));
        await tester.pumpAndSettle();

        expect(find.text('Leg Breakdown'), findsNothing,
            reason: '$type should not show Leg Breakdown section');
      }
    });

    testWidgets('Checkout Practice renders PracticeSummaryWidget',
        (tester) async {
      await tester.pumpWidget(_pump(
        type: GameType.checkoutPractice,
        gameResult: const GameResult.checkoutPractice(
          competitorName: 'Alice',
          attempts: 1,
          successes: 1,
          dartsThrown: 9,
          fromScore: 170,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeSummaryWidget), findsOneWidget);
      expect(find.byType(GameSummarySectionWidget), findsNothing);
      // X01-style 180s / Best Out rows MUST NOT appear on a checkout drill.
      expect(find.text('180s'), findsNothing);
      expect(find.text('Best Out'), findsNothing);
    });
  });
}
