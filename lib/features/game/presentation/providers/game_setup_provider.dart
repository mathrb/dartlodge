import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';

part 'game_setup_provider.g.dart';

@riverpod // autoDispose by default — wizard state is reset on leave
class GameSetupNotifier extends _$GameSetupNotifier {
  /// Locked player is NOT on GameSetupState; it never reaches the UI.
  String? _lockedPlayerId;

  @override
  GameSetupState build() {
    _init(); // fire-and-forget: resolves before user reaches player step
    return GameSetupState.initial();
  }

  // ── Private init ────────────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      final players = await ref.read(playerRepositoryProvider).getAllPlayers();
      // getAllPlayers() already returns sorted by lastActive DESC
      if (players.isNotEmpty) {
        _lockedPlayerId = players.first.playerId;
      }
    } catch (_) {
      // Database not ready or no players — locked player stays null (no-op).
    }
  }

  // ── Public methods ───────────────────────────────────────────────────────────

  /// selectingType → configuringGame (with default config for type)
  void selectGameType(GameType type) {
    state = GameSetupState.configuringGame(
      gameType: type,
      config: _defaultConfigFor(type),
    );
  }

  /// From selectingType: skip configuringGame, go directly to selectingPlayers.
  /// From configuringGame: confirm config, advance to selectingPlayers.
  /// From selectingPlayers: update config in place.
  void selectVariant(GameConfig config) {
    state.map(
      selectingType: (_) {
        state = GameSetupState.selectingPlayers(
          gameType: _gameTypeFor(config),
          config: config,
          selectedPlayerIds:
              _lockedPlayerId != null ? [_lockedPlayerId!] : [],
        );
      },
      configuringGame: (s) {
        state = GameSetupState.selectingPlayers(
          gameType: s.gameType,
          config: config,
          selectedPlayerIds:
              _lockedPlayerId != null ? [_lockedPlayerId!] : [],
        );
      },
      selectingPlayers: (s) {
        state = s.copyWith(config: config, gameType: _gameTypeFor(config));
      },
      formingTeams: (_) {},
      ready: (_) {},
    );
  }

  /// Reorders selected players by moving the item at [oldIndex] to [newIndex].
  /// No-ops if not in selectingPlayers.
  void reorderPlayers(int oldIndex, int newIndex) {
    state.maybeMap(
      selectingPlayers: (s) {
        final ids = List<String>.from(s.selectedPlayerIds);
        if (newIndex > oldIndex) newIndex -= 1;
        final id = ids.removeAt(oldIndex);
        ids.insert(newIndex, id);
        state = s.copyWith(selectedPlayerIds: ids);
      },
      orElse: () {},
    );
  }

  /// Adds or removes playerId. No-ops if not in selectingPlayers.
  void togglePlayer(String playerId) {
    state.maybeMap(
      selectingPlayers: (s) {
        final ids = s.selectedPlayerIds;
        final updated = ids.contains(playerId)
            ? ids.where((id) => id != playerId).toList()
            : [...ids, playerId];
        state = s.copyWith(selectedPlayerIds: updated);
      },
      orElse: () {},
    );
  }

  /// Replaces config in whichever variant holds it. No-ops in selectingType.
  void updateConfig(GameConfig config) {
    state.map(
      selectingType: (_) {},
      configuringGame: (s) => state = s.copyWith(config: config),
      selectingPlayers: (s) => state = s.copyWith(config: config),
      formingTeams: (s) => state = s.copyWith(config: config),
      ready: (s) => state = s.copyWith(config: config),
    );
  }

  /// Resets to initial and re-fetches the locked player.
  void reset() {
    _lockedPlayerId = null;
    state = GameSetupState.initial();
    _init();
  }

  /// Creates the game and competitors, then returns the new gameId.
  /// Returns null if the state is not ready or validation fails.
  Future<String?> startGame() async {
    if (!canStart) return null;

    final s = state.maybeMap(selectingPlayers: (s) => s, orElse: () => null);
    if (s == null) return null;

    final players = await ref.read(playerRepositoryProvider).getAllPlayers();
    final playerMap = {for (final p in players) p.playerId: p};

    final gameId = const Uuid().v4();

    final game = Game(
      gameId: gameId,
      gameType: s.gameType,
      config: s.config,
      startTime: DateTime.now(),
    );

    final competitors = <Competitor>[];
    for (var i = 0; i < s.selectedPlayerIds.length; i++) {
      final playerId = s.selectedPlayerIds[i];
      final player = playerMap[playerId];
      competitors.add(Competitor(
        competitorId: const Uuid().v4(),
        gameId: gameId,
        type: CompetitorType.solo,
        name: player?.name ?? playerId,
        players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
      ));
    }

    // Abandon any lingering active game (e.g. user navigated away mid-game)
    final activeGame = await ref.read(gameRepositoryProvider).getActiveGame();
    if (activeGame != null) {
      await ref.read(gameRepositoryProvider).completeGame(
        gameId: activeGame.gameId,
        winnerCompetitorId: null,
        endTime: DateTime.now(),
      );
    }

    try {
      final result =
          await ref.read(createGameUseCaseProvider).execute(game, competitors);
      // Persist config as "last used" for quick re-start next session.
      if (s.gameType == GameType.x01) {
        await ref.read(lastGameConfigProvider('x01').notifier).save(s.config);
      } else if (s.gameType == GameType.cricket) {
        await ref.read(lastGameConfigProvider('cricket').notifier).save(s.config);
      }
      return result.gameId;
    } on ValidationException {
      return null;
    }
  }

  // ── Computed getters ─────────────────────────────────────────────────────────

  bool get canStart => state.maybeMap(
        selectingPlayers: (s) => s.selectedPlayerIds.isNotEmpty,
        orElse: () => false,
      );

  String? get lockedPlayerId => _lockedPlayerId;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static GameConfig _defaultConfigFor(GameType type) => switch (type) {
        GameType.x01 => const GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        GameType.cricket => GameConfig.cricket(
            variant: 'standard',
            numbers: GameConfigurationConstants.cricketNumbers,
            pointsToWin: 3,
          ),
        GameType.aroundTheClock   => const GameConfig.aroundTheClock(),
        GameType.killer           => const GameConfig.killer(),
        GameType.baseball         => const GameConfig.baseball(),
        GameType.golf             => const GameConfig.golf(),
        GameType.shanghai         => const GameConfig.shanghai(),
        GameType.scram            => const GameConfig.scram(),
        GameType.halveIt          => const GameConfig.halveIt(),
        GameType.highScore        => const GameConfig.highScore(),
        GameType.blindCricket     => const GameConfig.blindCricket(),
        GameType.blindGolf        => const GameConfig.blindGolf(),
        GameType.blindKiller      => const GameConfig.blindKiller(),
        GameType.blindShanghai    => const GameConfig.blindShanghai(),
        GameType.chaseTheDragon   => const GameConfig.chaseTheDragon(),
        GameType.catch40          => const GameConfig.catch40(startingPlayerId: ''),
        GameType.bobs27           => const GameConfig.bobs27(startingPlayerId: ''),
        GameType.checkoutPractice => const GameConfig.checkoutPractice(startingPlayerId: ''),
      };

  static GameType _gameTypeFor(GameConfig config) => config.map(
        x01: (_) => GameType.x01,
        cricket: (_) => GameType.cricket,
        aroundTheClock: (_) => GameType.aroundTheClock,
        killer: (_) => GameType.killer,
        baseball: (_) => GameType.baseball,
        golf: (_) => GameType.golf,
        shanghai: (_) => GameType.shanghai,
        scram: (_) => GameType.scram,
        halveIt: (_) => GameType.halveIt,
        highScore: (_) => GameType.highScore,
        blindCricket: (_) => GameType.blindCricket,
        blindGolf: (_) => GameType.blindGolf,
        blindKiller: (_) => GameType.blindKiller,
        blindShanghai: (_) => GameType.blindShanghai,
        chaseTheDragon: (_) => GameType.chaseTheDragon,
        catch40: (_) => GameType.catch40,
        bobs27: (_) => GameType.bobs27,
        checkoutPractice: (_) => GameType.checkoutPractice,
      );
}
