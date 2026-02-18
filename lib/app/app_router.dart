// App Router Configuration
// Handles navigation between different screens using GoRouter

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/players/presentation/screens/players_screen.dart';
import '../features/game/presentation/screens/game_selection_screen.dart';
import '../features/statistics/presentation/screens/statistics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/players',
    routes: [
      GoRoute(
        path: '/players',
        name: 'players',
        builder: (context, state) => const PlayersScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'add_player',
            builder: (context, state) => const PlayersScreen(showAddDialog: true),
          ),
        ],
      ),
      GoRoute(
        path: '/games',
        name: 'games',
        builder: (context, state) => const GameSelectionScreen(),
        routes: [
          GoRoute(
            path: ':gameId',
            name: 'game_detail',
            builder: (context, state) {
              final gameId = state.uri.pathSegments.last;
              return GameSelectionScreen(gameId: gameId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});