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
  // The sole consumer (player picker AVG badge) displays PPR, which is
  // X01-only by definition. Cricket / practice players intentionally see
  // "AVG —" until a dedicated provider exists.
  return repository.watchPlayerStats(playerId, gameType: GameType.x01);
}

@riverpod
Stream<GameStats> liveGameStats(Ref ref, String gameId) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchGameStats(gameId);
}

@riverpod
Future<GameStats> gameStats(Ref ref, String gameId) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getGameStats(gameId);
}

// ── Player Stats Page providers ───────────────────────────────────────────────

@riverpod
class PlayerStatsPage extends _$PlayerStatsPage {
  @override
  PlayerStatsPageState build(String playerId) => PlayerStatsPageState.initial();

  void setTab(StatsTabIndex tab) => state = state.copyWith(activeTab: tab);
  void setStartingScore(int? score) =>
      state = state.copyWith(selectedStartingScore: score);
  void setCricketVariant(String? variant) =>
      state = state.copyWith(selectedCricketVariant: variant);
  void setTimeRange(StatsTimeRange range) =>
      state = state.copyWith(timeRange: range);
  void setPracticeGameType(GameType gameType) =>
      state = state.copyWith(selectedPracticeGameType: gameType);
}

@riverpod
Future<List<int>> playerX01StartingScores(Ref ref, String playerId) =>
    ref.watch(statisticsRepositoryProvider).getPlayerX01StartingScores(playerId);

@riverpod
Future<List<String>> playerCricketVariants(Ref ref, String playerId) =>
    ref.watch(statisticsRepositoryProvider).getPlayerCricketVariants(playerId);

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

@riverpod
Future<PlayerStats> filteredCricketStats(Ref ref, String playerId) {
  final s = ref.watch(playerStatsPageProvider(playerId));
  final limit = switch (s.timeRange) {
    StatsTimeRange.last10 => 10,
    StatsTimeRange.last100 => 100,
    StatsTimeRange.all => null,
  };
  return ref.watch(statisticsRepositoryProvider).getPlayerStats(
    playerId,
    gameType: GameType.cricket,
    variant: s.selectedCricketVariant,
    legLimit: limit,
  );
}

@riverpod
Future<List<PlayerLegSnapshot>> cricketLegHistory(Ref ref, String playerId) {
  final s = ref.watch(playerStatsPageProvider(playerId));
  final limit = switch (s.timeRange) {
    StatsTimeRange.last10 => 10,
    StatsTimeRange.last100 => 100,
    StatsTimeRange.all => null,
  };
  return ref.watch(statisticsRepositoryProvider).getPlayerLegHistory(
    playerId,
    gameType: GameType.cricket,
    variant: s.selectedCricketVariant,
    limit: limit,
  );
}

@riverpod
Future<PlayerStats> filteredPracticeStats(Ref ref, String playerId) {
  final s = ref.watch(playerStatsPageProvider(playerId));
  final limit = switch (s.timeRange) {
    StatsTimeRange.last10 => 10,
    StatsTimeRange.last100 => 100,
    StatsTimeRange.all => null,
  };
  return ref.watch(statisticsRepositoryProvider).getPlayerStats(
    playerId,
    gameType: s.selectedPracticeGameType,
    legLimit: limit,
  );
}

@riverpod
Future<List<PlayerLegSnapshot>> practiceDrillHistory(Ref ref, String playerId) {
  final s = ref.watch(playerStatsPageProvider(playerId));
  final limit = switch (s.timeRange) {
    StatsTimeRange.last10 => 10,
    StatsTimeRange.last100 => 100,
    StatsTimeRange.all => null,
  };
  return ref.watch(statisticsRepositoryProvider).getPlayerLegHistory(
    playerId,
    gameType: s.selectedPracticeGameType,
    limit: limit,
  );
}
