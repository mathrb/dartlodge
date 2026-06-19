// Statistics Repository Interface
// Defines the contract for statistics data access

import '../entities/player_stats.dart';
import '../entities/player_leg_snapshot.dart';
import '../entities/game_stats.dart';
import '../entities/dart_position.dart';
import '../assemblers/player_stats_assembler.dart' show AchievementMetricsData;
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
    String cricketTargetMode = 'fixed',
  });

  /// Cross-type achievement metric bundle for [playerId] (#525): replays the
  /// player's FULL completed history across ALL game types (no type filter) and
  /// delegates to `PlayerStatsAssembler.achievementMetricsFromEvents`. Returns a
  /// zero record when the player has no completed games. Throws
  /// [PlayerNotFoundException] if [playerId] does not exist. The achievements
  /// watcher maps this statistics-owned record to its `AchievementMetrics`.
  Future<AchievementMetricsData> achievementMetricsForPlayer(String playerId);

  /// Returns per-leg PPR/MPT snapshots ordered oldest → newest.
  ///
  /// [cricketTargetMode] selects the cricket target-mode cohort
  /// (`fixed` / `random` / `crazy`) — see
  /// `docs/plans/2026-05-19-cricket-target-modes-design.md` §6. Default is
  /// `fixed` because Standard Cricket career stats are the most common
  /// query and the bulk of historical data is fixed-mode. Random and Crazy
  /// stats are kept separate to avoid distorting the closure-rate and
  /// MPR shapes that depend on a known target set.
  Future<List<PlayerLegSnapshot>> getPlayerLegHistory(
    String playerId, {
    GameType? gameType,
    int? startingScore,
    String? variant,
    int? limit,
    String cricketTargetMode = 'fixed',
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

  /// Returns the recorded normalised positions of darts thrown by [playerId]
  /// for the impact heatmap (#576).
  ///
  /// These are RAW per-dart facts read directly from `dart_throws` — NOT a
  /// computed statistic, so the query does not route through
  /// `PlayerStatsAssembler`. Only located darts are returned: rows where
  /// `x`/`y` are NULL (manual entry, corrections, or pre-capture games) are
  /// excluded.
  ///
  /// Filters (all optional except [playerId], ANDed together):
  /// - [gameId]: a single game (post-game heatmap).
  /// - [gameType]: only darts from games of this type (stats tabs).
  /// - [from] / [to]: inclusive date window applied to the game's `start_time`.
  ///
  /// Coordinates are in the canonical board frame (origin = bullseye, radius
  /// 1.0 = outer double edge, "20 up"); see
  /// `docs/plans/2026-06-19-heatmap-design.md`.
  Future<List<DartPosition>> getDartPositions({
    String? gameId,
    required String playerId,
    GameType? gameType,
    DateTime? from,
    DateTime? to,
  });
}