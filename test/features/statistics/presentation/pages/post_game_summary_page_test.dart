import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/post_game_summary_page.dart';
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

    test('maps practice game types to practice category', () {
      for (final type in [
        GameType.countUp,
        GameType.aroundTheClock,
        GameType.catch40,
        GameType.bobs27,
        GameType.checkoutPractice,
        GameType.shanghai,
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

    testWidgets('routes to variant-selection/practice for practice games',
        (tester) async {
      await tester.pumpWidget(_buildApp(gameStats: _statsForGameType(GameType.checkoutPractice)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLAY AGAIN'));
      await tester.tap(find.text('PLAY AGAIN'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection:practice'), findsOneWidget);
    });

    testWidgets('DONE button navigates to home', (tester) async {
      await tester.pumpWidget(_buildApp(gameStats: _statsForGameType(GameType.x01)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('DONE'));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });
  });
}
