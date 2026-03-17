// Statistics Repository Interface
// Defines the contract for statistics data access

import '../entities/player_stats.dart';
import '../entities/player_leg_snapshot.dart';
import '../entities/game_stats.dart';
import '../../../../core/utils/constants.dart';

abstract interface class StatisticsRepository {
  // Per-game statistics

  /// Computes and returns statistics for all competitors in [gameId].
  /// Throws [GameNotFoundException] if [gameId] does not exist.
  Future<GameStats> getGameStats(String gameId);

  /// Emits updated [GameStats] whenever a new dart throw is inserted for
  /// [gameId]. Used for live statistics during an active game.
  Stream<GameStats> watchGameStats(String gameId);

  // Per-player (career) statistics

  /// Returns aggregated career statistics for [playerId] across all games
  /// of [gameType]. Pass null for [gameType] to aggregate across all game types.
  ///
  /// [from] and [to] are inclusive date-range filters applied to [start_time].
  /// Throws [PlayerNotFoundException] if [playerId] does not exist.
  Future<PlayerStats> getPlayerStats(
    String playerId, {
    GameType? gameType,
    DateTime? from,
    DateTime? to,
    int? startingScore,
    String? variant,
    int? legLimit,
  });

  /// Returns per-leg PPR/MPT snapshots ordered oldest → newest.
  Future<List<PlayerLegSnapshot>> getPlayerLegHistory(
    String playerId, {
    GameType? gameType,
    int? startingScore,
    String? variant,
    int? limit,
  });

  /// Returns distinct X01 starting scores for the player's completed games,
  /// sorted ascending.
  Future<List<int>> getPlayerX01StartingScores(String playerId);

  /// Returns distinct cricket variant strings for the player's completed games.
  Future<List<String>> getPlayerCricketVariants(String playerId);

  /// Returns statistics for [playerId] scoped to a single completed [gameId].
  /// Throws [GameNotFoundException] if [gameId] does not exist.
  /// Throws [PlayerNotFoundException] if [playerId] did not participate.
  Future<PlayerStats> getPlayerStatsForGame(String playerId, String gameId);

  /// Emits updated career [PlayerStats] whenever a game involving [playerId]
  /// is completed. Used to keep the statistics dashboard current.
  Stream<PlayerStats> watchPlayerStats(String playerId, {GameType? gameType});

  // Leaderboard

  /// Returns all players ranked by [PlayerStats.threeDartAverage] descending
  /// for [gameType]. Excludes players with fewer than [minGames] games.
  Future<List<PlayerStats>> getLeaderboard({
    required GameType gameType,
    int minGames = 1,
    int limit = 50,
  });
}