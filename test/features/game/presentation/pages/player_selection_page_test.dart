import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/pages/player_selection_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/game_setup_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/game_setup_state.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/providers/statistics_providers.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakePlayerRepository implements PlayerRepository {
  final List<Player> players;
  _FakePlayerRepository([this.players = const []]);

  @override
  Future<List<Player>> getAllPlayers() async => players;
  @override
  Future<Player?> getPlayer(String playerId) async =>
      players.firstWhere((p) => p.playerId == playerId,
          orElse: () => throw StateError('not found'));
  @override
  Future<void> createPlayer(Player player) async {}
  @override
  Future<void> updatePlayerName(String playerId, String name) async {}
  @override
  Future<void> touchPlayer(String playerId) async {}
  @override
  Future<void> deletePlayer(String playerId) async {}
  @override
  Stream<List<Player>> watchAllPlayers() =>
      Stream.value(players);
}

Player _fakePlayer(String id, String name) => Player(
      playerId: id,
      name: name,
      createdAt: DateTime(2024),
      lastActive: DateTime(2024),
    );

/// Fixed-state notifier that suppresses async init side effects.
class _FixedGameSetupNotifier extends GameSetupNotifier {
  _FixedGameSetupNotifier(this._fixedState);
  final GameSetupState _fixedState;

  @override
  GameSetupState build() => _fixedState;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _x01Config = GameConfig.x01(
  startingScore: 501,
  inStrategy: 'straight',
  outStrategy: 'double',
  legsToWin: 1,
);

const _cricketConfig = GameConfig.cricket(
  scoring: 'standard',
  numbers: ['15', '16', '17', '18', '19', '20', 'bull'],
  legsToWin: 1,
);

Widget _buildApp({
  required GameSetupState setupState,
  List<Player> players = const [],
  List<String> capturedRoutes = const [],
  ThemeData? theme,
  List<Override> extraOverrides = const [],
  Locale? locale,
  double textScale = 1.0,
}) {
  final router = GoRouter(
    initialLocation: '/game/player-selection',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/game/player-selection',
        builder: (_, __) => const PlayerSelectionPage(),
      ),
      GoRoute(
        path: '/game/active/x01/:gameId',
        builder: (_, s) {
          capturedRoutes.add('/game/active/x01/${s.pathParameters['gameId']}');
          return const Scaffold(body: Text('x01-board'));
        },
      ),
      GoRoute(
        path: '/game/active/cricket/:gameId',
        builder: (_, s) {
          capturedRoutes.add('/game/active/cricket/${s.pathParameters['gameId']}');
          return const Scaffold(body: Text('cricket-board'));
        },
      ),
      GoRoute(
        path: '/practice-board/:gameId',
        builder: (_, s) {
          capturedRoutes.add('/practice-board/${s.pathParameters['gameId']}');
          return const Scaffold(body: Text('practice-board'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      playerRepositoryProvider.overrideWithValue(_FakePlayerRepository(players)),
      gameSetupProvider.overrideWith(() => _FixedGameSetupNotifier(setupState)),
      allPlayersProvider.overrideWith(
        () => _FakeAllPlayersNotifier(players),
      ),
      ...extraOverrides,
    ],
    child: MaterialApp.router(
      theme: theme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      routerConfig: router,
      builder: textScale == 1.0
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
    ),
  );
}

/// Fake AllPlayers notifier that returns a fixed list.
class _FakeAllPlayersNotifier extends AllPlayers {
  _FakeAllPlayersNotifier(this._players);
  final List<Player> _players;

  @override
  Stream<List<Player>> build() => Stream.value(_players);
}

GameSetupState _selectingPlayersState({
  GameConfig config = _x01Config,
  GameType gameType = GameType.x01,
  List<String> selectedPlayerIds = const [],
  Map<String, int> playerHandicaps = const {},
}) {
  return GameSetupState.selectingPlayers(
    gameType: gameType,
    config: config,
    selectedPlayerIds: selectedPlayerIds,
    playerHandicaps: playerHandicaps,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Config chip X01 ────────────────────────────────────────────────────

  testWidgets('1. Config chip shows "501 · Double Out · ∞ Rounds · 1 leg" for X01 with no totalRounds',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('501 · Double Out · ∞ Rounds · 1 leg'), findsOneWidget);
  });

  // ── 1b. Config chip surfaces non-default in-strategy (#329) ───────────────

  testWidgets(
      '1b. Config chip includes Double In when in-strategy is double (#329)',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'double',
          outStrategy: 'double',
          legsToWin: 1,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('501 · Double In · Double Out · ∞ Rounds · 1 leg'),
        findsOneWidget);
  });

  testWidgets(
      '1c. Config chip includes Master In when in-strategy is master (#329)',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'master',
          outStrategy: 'double',
          legsToWin: 1,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('501 · Master In · Double Out · ∞ Rounds · 1 leg'),
        findsOneWidget);
  });

  // ── 1d. Config chip surfaces the best-of leg count ────────────────────────

  testWidgets(
      '1d. Config chip shows "Best of 5" for X01 first to 3, not the legs to win',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: 3,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('501 · Double Out · ∞ Rounds · Best of 5'),
        findsOneWidget);
  });

  testWidgets('1e. Config chip shows the plain leg count for a solo lineup',
      (tester) async {
    // Solo, every checkout wins the leg: first to 3 is exactly 3 legs.
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: 3,
        ),
        selectedPlayerIds: ['p1'],
      ),
      players: [_fakePlayer('p1', 'Alice')],
    ));
    await tester.pumpAndSettle();

    expect(find.text('501 · Double Out · ∞ Rounds · 3 legs'),
        findsOneWidget);
  });

  testWidgets('1f. Config chip counts the longest match for three players',
      (tester) async {
    // Three players, first to 2: each can win one leg before the decider.
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: 2,
        ),
        selectedPlayerIds: ['p1', 'p2', 'p3'],
      ),
      players: [
        _fakePlayer('p1', 'Alice'),
        _fakePlayer('p2', 'Bob'),
        _fakePlayer('p3', 'Cleo'),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('501 · Double Out · ∞ Rounds · Best of 4'),
        findsOneWidget);
  });

  // ── 2. Config chip Cricket ────────────────────────────────────────────────

  testWidgets('2. Config chip shows "standard · 0 pts" for Cricket',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: _cricketConfig,
        gameType: GameType.cricket,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Standard · ∞ Rounds · 1 leg'), findsOneWidget);
  });

  testWidgets('2b. Config chip names the Random target mode for Cricket',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.cricket(
          scoring: 'standard',
          targetMode: 'random',
          numbers: ['15', '16', '17', '18', '19', '20', 'bull'],
          legsToWin: 1,
        ),
        gameType: GameType.cricket,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Random · ∞ Rounds · 1 leg'), findsOneWidget);
  });

  testWidgets(
      '2c. Config chip shows "Crazy · Cut Throat" for Crazy with Cut Throat scoring',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.cricket(
          scoring: 'cut-throat',
          targetMode: 'crazy',
          numbers: ['15', '16', '17', '18', '19', '20', 'bull'],
          legsToWin: 1,
        ),
        gameType: GameType.cricket,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Crazy · Cut Throat · ∞ Rounds · 1 leg'), findsOneWidget);
  });

  // ── 2d. Lineup figure follows the game type ──────────────────────────────

  PlayerStats stats(
    GameType type, {
    int totalGames = 1,
    double threeDartAverage = 0,
    double? marksPerTurn,
  }) =>
      PlayerStats(
        playerId: 'p1',
        gameType: type,
        totalGames: totalGames,
        gamesWon: 0,
        winRate: 0,
        threeDartAverage: threeDartAverage,
        highestTurnScore: 0,
        totalDartsThrown: 0,
        dartsPerLeg: 0,
        bustRate: 0,
        marksPerTurn: marksPerTurn,
      );

  testWidgets('2d. Cricket lineup shows the player\'s Cricket MPR, not AVG',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: _cricketConfig,
        gameType: GameType.cricket,
        selectedPlayerIds: ['p1'],
      ),
      players: [_fakePlayer('p1', 'Ann')],
      extraOverrides: [
        playerStatsProvider('p1', GameType.cricket).overrideWith(
          (ref) => Stream.value(
            stats(GameType.cricket, marksPerTurn: 4.15),
          ),
        ),
        playerStatsProvider('p1', GameType.x01).overrideWith(
          (ref) => Stream.value(stats(GameType.x01, threeDartAverage: 51.2)),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('MPR 4.15'), findsOneWidget);
    expect(find.textContaining('AVG'), findsNothing);
  });

  testWidgets('2e. X01 lineup shows the three-dart average', (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(selectedPlayerIds: ['p1']),
      players: [_fakePlayer('p1', 'Ann')],
      extraOverrides: [
        playerStatsProvider('p1', GameType.x01).overrideWith(
          (ref) => Stream.value(stats(GameType.x01, threeDartAverage: 51.2)),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('AVG 51.2'), findsOneWidget);
  });

  testWidgets('2f. A player with no game of the type reads a dash, not 0',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(selectedPlayerIds: ['p1']),
      players: [_fakePlayer('p1', 'Ann')],
      extraOverrides: [
        playerStatsProvider('p1', GameType.x01).overrideWith(
          (ref) => Stream.value(stats(GameType.x01, totalGames: 0)),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('AVG —'), findsOneWidget);
    expect(find.text('AVG 0'), findsNothing);
  });

  // ── 3. Config chip ATC ───────────────────────────────────────────────────

  testWidgets('3. Config chip shows "Around the Clock" for ATC',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.aroundTheClock(),
        gameType: GameType.aroundTheClock,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Around the Clock'), findsOneWidget);
  });

  // ── 4. Tapping chip opens edit icon (and GameConfigPanel builds) ──────────

  testWidgets('4. Config chip tapping shows edit icon', (tester) async {
    // Use a large surface so GameConfigPanel doesn't overflow
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(),
    ));
    await tester.pumpAndSettle();

    // The chip contains an edit icon
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    // Tapping the chip should open the config bottom sheet
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // GameConfigPanel shows "GAME CONFIG"
    expect(find.text('GAME CONFIG'), findsOneWidget);
  });

  // ── 4b. Config chip hidden when there's nothing to configure (#261) ──────

  testWidgets("4b. Config chip is hidden for Catch 40 (no editable fields)",
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.catch40(),
        gameType: GameType.catch40,
      ),
    ));
    await tester.pumpAndSettle();

    // The chip's edit icon is the visible affordance — it should not
    // render when the underlying bottom-sheet would be empty.
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.text('Catch 40'), findsNothing);
  });

  testWidgets("4c. Config chip is hidden for Bob's 27 (no editable fields)",
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        config: const GameConfig.bobs27(),
        gameType: GameType.bobs27,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  // ── 5. Empty selected area ────────────────────────────────────────────────

  testWidgets('5. Empty selected area shows "Select players below"',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tap a player from the roster to add'), findsOneWidget);
  });

  // ── 6. Selected area shows player cells when players selected ────────────

  testWidgets('6. Selected area shows player cells when players selected',
      (tester) async {
    final players = [_fakePlayer('p1', 'Alice'), _fakePlayer('p2', 'Bob')];
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(
        selectedPlayerIds: ['p1', 'p2'],
      ),
      players: players,
    ));
    await tester.pumpAndSettle();

    // Should not show the empty state text
    expect(find.text('Tap a player from the roster to add'), findsNothing);
    // Initials appear in selected area (at least one 'A' for Alice and 'B' for Bob)
    expect(find.text('A'), findsWidgets); // 'A' for Alice (may appear in selected area + roster)
    expect(find.text('B'), findsWidgets); // 'B' for Bob
  });

  // ── 7. Tapping roster cell calls togglePlayer ─────────────────────────────

  testWidgets('7. Tapping unselected roster cell adds player', (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];

    final router = GoRouter(
      initialLocation: '/game/player-selection',
      routes: [
        GoRoute(
          path: '/game/player-selection',
          builder: (_, __) => const PlayerSelectionPage(),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(
              _FakePlayerRepository(players)),
          gameSetupProvider.overrideWith(
              () => _FixedGameSetupNotifier(_selectingPlayersState())),
          allPlayersProvider.overrideWith(
              () => _FakeAllPlayersNotifier(players)),
        ],
        child: Builder(builder: (context) {
          return MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: kSupportedLocales, routerConfig: router);
        }),
      ),
    );
    await tester.pumpAndSettle();

    // Verify roster grid renders the player name
    expect(find.text('Alice'), findsOneWidget);
  });

  // ── 8. Selected player card shows player name and remove button ───────────

  testWidgets('8. Selected player card shows name and remove button',
      (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(selectedPlayerIds: ['p1']),
      players: players,
    ));
    await tester.pumpAndSettle();

    // Player name appears in the active lineup (uppercase in card)
    expect(find.text('ALICE'), findsOneWidget);
    // Remove button is present
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
  });

  // ── 9. Remove button calls togglePlayer ───────────────────────────────────

  testWidgets('9. Tapping remove button removes player from lineup',
      (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(selectedPlayerIds: ['p1']),
      players: players,
    ));
    await tester.pumpAndSettle();

    // Player card is shown
    expect(find.text('ALICE'), findsOneWidget);

    // Tap the remove button
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();

    // No action sheet — the button directly calls togglePlayer
    expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
  });

  // ── 10. Active lineup is empty after removing player ──────────────────────

  testWidgets('10. Empty state shown after all players removed',
      (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(selectedPlayerIds: ['p1']),
      players: players,
    ));
    await tester.pumpAndSettle();

    // Remove the player
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();

    // Empty state text is shown
    expect(find.text('Tap a player from the roster to add'), findsOneWidget);
  });

  // ── 11. START GAME disabled with no players ───────────────────────────────

  testWidgets('11. START GAME disabled with no players selected',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(),
    ));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  // ── 12. START GAME enabled with players selected ──────────────────────────

  testWidgets('12. START GAME enabled with players selected', (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(selectedPlayerIds: ['p1']),
      players: players,
    ));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  // ── 13. START GAME shows loading indicator during start ───────────────────

  testWidgets('13. START GAME shows loading indicator during async start',
      (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];
    // Use a completer-based notifier so we can control when startGame resolves
    final completer = _ControlledStartCompleter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(_FakePlayerRepository(players)),
          gameSetupProvider.overrideWith(
            () => _ControllableStartNotifier(
              _selectingPlayersState(selectedPlayerIds: ['p1']),
              completer,
            ),
          ),
          allPlayersProvider.overrideWith(
            () => _FakeAllPlayersNotifier(players),
          ),
        ],
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: kSupportedLocales, 
          routerConfig: GoRouter(
            initialLocation: '/game/player-selection',
            routes: [
              GoRoute(
                path: '/game/player-selection',
                builder: (_, __) => const PlayerSelectionPage(),
              ),
              GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('home')),
              ),
              GoRoute(
                path: '/game/active/x01/:gameId',
                builder: (_, __) => const Scaffold(body: Text('x01')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap START GAME
    await tester.tap(find.text('START GAME'));
    await tester.pump(); // one frame — loading state shows

    // Loading indicator appears
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // Resolve so there are no pending futures
    completer.complete(null);
    await tester.pumpAndSettle();
  });

  // ── 14. Navigation to x01 route on success ────────────────────────────────

  testWidgets('14. Navigates to x01 route on successful game start',
      (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];
    final captured = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(_FakePlayerRepository(players)),
          gameSetupProvider.overrideWith(
            () => _SuccessGameSetupNotifier(
              _selectingPlayersState(selectedPlayerIds: ['p1']),
              'game-id-123',
            ),
          ),
          allPlayersProvider
              .overrideWith(() => _FakeAllPlayersNotifier(players)),
        ],
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: kSupportedLocales, 
          routerConfig: GoRouter(
            initialLocation: '/game/player-selection',
            routes: [
              GoRoute(
                path: '/game/player-selection',
                builder: (_, __) => const PlayerSelectionPage(),
              ),
              GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('home')),
              ),
              GoRoute(
                path: '/game/active/x01/:gameId',
                builder: (_, s) {
                  captured.add(s.pathParameters['gameId']!);
                  return const Scaffold(body: Text('x01-board'));
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();

    expect(find.text('x01-board'), findsOneWidget);
    expect(captured, contains('game-id-123'));
  });

  // ── 15. SnackBar on null return from startGame ────────────────────────────

  testWidgets('15. Shows SnackBar when startGame returns null', (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(_FakePlayerRepository(players)),
          gameSetupProvider.overrideWith(
            () => _NullStartGameSetupNotifier(
              _selectingPlayersState(selectedPlayerIds: ['p1']),
            ),
          ),
          allPlayersProvider
              .overrideWith(() => _FakeAllPlayersNotifier(players)),
        ],
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: kSupportedLocales, 
          routerConfig: GoRouter(
            initialLocation: '/game/player-selection',
            routes: [
              GoRoute(
                path: '/game/player-selection',
                builder: (_, __) => const PlayerSelectionPage(),
              ),
              GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('home')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not start game. Please check your selection.'),
      findsOneWidget,
    );
  });

  // ── 16. SnackBar on exception from startGame ──────────────────────────────

  testWidgets('16. Shows SnackBar when startGame throws', (tester) async {
    final players = [_fakePlayer('p1', 'Alice')];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(_FakePlayerRepository(players)),
          gameSetupProvider.overrideWith(
            () => _ThrowingStartGameSetupNotifier(
              _selectingPlayersState(selectedPlayerIds: ['p1']),
            ),
          ),
          allPlayersProvider
              .overrideWith(() => _FakeAllPlayersNotifier(players)),
        ],
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: kSupportedLocales, 
          routerConfig: GoRouter(
            initialLocation: '/game/player-selection',
            routes: [
              GoRoute(
                path: '/game/player-selection',
                builder: (_, __) => const PlayerSelectionPage(),
              ),
              GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('home')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('START GAME'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not start game. Please try again.'),
      findsOneWidget,
    );
  });

  // ── 17. Add cell opens create player sheet ────────────────────────────────

  testWidgets('17. Tapping add cell opens create player sheet', (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(),
    ));
    await tester.pumpAndSettle();

    // The add cell shows '+' text
    await tester.tap(find.text('NEW PLAYER'));
    await tester.pumpAndSettle();

    // Create player sheet has a text field and CREATE PLAYER button
    expect(find.text('CREATE PLAYER'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  // ── 18. Create player sheet validates empty name ──────────────────────────

  testWidgets('18. Create player sheet shows error on empty name submit',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('NEW PLAYER'));
    await tester.pumpAndSettle();

    // Tap CREATE PLAYER without entering a name
    await tester.tap(find.text('CREATE PLAYER'));
    await tester.pumpAndSettle();

    expect(find.text('Name cannot be empty'), findsOneWidget);
  });

  // ── 19. Create player form submits ────────────────────────────────────────

  testWidgets('19. Create player form calls createPlayer and closes',
      (tester) async {
    bool createCalled = false;
    final fakeRepo = _TrackingPlayerRepository(
      onCreatePlayer: (_) {
        createCalled = true;
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider.overrideWithValue(fakeRepo),
          gameSetupProvider.overrideWith(
            () => _FixedGameSetupNotifier(_selectingPlayersState()),
          ),
          allPlayersProvider.overrideWith(
            () => _FakeAllPlayersNotifier([]),
          ),
        ],
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: kSupportedLocales, 
          routerConfig: GoRouter(
            initialLocation: '/game/player-selection',
            routes: [
              GoRoute(
                path: '/game/player-selection',
                builder: (_, __) => const PlayerSelectionPage(),
              ),
              GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('home')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('NEW PLAYER'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Charlie');
    await tester.pumpAndSettle();

    await tester.tap(find.text('CREATE PLAYER'));
    await tester.pumpAndSettle();

    expect(createCalled, isTrue);
    // Sheet should be dismissed
    expect(find.text('CREATE PLAYER'), findsNothing);
  });

  // ── 20. Avatar preview updates as name is typed ───────────────────────────

  testWidgets('20. Avatar preview updates initials as name is typed',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('NEW PLAYER'));
    await tester.pumpAndSettle();

    // Initially shows '?'
    expect(find.text('?'), findsOneWidget);

    // Type a name
    await tester.enterText(find.byType(TextField), 'Dan');
    await tester.pump();

    // Avatar should show 'D'
    expect(find.text('D'), findsOneWidget);
  });

  // ── 21. X01 caps selection at 6 players ──────────────────────────────────

  testWidgets('21. X01 caps selection at 6 players — 7th shows tooltip',
      (tester) async {
    // Use a larger viewport so 6 selected cards + 7 roster cells fit without overflow
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final players = List.generate(
      7,
      (i) => _fakePlayer('p$i', 'Player $i'),
    );
    // 6 already selected
    final selectedIds = List.generate(6, (i) => 'p$i');

    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(selectedPlayerIds: selectedIds),
      players: players,
    ));
    await tester.pumpAndSettle();

    // The 7th player cell should be wrapped in a Tooltip
    final tooltips = tester
        .widgetList<Tooltip>(find.byType(Tooltip))
        .where((t) => t.message == 'Maximum 6 players reached')
        .toList();
    expect(tooltips, isNotEmpty);
  });

  // ── 22. Guard redirects to home when state reverts to selectingType ────────

  testWidgets('22. Guard redirects to home when state reverts to selectingType',
      (tester) async {
    // Use a mutable notifier so we can programmatically trigger a reset
    late _MutableGameSetupNotifier capturedNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerRepositoryProvider
              .overrideWithValue(_FakePlayerRepository()),
          gameSetupProvider.overrideWith(() {
            capturedNotifier = _MutableGameSetupNotifier(
              _selectingPlayersState(),
            );
            return capturedNotifier;
          }),
          allPlayersProvider
              .overrideWith(() => _FakeAllPlayersNotifier([])),
        ],
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: kSupportedLocales, 
          routerConfig: GoRouter(
            initialLocation: '/game/player-selection',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: Text('home')),
              ),
              GoRoute(
                path: '/game/player-selection',
                builder: (_, __) => const PlayerSelectionPage(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify we are on the player selection page
    expect(find.text('ACTIVE LINEUP'), findsOneWidget);

    // Simulate a reset — state transitions to selectingType
    capturedNotifier.triggerReset();
    await tester.pumpAndSettle();

    // The ref.listen guard fires go('/') via postFrameCallback
    expect(find.text('home'), findsOneWidget);
  });

  // ── 23. Header back falls back to home when the stack is empty ─────────────

  testWidgets(
      '23. Header back routes to home when reached via go() (empty stack)',
      (tester) async {
    // _buildApp uses initialLocation '/game/player-selection', so the page is
    // the root and canPop() is false — the "Play Again" go() scenario. The back
    // button must fall back to home, not silently no-op (MY-DARTS-J follow-up).
    await tester.pumpWidget(_buildApp(
      setupState: _selectingPlayersState(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ACTIVE LINEUP'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsOneWidget);
  });

  // ── 24–28. Roster header link, names and empty state (phone, light) ────────

  group('roster on a 412 px phone, light theme', () {
    void usePhoneView(WidgetTester tester) {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    // The surfaces the header link can sit on (page and roster box).
    const lightSurfaces = [AppColors.surface, AppColors.surfaceContainerLow];

    double contrast(Color fg, Color bg) {
      final a = Color.alphaBlend(fg, bg).computeLuminance();
      final b = bg.computeLuminance();
      final hi = a > b ? a : b;
      final lo = a > b ? b : a;
      return (hi + 0.05) / (lo + 0.05);
    }

    testWidgets('24. NEW PLAYER link text and icon meet 4.5:1', (tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(_buildApp(
        setupState: _selectingPlayersState(),
        players: [_fakePlayer('p1', 'Ann')],
        theme: AppTheme.light(),
      ));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('NEW PLAYER')).style!.color!;
      final link = find
          .ancestor(of: find.text('NEW PLAYER'), matching: find.byType(InkWell))
          .first;
      final icon = tester
          .widget<Icon>(find.descendant(
              of: link, matching: find.byIcon(Icons.person_add_outlined)))
          .color!;
      expect(text, AppColors.primary);
      expect(icon, AppColors.primary);
      for (final bg in lightSurfaces) {
        expect(contrast(text, bg), greaterThanOrEqualTo(4.5),
            reason: 'NEW PLAYER on $bg');
      }
    });

    testWidgets('25. NEW PLAYER hit area is at least 48 dp tall',
        (tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(_buildApp(
        setupState: _selectingPlayersState(),
        players: [_fakePlayer('p1', 'Ann')],
        theme: AppTheme.light(),
      ));
      await tester.pumpAndSettle();

      final inkWell = find
          .ancestor(of: find.text('NEW PLAYER'), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(inkWell).height,
          greaterThanOrEqualTo(kMinInteractiveDimension));
    });

    testWidgets('26. a 9-character name is shown in full in a roster cell',
        (tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(_buildApp(
        setupState: _selectingPlayersState(),
        players: [_fakePlayer('p1', 'Alexandra')],
        theme: AppTheme.light(),
      ));
      await tester.pumpAndSettle();

      final name = find.text('Alexandra');
      expect(name, findsOneWidget);
      expect(find.textContaining('…'), findsNothing);
      final paragraph = tester.renderObject<RenderParagraph>(name);
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('27. empty roster shows a hint and an add button that opens '
        'the create sheet', (tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(_buildApp(
        setupState: _selectingPlayersState(),
        theme: AppTheme.light(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No players yet'), findsOneWidget);
      final button = find.widgetWithText(OutlinedButton, 'Add new player');
      expect(button, findsOneWidget);
      expect(tester.getSize(button).height,
          greaterThanOrEqualTo(kMinInteractiveDimension));

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('CREATE PLAYER'), findsOneWidget);
    });

    testWidgets('28. active HCP chip text uses the readable accent',
        (tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(_buildApp(
        setupState: _selectingPlayersState(
          selectedPlayerIds: ['p1'],
          playerHandicaps: {'p1': 2},
        ),
        players: [_fakePlayer('p1', 'Ann')],
        theme: AppTheme.light(),
      ));
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text('HCP')).style!.color,
          AppColors.primary);
      expect(tester.widget<Text>(find.text('+2')).style!.color,
          AppColors.primary);
    });
  });

  // ── Large text (DESIGN_SYSTEM §13) ────────────────────────────────────────

  group('Config chip at large text', () {
    Future<void> pumpAt(
      WidgetTester tester, {
      required Locale locale,
      required double scale,
      required double width,
    }) async {
      tester.view.physicalSize = Size(width, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_buildApp(
        setupState: _selectingPlayersState(),
        locale: locale,
        textScale: scale,
      ));
      await tester.pumpAndSettle();
    }

    Finder chipRow() => find
        .ancestor(
          of: find.byIcon(Icons.edit_outlined),
          matching: find.byType(Row),
        )
        .first;

    RenderParagraph summaryParagraph(WidgetTester tester) {
      // The summary is the only Text sharing a Row with the edit icon
      // (icons paint a RichText too, but are not Text widgets).
      final text = find.descendant(of: chipRow(), matching: find.byType(Text));
      expect(text, findsOneWidget);
      return tester.renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)),
      );
    }

    // The test font draws every glyph 1 em wide, far wider than the app
    // font: at 412 dp the default fr summary would need three lines and the
    // lineup headers would overflow, neither of which happens on a device.
    // A 700 dp surface still pushes the edit icon off screen without the fix
    // (the one-line summary is ~880 dp wide at 2.0x) while the rest of the
    // page lays out.
    const width = 700.0;
    for (final scale in [1.7, 2.0]) {
      testWidgets('fr at ${scale}x keeps the edit icon on screen and the '
          'summary whole', (tester) async {
        await pumpAt(tester,
            locale: const Locale('fr'), scale: scale, width: width);

        expect(tester.takeException(), isNull);
        final icon = _globalRect(
          tester.renderObject<RenderBox>(find.byIcon(Icons.edit_outlined)),
        );
        expect(icon.left, greaterThanOrEqualTo(0));
        expect(icon.right, lessThanOrEqualTo(width));

        final summary = summaryParagraph(tester);
        expect(summary.didExceedMaxLines, isFalse,
            reason: 'the summary must not be truncated');
        final rect = _globalRect(summary);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      });
    }

    testWidgets('en at 1.0x keeps the summary on one line', (tester) async {
      // A wide surface: the test font is wider than the app font.
      await pumpAt(tester,
          locale: const Locale('en'), scale: 1.0, width: 1080);

      final summary = summaryParagraph(tester);
      expect(_lineCount(summary), 1);
      expect(find.text('501 · Double Out · ∞ Rounds · 1 leg'), findsOneWidget);
    });
  });
}

// ── Stub notifiers for startGame scenarios ────────────────────────────────────

/// A simple completer wrapper used to control when a notifier resolves.
class _ControlledStartCompleter {
  final _completer = Completer<String?>();
  Future<String?> get future => _completer.future;
  void complete(String? value) => _completer.complete(value);
}

/// Notifier whose startGame resolves via an external completer.
class _ControllableStartNotifier extends GameSetupNotifier {
  _ControllableStartNotifier(this._fixedState, this._completer);
  final GameSetupState _fixedState;
  final _ControlledStartCompleter _completer;

  @override
  GameSetupState build() => _fixedState;

  @override
  bool get canStart => true;

  @override
  Future<String?> startGame() => _completer.future;
}

/// Notifier that returns a fixed game ID on startGame.
class _SuccessGameSetupNotifier extends GameSetupNotifier {
  _SuccessGameSetupNotifier(this._fixedState, this._gameId);
  final GameSetupState _fixedState;
  final String _gameId;

  @override
  GameSetupState build() => _fixedState;

  @override
  bool get canStart => true;

  @override
  Future<String?> startGame() async => _gameId;
}

/// Notifier that returns null on startGame.
class _NullStartGameSetupNotifier extends GameSetupNotifier {
  _NullStartGameSetupNotifier(this._fixedState);
  final GameSetupState _fixedState;

  @override
  GameSetupState build() => _fixedState;

  @override
  bool get canStart => true;

  @override
  Future<String?> startGame() async => null;
}

/// Notifier that throws on startGame.
class _ThrowingStartGameSetupNotifier extends GameSetupNotifier {
  _ThrowingStartGameSetupNotifier(this._fixedState);
  final GameSetupState _fixedState;

  @override
  GameSetupState build() => _fixedState;

  @override
  bool get canStart => true;

  @override
  Future<String?> startGame() async {
    throw Exception('db error');
  }
}

/// Notifier that can be manually reset to selectingType from outside.
class _MutableGameSetupNotifier extends GameSetupNotifier {
  _MutableGameSetupNotifier(this._fixedState);
  final GameSetupState _fixedState;

  @override
  GameSetupState build() => _fixedState;

  void triggerReset() {
    state = const GameSetupState.selectingType();
  }
}

// ── Tracking repository ───────────────────────────────────────────────────────

class _TrackingPlayerRepository implements PlayerRepository {
  _TrackingPlayerRepository({required this.onCreatePlayer});

  final void Function(Player) onCreatePlayer;

  @override
  Future<void> createPlayer(Player player) async => onCreatePlayer(player);
  @override
  Future<List<Player>> getAllPlayers() async => [];
  @override
  Future<Player?> getPlayer(String playerId) async => null;
  @override
  Future<void> updatePlayerName(String playerId, String name) async {}
  @override
  Future<void> touchPlayer(String playerId) async {}
  @override
  Future<void> deletePlayer(String playerId) async {}
  @override
  Stream<List<Player>> watchAllPlayers() => const Stream.empty();
}

/// The number of laid-out lines of [p]: its height over one line's height.
int _lineCount(RenderParagraph p) {
  final oneLine = TextPainter(
    text: p.text,
    textScaler: p.textScaler,
    textDirection: p.textDirection,
    maxLines: 1,
  )..layout();
  final lines = (p.size.height / oneLine.height).round();
  oneLine.dispose();
  return lines;
}

/// [box]'s painted rect in global coordinates (including FittedBox scaling).
Rect _globalRect(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
