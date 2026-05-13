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

  /// Emits an initial snapshot promptly on subscribe, then a new [GameStats]
  /// after any `dart_throws` or `game_events` write (table-granular — drift
  /// does not filter at the subscription layer, so writes to unrelated games
  /// also re-trigger; the emitted [GameStats] is scoped to [gameId] via
  /// re-computation). Watching both tables matters for events without a
  /// same-transaction dart insert (e.g. `LegCompleted`, `GameCompleted`,
  /// empty-turn busts via `TurnEnded`). Used for live statistics during an
  /// active game.
  Stream<GameStats> watchGameStats(String gameId);

  // Per-player (career) statistics

  /// Returns aggregated career statistics for [playerId] across completed
  /// games of [gameType].
  ///
  /// [gameType] is required: PPR-shaped fields (`threeDartAverage`,
  /// `bustRate`, score buckets) are X01-specific by definition, and cricket
  /// metrics (`marksPerTurn`, mark buckets) only apply to cricket. A single
  /// call cannot mix game types coherently.
  ///
  /// [from] and [to] are inclusive date-range filters applied to [start_time].
  /// Throws [PlayerNotFoundException] if [playerId] does not exist.
  Future<PlayerStats> getPlayerStats(
    String playerId, {
    required GameType gameType,
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

  /// Emits an initial snapshot promptly on subscribe, then updated career
  /// [PlayerStats] after any `dart_throws` or `game_events` write
  /// (table-granular — drift does not filter at the subscription layer, so
  /// writes for games this player isn't in also re-trigger; the emitted
  /// [PlayerStats] is scoped to [playerId] / [gameType] via re-computation).
  /// Used to keep the statistics dashboard current.
  ///
  /// [gameType] is required for the same reasons as [getPlayerStats].
  Stream<PlayerStats> watchPlayerStats(String playerId,
      {required GameType gameType});
}