import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:dart_lodge/features/game/presentation/state/game_setup_state.dart';

part 'game_setup_provider.g.dart';

@riverpod // autoDispose by default — wizard state is reset on leave
class GameSetupNotifier extends _$GameSetupNotifier {
  /// Never reaches the UI directly — seeded into `selectedPlayerIds` on entry
  /// to the player step.
  List<String> _lockedPlayerIds = const [];

  @override
  GameSetupState build() {
    _init(); // fire-and-forget: resolves before user reaches player step
    return GameSetupState.initial();
  }

  // ── Private init ────────────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      final gameRepo = ref.read(gameRepositoryProvider);
      final recent = await gameRepo.getCompletedGames(limit: 1);
      if (recent.isNotEmpty) {
        final competitors = await gameRepo.getCompetitors(recent.first.gameId);
        // Sort defensively — Competitor entity doesn't enforce player ordering.
        final ids = <String>{};
        for (final competitor in competitors) {
          final sortedPlayers = [...competitor.players]
            ..sort((a, b) => a.rotationPosition.compareTo(b.rotationPosition));
          for (final cp in sortedPlayers) {
            ids.add(cp.playerId);
          }
        }
        if (ids.isNotEmpty) {
          _lockedPlayerIds = ids.toList();
          return;
        }
      }

      // getAllPlayers() returns sorted by lastActive DESC, so .first is the most recent.
      final players = await ref.read(playerRepositoryProvider).getAllPlayers();
      if (players.isNotEmpty) {
        _lockedPlayerIds = [players.first.playerId];
      }
    } catch (_) {
      // Database not ready or no data — no-op, locked roster stays empty.
    }
  }

  List<String> _seedFor(GameType type) {
    final max = type.maxPlayers;
    if (max == null || _lockedPlayerIds.length <= max) {
      return List<String>.from(_lockedPlayerIds);
    }
    return _lockedPlayerIds.sublist(0, max);
  }

  // ── Public methods ───────────────────────────────────────────────────────────

  /// Re-launches a previously played game's configuration. Loads the
  /// game from the repository, then seeds setup state via
  /// [selectVariant] so the player-selection screen opens pre-configured
  /// with the same drill (#337). Returns true on success; false (and
  /// state untouched) when the game can't be found or the load throws.
  Future<bool> replayGame(String gameId) async {
    try {
      final game = await ref.read(gameRepositoryProvider).getGame(gameId);
      if (game == null) return false;
      selectVariant(game.config);
      return true;
    } catch (_) {
      return false;
    }
  }

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
        final type = _gameTypeFor(config);
        state = GameSetupState.selectingPlayers(
          gameType: type,
          config: config,
          selectedPlayerIds: _seedFor(type),
        );
      },
      configuringGame: (s) {
        state = GameSetupState.selectingPlayers(
          gameType: s.gameType,
          config: config,
          selectedPlayerIds: _seedFor(s.gameType),
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

  /// Sets a handicap offset for a specific player. Only valid in selectingPlayers.
  /// Allowed values: 0, -50, -100, -150, -200.
  void setPlayerHandicap(String playerId, int handicap) {
    state.maybeMap(
      selectingPlayers: (s) {
        final current = s.playerHandicaps[playerId] ?? 0;
        if (current == handicap) return;
        final updated = Map<String, int>.from(s.playerHandicaps);
        if (handicap == 0) {
          updated.remove(playerId);
        } else {
          updated[playerId] = handicap;
        }
        state = s.copyWith(playerHandicaps: updated);
      },
      orElse: () {},
    );
  }

  /// Resets to initial and re-fetches the locked roster.
  void reset() {
    _lockedPlayerIds = const [];
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

    // Competitors are built before the game so their UUIDs can be referenced
    // in the handicap map (which is keyed by competitorId, not playerId).
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

    Map<String, int> handicapsByCompetitor() {
      if (s.playerHandicaps.isEmpty) return const {};
      final result = <String, int>{};
      for (var i = 0; i < s.selectedPlayerIds.length; i++) {
        final handicap = s.playerHandicaps[s.selectedPlayerIds[i]];
        if (handicap != null && handicap != 0) {
          result[competitors[i].competitorId] = handicap;
        }
      }
      return result;
    }

    final GameConfig finalConfig = s.config.maybeMap(
      x01: (x01) {
        final handicaps = handicapsByCompetitor();
        return handicaps.isEmpty ? x01 : x01.copyWith(handicaps: handicaps);
      },
      countUp: (countUp) {
        final handicaps = handicapsByCompetitor();
        return handicaps.isEmpty
            ? countUp
            : countUp.copyWith(handicaps: handicaps);
      },
      orElse: () => s.config,
    );

    final game = Game(
      gameId: gameId,
      gameType: s.gameType,
      config: finalConfig,
      startTime: DateTime.now(),
    );

    // Abandon any lingering active game (page reload, app killed mid-game).
    final activeGame = await ref.read(gameRepositoryProvider).getActiveGame();
    if (activeGame != null) {
      await _abandonLingeringGame(activeGame.gameId);
    }

    try {
      final result =
          await ref.read(createGameUseCaseProvider).execute(game, competitors);
      // Persist config as "last used" for quick re-start next session.
      if (s.gameType == GameType.x01) {
        await ref.read(lastGameConfigProvider('x01').notifier).save(finalConfig);
      } else if (s.gameType == GameType.cricket) {
        await ref.read(lastGameConfigProvider('cricket').notifier).save(finalConfig);
      }
      return result.gameId;
    } on ValidationException {
      return null;
    }
  }

  /// Closes a game that was left active, the same way the End Game / End
  /// Drill menus do: `GameCompleted(winner=null)` is appended and the game is
  /// marked complete in one transaction. Without the event, the stats replay
  /// never sees a match boundary and the abandoned game's darts bleed into
  /// the next game's legs (#280).
  ///
  /// `endTime` is the abandoned game's last event, not "now": the game may
  /// have been left days before the next one starts, and History dates and
  /// sorts by it.
  Future<void> _abandonLingeringGame(String gameId) async {
    final events =
        await ref.read(gameEventRepositoryProvider).getEventsForGame(gameId);
    var latestSequence = 0;
    DateTime? lastPlayedAt;
    for (final e in events) {
      if (e.localSequence > latestSequence) latestSequence = e.localSequence;
      if (lastPlayedAt == null || e.occurredAt.isAfter(lastPlayedAt)) {
        lastPlayedAt = e.occurredAt;
      }
    }
    try {
      await ref.read(gameRepositoryProvider).appendEventsAndCompleteGame(
        events: [
          buildGameCompletedEvent(
            gameId: gameId,
            winnerCompetitorId: null,
            localSequence: latestSequence + 1,
          ),
        ],
        gameId: gameId,
        winnerCompetitorId: null,
        endTime: lastPlayedAt ?? DateTime.now(),
      );
    } on GameAlreadyCompleteException {
      // Idempotent: another path already closed the game.
    }
  }

  // ── Computed getters ─────────────────────────────────────────────────────────

  bool get canStart => state.maybeMap(
        selectingPlayers: (s) => s.selectedPlayerIds.isNotEmpty,
        orElse: () => false,
      );

  List<String> get lockedPlayerIds => List.unmodifiable(_lockedPlayerIds);

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static GameConfig _defaultConfigFor(GameType type) => switch (type) {
        GameType.x01 => const GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
            legsToWin: 1,
          ),
        GameType.cricket => GameConfig.cricket(
            scoring: 'standard',
            numbers: GameConfigurationConstants.cricketNumbers,
            legsToWin: 1,
          ),
        GameType.aroundTheClock   => const GameConfig.aroundTheClock(),
        GameType.shanghai         => const GameConfig.shanghai(),
        GameType.catch40          => const GameConfig.catch40(startingPlayerId: ''),
        GameType.bobs27           => const GameConfig.bobs27(startingPlayerId: ''),
        GameType.checkoutPractice => const GameConfig.checkoutPractice(startingPlayerId: ''),
        GameType.countUp          => const GameConfig.countUp(
            totalRounds: GameConfigurationConstants.countUpDefaultRounds,
          ),
      };

  static GameType _gameTypeFor(GameConfig config) => config.map(
        x01: (_) => GameType.x01,
        cricket: (_) => GameType.cricket,
        aroundTheClock: (_) => GameType.aroundTheClock,
        shanghai: (_) => GameType.shanghai,
        catch40: (_) => GameType.catch40,
        bobs27: (_) => GameType.bobs27,
        checkoutPractice: (_) => GameType.checkoutPractice,
        countUp: (_) => GameType.countUp,
      );
}
