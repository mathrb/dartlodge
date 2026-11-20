import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
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

/// A player's all-time stats for one [gameType]. The player picker reads
/// it for the lineup figure: X01 three-dart average, Cricket MPR.
@riverpod
Stream<PlayerStats> playerStats(
  Ref ref,
  String playerId,
  GameType gameType,
) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.watchPlayerStats(playerId, gameType: gameType);
}

@riverpod
Future<GameStats> gameStats(Ref ref, String gameId) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getGameStats(gameId);
}

/// Replays `game_events` through the practice/Shanghai engine and returns
/// the post-game `GameResult`. Returns null for x01/cricket/count-up — those
/// stay on [gameStatsProvider] (x01-shaped summary chrome fits them).
@riverpod
Future<GameResult?> gameResult(Ref ref, String gameId) {
  final useCase = ref.watch(getGameResultUseCaseProvider);
  return useCase.execute(gameId);
}
