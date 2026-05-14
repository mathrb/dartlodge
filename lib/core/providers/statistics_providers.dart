import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';

part 'statistics_providers.g.dart';

/// Cross-feature read providers exposing statistics data to callers outside
/// the statistics feature (e.g. the game player-picker AVG badge, in-game
/// live stats display, post-game summary).
///
/// Page-internal state and filter-driven derivations for the Player Stats
/// screen live in
/// `lib/features/statistics/presentation/providers/player_stats_page_provider.dart`
/// so that `features/statistics/` presentation types are not imported from
/// `core/` (which would invert the architecture's dependency direction).

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
