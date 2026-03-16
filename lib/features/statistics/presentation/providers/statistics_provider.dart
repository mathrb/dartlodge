import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/persistence/database_provider.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/game_stats.dart';
import '../../domain/entities/player_stats.dart';
import '../../domain/entities/player_leg_snapshot.dart';
import '../state/player_stats_page_state.dart';

part 'statistics_provider.g.dart';

@riverpod
Stream<PlayerStats> playerStats(Ref ref, String playerId) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchPlayerStats(playerId);
}

@riverpod
Stream<GameStats> liveGameStats(Ref ref, String gameId) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchGameStats(gameId);
}

@riverpod
class Leaderboard extends _$Leaderboard {
  GameType _gameType = GameType.x01;
  int _minGames = 5;
  String _metric = 'threeDartAverage';

  @override
  Future<List<PlayerStats>> build() async {
    final repository = ref.read(statisticsRepositoryProvider);
    return repository.getLeaderboard(
      gameType: _gameType,
      minGames: _minGames,
    );
  }

  void setGameType(GameType gameType) {
    _gameType = gameType;
    ref.invalidateSelf();
  }

  void setMinGames(int min) {
    _minGames = min;
    ref.invalidateSelf();
  }

  void setMetric(String metric) {
    _metric = metric;
    ref.invalidateSelf();
  }
}

// ── Player Stats Page providers ───────────────────────────────────────────────

@riverpod
class PlayerStatsPage extends _$PlayerStatsPage {
  @override
  PlayerStatsPageState build(String playerId) => PlayerStatsPageState.initial();

  void setTab(StatsTabIndex tab) => state = state.copyWith(activeTab: tab);
  void setStartingScore(int? score) =>
      state = state.copyWith(selectedStartingScore: score);
  void setTimeRange(StatsTimeRange range) =>
      state = state.copyWith(timeRange: range);
  void toggleCheckoutOverlay() =>
      state = state.copyWith(showCheckoutOverlay: !state.showCheckoutOverlay);
}

@riverpod
Future<List<int>> playerX01StartingScores(Ref ref, String playerId) =>
    ref.watch(statisticsRepositoryProvider).getPlayerX01StartingScores(playerId);

@riverpod
Future<PlayerStats> filteredPlayerStats(Ref ref, String playerId) {
  final s = ref.watch(playerStatsPageProvider(playerId));
  final limit = switch (s.timeRange) {
    StatsTimeRange.last10 => 10,
    StatsTimeRange.last100 => 100,
    StatsTimeRange.all => null,
  };
  return ref.watch(statisticsRepositoryProvider).getPlayerStats(
    playerId,
    gameType: GameType.x01,
    startingScore: s.selectedStartingScore,
    legLimit: limit,
  );
}

@riverpod
Future<List<PlayerLegSnapshot>> playerLegHistory(Ref ref, String playerId) {
  final s = ref.watch(playerStatsPageProvider(playerId));
  final limit = switch (s.timeRange) {
    StatsTimeRange.last10 => 10,
    StatsTimeRange.last100 => 100,
    StatsTimeRange.all => null,
  };
  return ref.watch(statisticsRepositoryProvider).getPlayerLegHistory(
    playerId,
    gameType: GameType.x01,
    startingScore: s.selectedStartingScore,
    limit: limit,
  );
}
