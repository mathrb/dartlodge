import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/state/player_stats_page_state.dart';

part 'player_stats_page_provider.g.dart';

// ── Player Stats Page providers ───────────────────────────────────────────────
//
// These providers are page-internal to the Player Stats screen: they own the
// filter state (active tab, time range, starting score, cricket variant,
// practice game type) and feed the per-tab filtered stats + leg-history
// queries. Co-located with `PlayerStatsPageState` so the page-state class
// stays inside `features/statistics/` (no inversion of the
// presentation → core dependency direction).

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
