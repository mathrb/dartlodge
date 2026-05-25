// App Router Configuration
// Handles navigation between different screens using GoRouter

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dart_lodge/features/game/presentation/pages/home_page.dart';
import 'package:dart_lodge/features/game/presentation/pages/player_selection_page.dart';
import 'package:dart_lodge/features/game/presentation/pages/variant_selection_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_cricket_game_provider.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_game_provider.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_practice_provider.dart';
import 'package:dart_lodge/features/game/presentation/widgets/end_game_dialog_widget.dart';
import 'package:dart_lodge/features/history/presentation/pages/history_page.dart';
import 'package:dart_lodge/features/players/presentation/pages/create_player_page.dart';
import 'package:dart_lodge/features/players/presentation/pages/edit_player_page.dart';
import 'package:dart_lodge/features/players/presentation/pages/player_detail_page.dart';
import 'package:dart_lodge/features/players/presentation/pages/player_list_page.dart';
import 'package:dart_lodge/features/settings/presentation/pages/settings_page.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/stats_tab_page.dart';
import 'package:dart_lodge/features/game/presentation/pages/count_up_board_page.dart';
import 'package:dart_lodge/features/game/presentation/pages/cricket_board_page.dart';
import 'package:dart_lodge/features/game/presentation/pages/practice_board_page.dart';
import 'package:dart_lodge/features/game/presentation/pages/x01_board_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/game_setup_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/game_setup_state.dart';
import 'package:dart_lodge/features/history/presentation/pages/game_detail_page.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/player_stats_page.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/post_game_summary_page.dart';

part 'app_router.g.dart';

// ── Route string constants ────────────────────────────────────────────────────

abstract final class GameRoutes {
  static const home             = '/';
  static const history          = '/history';
  static const stats            = '/stats';
  static const settings         = '/settings';
  static const players          = '/players';
  static const variantSelection = '/game/variant-selection';
  static const playerSelection  = '/game/player-selection';
  static const activeX01        = '/game/active/x01';
  static const activeCricket    = '/game/active/cricket';
  static const activePractice   = '/practice-board';
  static const activeCountUp    = '/game/active/count-up';

  static String gameDetail(String id) => '/game/history/$id';
  static String playerStats(String id) => '/stats/player/$id';
  static String postGame(String id) => '/post-game/$id';
}

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
Widget _practiceBoardPage(BuildContext _, GoRouterState s) =>
    PracticeBoardPage(gameId: s.pathParameters['gameId']!);
Widget _countUpBoardPage(BuildContext _, GoRouterState s) =>
    CountUpBoardPage(gameId: s.pathParameters['gameId']!);
Widget _playerStatsPage(BuildContext _, GoRouterState s) =>
    PlayerStatsPage(playerId: s.pathParameters['playerId']!);
Widget _postGameSummaryPage(BuildContext _, GoRouterState s) =>
    PostGameSummaryPage(gameId: s.pathParameters['gameId']!);
Widget _gameDetailPage(BuildContext _, GoRouterState s) =>
    GameDetailPage(gameId: s.pathParameters['gameId']!);
Widget _errorPage(BuildContext _, GoRouterState s) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('Page not found: ${s.uri}')));

// ── onExit handlers (browser-back / route-exit confirmation, #319) ───────────
//
// `GoRoute.onExit` runs for ALL exit paths — in-app `context.go`, browser
// back/forward, and OS gesture — so it catches the case `PopScope` couldn't
// on Flutter Web (browser back didn't reach `onPopInvokedWithResult` because
// the URL had already changed). Each handler:
//   1. Short-circuits when the game is already complete (natural finish or
//      explicit "End Game" already ran the endGame use case), so post-game
//      navigation isn't gated behind a confirmation dialog.
//   2. Otherwise shows the End Game dialog. If the user confirms, marks the
//      game abandoned via the matching notifier so stats projections see
//      the clean game-boundary reset (#280 / #252) and returns true.
//   3. On cancel, returns false to keep the user on the active board.

Future<bool> _confirmActiveExit({
  required BuildContext context,
  required bool isComplete,
  required Future<void> Function() endGame,
}) async {
  if (isComplete) return true;
  final completer = Completer<bool>();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => EndGameDialogWidget(
      onConfirm: () async {
        Navigator.of(dialogContext).pop();
        await endGame();
        if (!completer.isCompleted) completer.complete(true);
      },
      onCancel: () {
        Navigator.of(dialogContext).pop();
        if (!completer.isCompleted) completer.complete(false);
      },
    ),
  );
  // `showDialog` resolves on dialog pop. If the user dismisses the dialog by
  // some other means (e.g. tap-outside on a future change), treat it as
  // cancel so the player stays on the board.
  if (!completer.isCompleted) completer.complete(false);
  return completer.future;
}

FutureOr<bool> _activeX01Exit(BuildContext context, GoRouterState state) {
  final container = ProviderScope.containerOf(context, listen: false);
  final gameId = state.pathParameters['gameId']!;
  final s = container.read(activeGameProvider(gameId));
  final isComplete = s.value?.gameState.isComplete ?? false;
  return _confirmActiveExit(
    context: context,
    isComplete: isComplete,
    endGame: () =>
        container.read(activeGameProvider(gameId).notifier).endGame(),
  );
}

FutureOr<bool> _activeCricketExit(BuildContext context, GoRouterState state) {
  final container = ProviderScope.containerOf(context, listen: false);
  final gameId = state.pathParameters['gameId']!;
  final s = container.read(activeCricketGameProvider(gameId));
  final isComplete = s.value?.gameState.isComplete ?? false;
  return _confirmActiveExit(
    context: context,
    isComplete: isComplete,
    endGame: () =>
        container.read(activeCricketGameProvider(gameId).notifier).endGame(),
  );
}

FutureOr<bool> _activePracticeExit(BuildContext context, GoRouterState state) {
  final container = ProviderScope.containerOf(context, listen: false);
  final gameId = state.pathParameters['gameId']!;
  final s = container.read(activePracticeProvider(gameId));
  final isComplete = s.value?.gameState.isComplete ?? false;
  return _confirmActiveExit(
    context: context,
    isComplete: isComplete,
    endGame: () =>
        container.read(activePracticeProvider(gameId).notifier).endDrill(),
  );
}

// ── Route tree ────────────────────────────────────────────────────────────────

List<RouteBase> _buildRoutes() => [
      // Top-level flat routes — no persistent shell / bottom nav
      GoRoute(path: GameRoutes.home,     builder: _homePage),
      GoRoute(path: GameRoutes.history,  builder: _historyPage),
      GoRoute(path: GameRoutes.stats,    builder: _statsPage),
      GoRoute(path: GameRoutes.settings, builder: _settingsPage),
      // EPIC-002 player routes
      GoRoute(
        path: GameRoutes.players,
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
      // EPIC-004 game setup routes
      GoRoute(
          path: '${GameRoutes.variantSelection}/:category',
          builder: _variantSelectionPage),
      GoRoute(path: GameRoutes.playerSelection, builder: _playerSelectionPage),
      // Active game board routes. `onExit` confirms before leaving an
      // in-progress game so browser back / OS gesture can't silently abandon
      // it (#319). PopScope on the page itself handles the in-app back arrow
      // and the legacy Android system gesture; onExit also catches both, so
      // some boards now show the dialog twice — todo: collapse the two paths
      // in a follow-up. For now the second dialog short-circuits via
      // isComplete because the first confirmation already ran endGame().
      GoRoute(
          path: '${GameRoutes.activeX01}/:gameId',
          builder: _x01BoardPage,
          onExit: _activeX01Exit),
      GoRoute(
          path: '${GameRoutes.activeCricket}/:gameId',
          builder: _cricketBoardPage,
          onExit: _activeCricketExit),
      GoRoute(
          path: '${GameRoutes.activePractice}/:gameId',
          builder: _practiceBoardPage,
          onExit: _activePracticeExit),
      GoRoute(
          path: '${GameRoutes.activeCountUp}/:gameId',
          builder: _countUpBoardPage),
      GoRoute(
          path: '/stats/player/:playerId',
          builder: _playerStatsPage),
      GoRoute(
          path: '/post-game/:gameId',
          builder: _postGameSummaryPage),
      GoRoute(
          path: '/game/history/:gameId',
          builder: _gameDetailPage),
    ];
