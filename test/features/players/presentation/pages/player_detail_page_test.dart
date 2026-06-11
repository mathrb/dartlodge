import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/players/presentation/pages/player_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> _routes() => [
      GoRoute(
        path: GameRoutes.players,
        builder: (_, __) => const Scaffold(body: Text('players-list')),
      ),
      GoRoute(
        path: '/players/:playerId',
        builder: (_, s) =>
            PlayerDetailPage(playerId: s.pathParameters['playerId']!),
      ),
    ];

void main() {
  testWidgets(
      'Back from the error state falls back to the players list when the '
      'stack is not poppable (Sentry GoError "nothing to pop")',
      (tester) async {
    // PlayerDetailPage as the SOLE route — the deep-link / app-restoration
    // scenario where context.pop() has nothing to pop and used to throw.
    final router =
        GoRouter(initialLocation: '/players/p1', routes: _routes());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        playerProvider('p1')
            .overrideWith((ref) async => throw Exception('boom')),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load player'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Back'));
    await tester.pumpAndSettle();

    // No GoError thrown, and we land on the players list.
    expect(tester.takeException(), isNull);
    expect(find.text('players-list'), findsOneWidget);
  });

  testWidgets(
      'Back from the player-not-found state falls back to the players list '
      'when the stack is not poppable',
      (tester) async {
    final router =
        GoRouter(initialLocation: '/players/p1', routes: _routes());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        playerProvider('p1').overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Player not found'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Back'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('players-list'), findsOneWidget);
  });

  testWidgets('Back pops normally when the stack IS poppable', (tester) async {
    final router = GoRouter(initialLocation: '/players', routes: _routes());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        playerProvider('p1').overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    await tester.pumpAndSettle();

    // Push the detail page so the list stays underneath and is poppable.
    router.push('/players/p1');
    await tester.pumpAndSettle();
    expect(find.text('Player not found'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Back'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('players-list'), findsOneWidget);
  });
}
