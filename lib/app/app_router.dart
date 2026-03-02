// App Router Configuration
// Handles navigation between different screens using GoRouter

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_darts/core/widgets/scaffold_with_nav_bar.dart';
import 'package:my_darts/features/game/presentation/pages/home_page.dart';
import 'package:my_darts/features/game/presentation/pages/player_selection_page.dart';
import 'package:my_darts/features/game/presentation/pages/variant_selection_page.dart';
import 'package:my_darts/features/history/presentation/pages/history_page.dart';
import 'package:my_darts/features/players/presentation/pages/create_player_page.dart';
import 'package:my_darts/features/players/presentation/pages/edit_player_page.dart';
import 'package:my_darts/features/players/presentation/pages/player_detail_page.dart';
import 'package:my_darts/features/players/presentation/pages/player_list_page.dart';
import 'package:my_darts/features/settings/presentation/pages/settings_page.dart';
import 'package:my_darts/features/statistics/presentation/pages/stats_tab_page.dart';
import 'package:my_darts/features/game/presentation/pages/cricket_board_page.dart';
import 'package:my_darts/features/game/presentation/pages/x01_board_page.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';

part 'app_router.g.dart';

// ── Route string constants ────────────────────────────────────────────────────

abstract final class GameRoutes {
  static const home             = '/';
  static const variantSelection = '/game/variant-selection';
  static const playerSelection  = '/game/player-selection';
  static const activeX01        = '/game/active/x01';
  static const activeCricket    = '/game/active/cricket';
  static const activePractice   = '/game/active/practice';
}

// ── Branch navigator keys ─────────────────────────────────────────────────────

final _homeKey     = GlobalKey<NavigatorState>(debugLabel: 'home');
final _historyKey  = GlobalKey<NavigatorState>(debugLabel: 'history');
final _statsKey    = GlobalKey<NavigatorState>(debugLabel: 'stats');
final _settingsKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

// ── RouterNotifier ────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class RouterNotifier extends _$RouterNotifier implements Listenable {
  final List<VoidCallback> _listeners = [];

  @override
  GoRouter build() {
    ref.listen<GameSetupState>(gameSetupProvider, (_, __) {
      for (final l in [..._listeners]) l();
    });
    return GoRouter(
      initialLocation: GameRoutes.home,
      refreshListenable: this,
      redirect: _redirect,
      routes: _buildRoutes(),
      errorBuilder: _errorPage,
    );
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    if (state.matchedLocation == GameRoutes.playerSelection) {
      final isSelectingType = ref.read(gameSetupProvider).maybeMap(
        selectingType: (_) => true,
        orElse: () => false,
      );
      if (isSelectingType) return GameRoutes.home;
    }
    return null;
  }

  @override
  void addListener(VoidCallback l) => _listeners.add(l);

  @override
  void removeListener(VoidCallback l) => _listeners.remove(l);
}

// ── Page builder functions ────────────────────────────────────────────────────

Widget _homePage(BuildContext _, GoRouterState __) => const HomePage();
Widget _historyPage(BuildContext _, GoRouterState __) => const HistoryPage();
Widget _statsPage(BuildContext _, GoRouterState __) => const StatsTabPage();
Widget _settingsPage(BuildContext _, GoRouterState __) => const SettingsPage();
Widget _playerListPage(BuildContext _, GoRouterState __) => const PlayerListPage();
Widget _createPlayerPage(BuildContext _, GoRouterState __) => const CreatePlayerPage();
Widget _playerDetailPage(BuildContext _, GoRouterState s) =>
    PlayerDetailPage(playerId: s.pathParameters['playerId']!);
Widget _editPlayerPage(BuildContext _, GoRouterState s) =>
    EditPlayerPage(playerId: s.pathParameters['playerId']!, currentName: s.extra as String? ?? '');
Widget _variantSelectionPage(BuildContext _, GoRouterState s) =>
    VariantSelectionPage(category: s.pathParameters['category']!);
Widget _playerSelectionPage(BuildContext _, GoRouterState __) => const PlayerSelectionPage();
Widget _x01BoardPage(BuildContext _, GoRouterState s) =>
    X01BoardPage(gameId: s.pathParameters['gameId']!);
Widget _cricketBoardPage(BuildContext _, GoRouterState s) =>
    CricketBoardPage(gameId: s.pathParameters['gameId']!);
Widget _practiceBoardPage(BuildContext _, GoRouterState __) => Scaffold(
    appBar: AppBar(title: const Text('Practice')),
    body: const Center(child: Text('Practice Board — coming in EPIC-007')));
Widget _errorPage(BuildContext _, GoRouterState s) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('Page not found: ${s.uri}')));

Widget _shellBuilder(
        BuildContext _, GoRouterState __, StatefulNavigationShell shell) =>
    ScaffoldWithNavBar(navigationShell: shell);

// ── Route tree ────────────────────────────────────────────────────────────────

List<RouteBase> _buildRoutes() => [
      StatefulShellRoute.indexedStack(
        builder: _shellBuilder,
        branches: [
          StatefulShellBranch(
              navigatorKey: _homeKey,
              routes: [GoRoute(path: GameRoutes.home, builder: _homePage)]),
          StatefulShellBranch(
              navigatorKey: _historyKey,
              routes: [GoRoute(path: '/history', builder: _historyPage)]),
          StatefulShellBranch(
              navigatorKey: _statsKey,
              routes: [GoRoute(path: '/stats', builder: _statsPage)]),
          StatefulShellBranch(
              navigatorKey: _settingsKey,
              routes: [GoRoute(path: '/settings', builder: _settingsPage)]),
        ],
      ),
      // EPIC-002 player routes — outside shell
      GoRoute(
        path: '/players',
        builder: _playerListPage,
        routes: [
          GoRoute(path: 'add', builder: _createPlayerPage),
          GoRoute(
            path: ':playerId',
            builder: _playerDetailPage,
            routes: [GoRoute(path: 'edit', builder: _editPlayerPage)],
          ),
        ],
      ),
      // EPIC-004 game setup routes — outside shell
      GoRoute(
          path: '${GameRoutes.variantSelection}/:category',
          builder: _variantSelectionPage),
      GoRoute(path: GameRoutes.playerSelection, builder: _playerSelectionPage),
      // Active game board stubs — outside shell
      GoRoute(
          path: '${GameRoutes.activeX01}/:gameId', builder: _x01BoardPage),
      GoRoute(
          path: '${GameRoutes.activeCricket}/:gameId',
          builder: _cricketBoardPage),
      GoRoute(
          path: '${GameRoutes.activePractice}/:gameId',
          builder: _practiceBoardPage),
    ];
