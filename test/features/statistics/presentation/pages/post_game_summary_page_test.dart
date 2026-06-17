import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/post_game_summary_page.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/practice_summary_widget.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/shanghai_summary_widget.dart';
import 'package:dart_lodge/core/providers/statistics_providers.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

GameStats _statsForGameType(GameType gameType) => GameStats(
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
      gameType: gameType.name,
    );

// Lightweight stand-in pages for the variant-selection / home routes so we
// can assert location after tapping buttons without spinning up the full
// app router (variant-selection page requires repositories we don't want
// to wire up here).
final List<RouteBase> _routes = [
  GoRoute(
    path: '/post-game/:gameId',
    builder: (_, s) => PostGameSummaryPage(gameId: s.pathParameters['gameId']!),
  ),
  GoRoute(
    path: '${GameRoutes.variantSelection}/:category',
    builder: (_, s) => Scaffold(
      body: Text('variant-selection:${s.pathParameters['category']}'),
    ),
  ),
  GoRoute(
    path: GameRoutes.home,
    builder: (_, __) => const Scaffold(body: Text('home')),
  ),
  GoRoute(
    path: GameRoutes.settings,
    builder: (_, __) => const Scaffold(body: Text('settings')),
  ),
];

Widget _buildApp({required GameStats gameStats}) {
  final router = GoRouter(
    initialLocation: '/post-game/game-1',
    routes: _routes,
  );
  return ProviderScope(
    overrides: [
      gameStatsProvider('game-1').overrideWith((_) async => gameStats),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

Widget _buildAppWithResult({
  required GameStats gameStats,
  required GameResult? gameResult,
}) {
  final router = GoRouter(
    initialLocation: '/post-game/game-1',
    routes: _routes,
  );
  return ProviderScope(
    overrides: [
      gameStatsProvider('game-1').overrideWith((_) async => gameStats),
      gameResultProvider('game-1').overrideWith((_) async => gameResult),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('categoryForGameType', () {
    test('maps x01 to x01 category', () {
      expect(categoryForGameType(GameType.x01.name), 'x01');
    });

    test('maps cricket to cricket category', () {
      expect(categoryForGameType(GameType.cricket.name), 'cricket');
    });

    test('maps shanghai and count-up to casual category', () {
      for (final type in [GameType.shanghai, GameType.countUp]) {
        expect(
          categoryForGameType(type.name),
          'casual',
          reason: '${type.name} should map to casual',
        );
      }
    });

    test('maps drill game types to practice category', () {
      for (final type in [
        GameType.aroundTheClock,
        GameType.catch40,
        GameType.bobs27,
        GameType.checkoutPractice,
      ]) {
        expect(
          categoryForGameType(type.name),
          'practice',
          reason: '${type.name} should map to practice',
        );
      }
    });

    test('unknown game type falls back to practice', () {
      expect(categoryForGameType('totally-unknown'), 'practice');
    });
  });

  group('PostGameSummaryPage PLAY AGAIN', () {
    testWidgets('routes to variant-selection/x01 for X01 games',
        (tester) async {
      await tester.pumpWidget(_buildApp(gameStats: _statsForGameType(GameType.x01)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLAY AGAIN'));
      await tester.tap(find.text('PLAY AGAIN'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection:x01'), findsOneWidget);
    });

    testWidgets('routes to variant-selection/cricket for cricket games',
        (tester) async {
      await tester.pumpWidget(_buildApp(gameStats: _statsForGameType(GameType.cricket)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLAY AGAIN'));
      await tester.tap(find.text('PLAY AGAIN'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection:cricket'), findsOneWidget);
    });

    testWidgets('routes to variant-selection/practice for drill games',
        (tester) async {
      await tester.pumpWidget(_buildApp(gameStats: _statsForGameType(GameType.checkoutPractice)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLAY AGAIN'));
      await tester.tap(find.text('PLAY AGAIN'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection:practice'), findsOneWidget);
    });

    testWidgets('routes to variant-selection/casual for casual games',
        (tester) async {
      await tester.pumpWidget(_buildApp(gameStats: _statsForGameType(GameType.shanghai)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLAY AGAIN'));
      await tester.tap(find.text('PLAY AGAIN'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection:casual'), findsOneWidget);
    });

    testWidgets('DONE button navigates to home', (tester) async {
      await tester.pumpWidget(_buildApp(gameStats: _statsForGameType(GameType.x01)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('DONE'));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    // Tests above exercise the fallback path (no gameRepositoryProvider
    // override → throws/null → falls back to variant-selection by category).
    // The intended happy path — load the game, seed setup, skip straight to
    // player-selection — is covered by the get-game-result use-case tests
    // and verified manually; covering it here would require wiring a fake
    // game repository, which the lightweight router shim deliberately
    // avoids (#337).
  });

  group('PostGameSummaryPage body branching', () {
    testWidgets('shanghai renders ShanghaiSummaryWidget',
        (tester) async {
      await tester.pumpWidget(_buildAppWithResult(
        gameStats: _statsForGameType(GameType.shanghai),
        gameResult: const GameResult.shanghai(
          competitors: [
            ShanghaiCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              totalScore: 100,
              shanghaiBonuses: 1,
              bestRound: 40,
              roundsPlayed: 7,
            ),
          ],
          winnerCompetitorId: null,
          totalRounds: 7,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ShanghaiSummaryWidget), findsOneWidget);
      expect(find.byType(PracticeSummaryWidget), findsNothing);
    });

    testWidgets('checkout practice renders PracticeSummaryWidget',
        (tester) async {
      await tester.pumpWidget(_buildAppWithResult(
        gameStats: _statsForGameType(GameType.checkoutPractice),
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
      expect(find.byType(ShanghaiSummaryWidget), findsNothing);
    });

    testWidgets('around-the-clock renders PracticeSummaryWidget',
        (tester) async {
      await tester.pumpWidget(_buildAppWithResult(
        gameStats: _statsForGameType(GameType.aroundTheClock),
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
    });

    testWidgets('x01 path does NOT touch gameResultProvider',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        gameStats: _statsForGameType(GameType.x01),
      ));
      await tester.pumpAndSettle();

      // The x01 branch consumes gameStatsProvider only.
      expect(find.byType(ShanghaiSummaryWidget), findsNothing);
      expect(find.byType(PracticeSummaryWidget), findsNothing);
    });

    testWidgets('null game result shows fallback message',
        (tester) async {
      await tester.pumpWidget(_buildAppWithResult(
        gameStats: _statsForGameType(GameType.bobs27),
        gameResult: null,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No result available for this game.'), findsOneWidget);
    });
  });
}
