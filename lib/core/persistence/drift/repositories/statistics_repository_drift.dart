// Statistics Repository Drift Implementation
// Concrete implementation of StatisticsRepository interface using Drift

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:my_darts/features/statistics/domain/entities/player_stats.dart';
import 'package:my_darts/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:my_darts/features/statistics/domain/entities/game_stats.dart';
import '../database.dart' as drift_db;

class StatisticsRepositoryDrift implements StatisticsRepository {
  final drift_db.AppDatabase _db;

  StatisticsRepositoryDrift(this._db);

  @override
  Future<GameStats> getGameStats(String gameId) async {
    try {
      // Verify game exists
      final gameExists = await (_db.select(_db.games)
            ..where((g) => g.gameId.equals(gameId))
            ..limit(1))
          .getSingleOrNull() !=
          null;

      if (!gameExists) {
        throw GameNotFoundException(gameId);
      }

      // Get all dart throws for this game ordered by turn/dart number
      final dartThrows = await (_db.select(_db.dartThrows)
            ..where((t) => t.gameId.equals(gameId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.turnNumber),
              (t) => OrderingTerm.asc(t.dartNumber),
            ]))
          .get();

      if (dartThrows.isEmpty) {
        return GameStats(gameId: gameId, byCompetitor: []);
      }

      // Group by competitor in Dart
      final Map<String, List<drift_db.DartThrow>> byCompetitor = {};
      for (final t in dartThrows) {
        byCompetitor.putIfAbsent(t.competitorId, () => []).add(t);
      }

      final List<CompetitorStats> competitorStats = [];

      for (final entry in byCompetitor.entries) {
        final competitorId = entry.key;
        final throws = entry.value;

        // Get competitor name
        final competitor = await (_db.select(_db.competitors)
              ..where((c) => c.competitorId.equals(competitorId))
              ..limit(1))
            .getSingleOrNull();

        if (competitor == null) continue;

        // Group throws by player within competitor
        final Map<String, List<drift_db.DartThrow>> byPlayer = {};
        for (final t in throws) {
          byPlayer.putIfAbsent(t.playerId, () => []).add(t);
        }

        // Build PlayerTurnStats for each player
        final List<PlayerTurnStats> playerTurnStats = [];
        for (final playerEntry in byPlayer.entries) {
          final playerId = playerEntry.key;
          final playerThrows = playerEntry.value;

          final int playerDarts = playerThrows.length;
          final int playerScore =
              playerThrows.fold(0, (sum, t) => sum + t.score);
          final double playerAvg =
              playerDarts > 0 ? (playerScore / playerDarts) * 3 : 0.0;

          playerTurnStats.add(PlayerTurnStats(
            playerId: playerId,
            threeDartAverage: playerAvg,
            dartsThrown: playerDarts,
          ));
        }

        // Competitor totals
        final int totalDarts = throws.length;
        final int totalScore = throws.fold(0, (sum, t) => sum + t.score);
        final double threeDartAverage =
            totalDarts > 0 ? (totalScore / totalDarts) * 3 : 0.0;

        final legsWon = await _getLegsWonForCompetitor(competitorId, gameId);

        competitorStats.add(CompetitorStats(
          competitorId: competitorId,
          competitorName: competitor.name,
          byPlayer: playerTurnStats,
          threeDartAverage: threeDartAverage,
          legsWon: legsWon,
          totalDartsThrown: totalDarts,
        ));
      }

      return GameStats(gameId: gameId, byCompetitor: competitorStats);
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve game statistics: ${e.toString()}');
    }
  }

  @override
  Stream<GameStats> watchGameStats(String gameId) {
    final dartThrowsQuery = _db.select(_db.dartThrows)
      ..where((t) => t.gameId.equals(gameId));

    return dartThrowsQuery
        .watch()
        .asyncMap((_) async => getGameStats(gameId))
        .handleError((error) {
      if (error is RepositoryException) throw error;
      throw StatisticsException(
          'Failed to watch game statistics: ${error.toString()}');
    });
  }

  @override
  Future<PlayerStats> getPlayerStats(
    String playerId, {
    GameType? gameType,
    DateTime? from,
    DateTime? to,
    int? startingScore,
    String? variant,
    int? legLimit,
  }) async {
    try {
      // Verify player exists
      final playerExists = await (_db.select(_db.players)
            ..where((p) => p.playerId.equals(playerId))
            ..limit(1))
          .getSingleOrNull() !=
          null;

      if (!playerExists) {
        throw PlayerNotFoundException(playerId);
      }

      // Build dart count query
      final dartCountQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.dartId.count()])
        ..where(_db.dartThrows.playerId.equals(playerId));

      // Build avg score query
      final avgScoreQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.score.avg()])
        ..where(_db.dartThrows.playerId.equals(playerId));

      late int dartCount;
      late double avgScore;

      if (gameType != null || from != null || to != null) {
        final joinedDartCountQuery = dartCountQuery.join([
          innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
        ]);
        final joinedAvgScoreQuery = avgScoreQuery.join([
          innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
        ]);

        if (gameType != null) {
          joinedDartCountQuery
              .where(_db.games.gameType.equals(gameType.name));
          joinedAvgScoreQuery
              .where(_db.games.gameType.equals(gameType.name));
        }
        if (from != null) {
          joinedDartCountQuery.where(
              _db.games.startTime.isBiggerOrEqualValue(from.toIso8601String()));
          joinedAvgScoreQuery.where(
              _db.games.startTime.isBiggerOrEqualValue(from.toIso8601String()));
        }
        if (to != null) {
          joinedDartCountQuery.where(
              _db.games.startTime.isSmallerOrEqualValue(to.toIso8601String()));
          joinedAvgScoreQuery.where(
              _db.games.startTime.isSmallerOrEqualValue(to.toIso8601String()));
        }

        final dartCountResult = await joinedDartCountQuery.getSingle();
        dartCount = dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

        final avgScoreResult = await joinedAvgScoreQuery.getSingle();
        avgScore = avgScoreResult.read(_db.dartThrows.score.avg()) ?? 0;
      } else {
        final dartCountResult = await dartCountQuery.getSingle();
        dartCount = dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

        final avgScoreResult = await avgScoreQuery.getSingle();
        avgScore = avgScoreResult.read(_db.dartThrows.score.avg()) ?? 0;
      }

      if (dartCount == 0) {
        return _createEmptyPlayerStats(playerId, gameType);
      }

      // Total distinct completed games for player
      final totalGames = await _getTotalGamesForPlayer(playerId, gameType, from, to);

      // Games won
      final gamesWon = await _getGamesWonByPlayer(playerId, gameType);
      final double winRate = totalGames > 0 ? gamesWon / totalGames : 0.0;

      // Highest turn score
      final highestTurnScore =
          await _calculateHighestTurnScore(playerId, gameType);

      // Legs played, legs won and darts per leg
      final legsPlayed = await _getLegsPlayedByPlayer(playerId, gameType);
      final legsWon = await _getLegsWonByPlayer(playerId, gameType);
      final double dartsPerLeg =
          legsPlayed > 0 ? dartCount / legsPlayed : 0.0;

      // Cricket-specific stats (early return — X01 fields not applicable)
      if (gameType == GameType.cricket) {
        final cricketStats =
            await _calculateCricketStats(playerId, variant: variant);
        return PlayerStats(
          playerId: playerId,
          gameType: GameType.cricket,
          totalGames: totalGames,
          gamesWon: gamesWon,
          winRate: winRate,
          threeDartAverage: 0.0,
          bustRate: 0.0,
          highestTurnScore: 0,
          dartsPerLeg: dartsPerLeg,
          totalDartsThrown: dartCount,
          legsPlayed: legsPlayed,
          legsWon: legsWon,
          marksPerTurn: cricketStats['marksPerTurn'] as double?,
          hitRate: cricketStats['hitRate'] as double?,
          sixMarkTurns: cricketStats['sixMarkTurns'] as int? ?? 0,
          nineMarkTurns: cricketStats['nineMarkTurns'] as int? ?? 0,
        );
      }

      // Bust rate
      final bustRate = await _calculateBustRate(playerId, gameType);

      // X01-specific stats
      double? checkoutPercentage;
      int? highestCheckout;
      if (gameType == GameType.x01 || gameType == null) {
        final x01Stats = await _calculateX01Statistics(playerId, gameType);
        checkoutPercentage = x01Stats['checkoutPercentage'] as double?;
        highestCheckout = x01Stats['highestCheckout'] as int?;
      }

      final GameType effectiveGameType = gameType ?? GameType.x01;

      // Score buckets (60+, 100+, 140+, 180) — computed from game_events
      Map<String, int> scoreBuckets = {};
      if (effectiveGameType == GameType.x01) {
        // Collect game IDs for this player
        final gameIdsQuery = _db.selectOnly(_db.dartThrows)
          ..addColumns([_db.dartThrows.gameId])
          ..join([
            innerJoin(
                _db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
          ])
          ..where(_db.dartThrows.playerId.equals(playerId) &
              _db.games.gameType.equals(GameType.x01.name))
          ..groupBy([_db.dartThrows.gameId]);
        final gameIdRows = await gameIdsQuery.get();
        final gameIds = gameIdRows
            .map((r) => r.read(_db.dartThrows.gameId))
            .whereType<String>()
            .toList();
        scoreBuckets = await _calculateX01ScoreBuckets(playerId, gameIds);
      }

      return PlayerStats(
        playerId: playerId,
        gameType: effectiveGameType,
        totalGames: totalGames,
        gamesWon: gamesWon,
        winRate: winRate,
        threeDartAverage: (avgScore * 3).toDouble(),
        checkoutPercentage: checkoutPercentage,
        highestCheckout: highestCheckout,
        highestTurnScore: highestTurnScore,
        totalDartsThrown: dartCount,
        dartsPerLeg: dartsPerLeg,
        bustRate: bustRate,
        legsPlayed: legsPlayed,
        legsWon: legsWon,
        sixtyPlusTurns: scoreBuckets['sixtyPlus'] ?? 0,
        oneHundredPlusTurns: scoreBuckets['oneHundredPlus'] ?? 0,
        oneFortyPlusTurns: scoreBuckets['oneFortyPlus'] ?? 0,
        oneEightyTurns: scoreBuckets['oneEighty'] ?? 0,
      );
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve player statistics: ${e.toString()}');
    }
  }

  @override
  Future<PlayerStats> getPlayerStatsForGame(
      String playerId, String gameId) async {
    try {
      // Check game exists first
      final game = await (_db.select(_db.games)
            ..where((g) => g.gameId.equals(gameId))
            ..limit(1))
          .getSingleOrNull();

      if (game == null) {
        throw GameNotFoundException(gameId);
      }

      // Check player participated
      final dartCountQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.dartId.count()])
        ..where(_db.dartThrows.playerId.equals(playerId) &
            _db.dartThrows.gameId.equals(gameId));

      final dartCountResult = await dartCountQuery.getSingle();
      final dartCount =
          dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

      if (dartCount == 0) {
        throw PlayerNotFoundException(playerId);
      }

      final gameType = GameType.values.firstWhere(
        (type) => type.name == game.gameType,
        orElse: () => GameType.x01,
      );

      // Average score for this game/player
      final avgScoreQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.score.avg()])
        ..where(_db.dartThrows.playerId.equals(playerId) &
            _db.dartThrows.gameId.equals(gameId));

      final avgScoreResult = await avgScoreQuery.getSingle();
      final double avgScore =
          avgScoreResult.read(_db.dartThrows.score.avg()) ?? 0;

      // Game-specific metrics
      final highestTurnScore =
          await _calculateHighestTurnScore(playerId, gameType, gameId: gameId);
      final checkoutPercentage =
          await _calculateCheckoutPercentageForGame(playerId, gameId);
      final highestCheckout =
          await _calculateHighestCheckoutForGame(playerId, gameId);
      final bustRate =
          await _calculateBustRate(playerId, gameType, gameId: gameId);
      final legsPlayedInGame = await _getLegsPlayedInGame(gameId);
      final legsWon = await _getLegsWonForPlayerInGame(playerId, gameId);
      final double dartsPerLeg =
          legsPlayedInGame > 0 ? dartCount / legsPlayedInGame : 0.0;

      return PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: 1,
        gamesWon: legsWon > 0 ? 1 : 0,
        winRate: legsWon > 0 ? 1.0 : 0.0,
        threeDartAverage: (avgScore * 3).toDouble(),
        checkoutPercentage: checkoutPercentage,
        highestCheckout: highestCheckout,
        highestTurnScore: highestTurnScore,
        totalDartsThrown: dartCount,
        dartsPerLeg: dartsPerLeg,
        bustRate: bustRate,
        legsPlayed: legsPlayedInGame,
        legsWon: legsWon,
      );
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve player game statistics: ${e.toString()}');
    }
  }

  @override
  Stream<PlayerStats> watchPlayerStats(String playerId,
      {GameType? gameType}) {
    if (gameType != null) {
      final dartThrowsQuery = _db.select(_db.dartThrows)
        ..where((t) => t.playerId.equals(playerId));
      final joinedQuery = dartThrowsQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId)),
      ]);
      joinedQuery.where(_db.games.gameType.equals(gameType.name));
      return joinedQuery
          .watch()
          .asyncMap((_) async => getPlayerStats(playerId, gameType: gameType))
          .handleError((error) {
        if (error is RepositoryException) throw error;
        throw StatisticsException(
            'Failed to watch player statistics: ${error.toString()}');
      });
    } else {
      final dartThrowsQuery = _db.select(_db.dartThrows)
        ..where((t) => t.playerId.equals(playerId));
      return dartThrowsQuery
          .watch()
          .asyncMap(
              (_) async => getPlayerStats(playerId, gameType: gameType))
          .handleError((error) {
        if (error is RepositoryException) throw error;
        throw StatisticsException(
            'Failed to watch player statistics: ${error.toString()}');
      });
    }
  }

  @override
  Future<List<PlayerStats>> getLeaderboard({
    required GameType gameType,
    int minGames = 1,
    int limit = 50,
  }) async {
    try {
      final gamesPerPlayerQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.playerId, _db.dartThrows.gameId.count()])
        ..join([
          innerJoin(
              _db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
        ])
        ..where(_db.games.gameType.equals(gameType.name))
        ..groupBy([_db.dartThrows.playerId]);

      final gamesPerPlayerResults = await gamesPerPlayerQuery.get();
      final playerGameCounts = <String, int>{};
      for (final row in gamesPerPlayerResults) {
        final pId = row.read(_db.dartThrows.playerId);
        final gameCount = row.read(_db.dartThrows.gameId.count()) ?? 0;
        if (pId != null && gameCount >= minGames) {
          playerGameCounts[pId] = gameCount;
        }
      }

      final leaderboard = <PlayerStats>[];
      for (final pId in playerGameCounts.keys) {
        final stats = await getPlayerStats(pId, gameType: gameType);
        leaderboard.add(stats);
      }

      leaderboard
          .sort((a, b) => b.threeDartAverage.compareTo(a.threeDartAverage));

      return leaderboard.take(limit).toList();
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve leaderboard: ${e.toString()}');
    }
  }

  // ── Helper methods ──────────────────────────────────────────────────────────

  PlayerStats _createEmptyPlayerStats(String playerId, GameType? gameType) {
    return PlayerStats(
      playerId: playerId,
      gameType: gameType ?? GameType.x01,
      totalGames: 0,
      gamesWon: 0,
      winRate: 0.0,
      threeDartAverage: 0.0,
      checkoutPercentage: null,
      highestCheckout: null,
      highestTurnScore: 0,
      totalDartsThrown: 0,
      dartsPerLeg: 0.0,
      bustRate: 0.0,
    );
  }

  /// Count of distinct completed games the player has participated in.
  Future<int> _getTotalGamesForPlayer(
    String playerId,
    GameType? gameType,
    DateTime? from,
    DateTime? to,
  ) async {
    try {
      final query = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.gameId.count(distinct: true)])
        ..join([
          innerJoin(
              _db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
        ])
        ..where(_db.dartThrows.playerId.equals(playerId) &
            _db.games.isComplete.equals(1));

      if (gameType != null) {
        query.where(_db.games.gameType.equals(gameType.name));
      }
      if (from != null) {
        query.where(
            _db.games.startTime.isBiggerOrEqualValue(from.toIso8601String()));
      }
      if (to != null) {
        query.where(
            _db.games.startTime.isSmallerOrEqualValue(to.toIso8601String()));
      }

      final result = await query.getSingle();
      return result.read(_db.dartThrows.gameId.count(distinct: true)) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Number of games won by [playerId] (via winner_competitor_id join).
  Future<int> _getGamesWonByPlayer(
      String playerId, GameType? gameType) async {
    try {
      final query = _db.selectOnly(_db.games)
        ..addColumns([_db.games.gameId.count(distinct: true)])
        ..join([
          innerJoin(_db.competitors,
              _db.competitors.competitorId.equalsExp(_db.games.winnerCompetitorId)),
          innerJoin(_db.competitorPlayers,
              _db.competitorPlayers.competitorId
                  .equalsExp(_db.competitors.competitorId)),
        ])
        ..where(_db.competitorPlayers.playerId.equals(playerId) &
            _db.games.isComplete.equals(1));

      if (gameType != null) {
        query.where(_db.games.gameType.equals(gameType.name));
      }

      final result = await query.getSingle();
      return result.read(_db.games.gameId.count(distinct: true)) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Highest single-turn score for [playerId] across the given scope.
  Future<int> _calculateHighestTurnScore(
    String playerId,
    GameType? gameType, {
    String? gameId,
  }) async {
    try {
      String gameFilter;
      List<String> args;

      if (gameId != null) {
        gameFilter = 'AND game_id = ?';
        args = [playerId, gameId];
      } else if (gameType != null) {
        gameFilter =
            "AND game_id IN (SELECT game_id FROM games WHERE game_type = ?)";
        args = [playerId, gameType.name];
      } else {
        gameFilter = '';
        args = [playerId];
      }

      final sql = '''
        SELECT MAX(turn_score) AS highest_turn_score
        FROM (
          SELECT SUM(score) AS turn_score
          FROM dart_throws
          WHERE player_id = ?
          $gameFilter
          GROUP BY game_id, turn_number
        )
      ''';

      final rows = await _db.customSelect(sql, variables: [
        for (final a in args) Variable.withString(a),
      ]).get();

      final raw = rows.first.data['highest_turn_score'];
      if (raw == null) return 0;
      return (raw as num).toInt();
    } catch (e) {
      return 0;
    }
  }

  /// Number of legs won by [playerId] across completed games of [gameType].
  Future<int> _getLegsWonByPlayer(
      String playerId, GameType? gameType) async {
    try {
      String gameTypeFilter = '';
      List<Variable<Object>> vars = [Variable.withString(playerId)];

      if (gameType != null) {
        gameTypeFilter = 'AND g.game_type = ?';
        vars.add(Variable.withString(gameType.name));
      }

      final sql = '''
        SELECT COUNT(*) AS legs_won
        FROM game_events ge
        JOIN games g ON ge.game_id = g.game_id
        WHERE ge.event_type = 'LegCompleted'
        AND JSON_EXTRACT(ge.payload_json, '\$.winner_player_id') = ?
        AND g.is_complete = 1
        $gameTypeFilter
      ''';

      final rows = await _db.customSelect(sql, variables: vars).get();
      final raw = rows.first.data['legs_won'];
      if (raw == null) return 0;
      return (raw as num).toInt();
    } catch (e) {
      return 0;
    }
  }

  /// Cricket-specific stats: MPT, hit rate, and mark buckets.
  /// Computed from [dart_throws] using the canonical segment format.
  Future<Map<String, dynamic>> _calculateCricketStats(
    String playerId, {
    String? variant,
  }) async {
    try {
      String variantFilter = '';
      List<Variable<Object>> vars = [Variable.withString(playerId)];

      if (variant != null) {
        variantFilter =
            "AND JSON_EXTRACT(g.config_json, '\$.variant') = ?";
        vars.add(Variable.withString(variant));
      }

      // Segment-to-marks expression shared across queries.
      // Handles: DB=2, SB=1, T{n}=3, D{n}=2, {n}=1 for n in cricket targets.
      const marksExpr = '''
        CASE
          WHEN dt.segment = 'DB' THEN 2
          WHEN dt.segment = 'SB' THEN 1
          WHEN dt.segment LIKE 'T%'
            AND CAST(SUBSTR(dt.segment, 2) AS INTEGER) IN (15,16,17,18,19,20,25) THEN 3
          WHEN dt.segment LIKE 'D%'
            AND CAST(SUBSTR(dt.segment, 2) AS INTEGER) IN (15,16,17,18,19,20,25) THEN 2
          WHEN CAST(dt.segment AS INTEGER) IN (15,16,17,18,19,20,25) THEN 1
          ELSE 0
        END
      ''';

      final mptSql = '''
        SELECT
          SUM($marksExpr) AS total_marks,
          COUNT(DISTINCT dt.game_id || '|' || CAST(dt.turn_number AS TEXT)) AS total_turns
        FROM dart_throws dt
        JOIN games g ON dt.game_id = g.game_id
        WHERE dt.player_id = ?
        AND g.game_type = 'cricket'
        AND g.is_complete = 1
        $variantFilter
      ''';

      final hitRateSql = '''
        SELECT
          COUNT(*) AS total_darts,
          SUM(CASE
            WHEN dt.segment IN ('DB', 'SB') THEN 1
            WHEN dt.segment LIKE 'T%'
              AND CAST(SUBSTR(dt.segment, 2) AS INTEGER) IN (15,16,17,18,19,20,25) THEN 1
            WHEN dt.segment LIKE 'D%'
              AND CAST(SUBSTR(dt.segment, 2) AS INTEGER) IN (15,16,17,18,19,20,25) THEN 1
            WHEN CAST(dt.segment AS INTEGER) IN (15,16,17,18,19,20,25) THEN 1
            ELSE 0
          END) AS cricket_darts
        FROM dart_throws dt
        JOIN games g ON dt.game_id = g.game_id
        WHERE dt.player_id = ?
        AND g.game_type = 'cricket'
        AND g.is_complete = 1
        $variantFilter
      ''';

      final markBucketsSql = '''
        SELECT
          SUM(CASE WHEN turn_marks >= 9 THEN 1 ELSE 0 END) AS nine_mark_turns,
          SUM(CASE WHEN turn_marks >= 6 THEN 1 ELSE 0 END) AS six_mark_turns
        FROM (
          SELECT SUM($marksExpr) AS turn_marks
          FROM dart_throws dt
          JOIN games g ON dt.game_id = g.game_id
          WHERE dt.player_id = ?
          AND g.game_type = 'cricket'
          AND g.is_complete = 1
          $variantFilter
          GROUP BY dt.game_id, dt.turn_number
        )
      ''';

      final mptRows =
          await _db.customSelect(mptSql, variables: vars).get();
      final hitRateRows =
          await _db.customSelect(hitRateSql, variables: vars).get();
      final bucketsRows =
          await _db.customSelect(markBucketsSql, variables: vars).get();

      final totalMarks =
          (mptRows.first.data['total_marks'] as num? ?? 0).toInt();
      final totalTurns =
          (mptRows.first.data['total_turns'] as num? ?? 0).toInt();
      final double? marksPerTurn =
          totalTurns > 0 ? totalMarks / totalTurns : null;

      final totalDarts =
          (hitRateRows.first.data['total_darts'] as num? ?? 0).toInt();
      final cricketDarts =
          (hitRateRows.first.data['cricket_darts'] as num? ?? 0).toInt();
      final double? hitRate =
          totalDarts > 0 ? cricketDarts / totalDarts : null;

      final nineMarkTurns =
          (bucketsRows.first.data['nine_mark_turns'] as num? ?? 0).toInt();
      final sixMarkTurns =
          (bucketsRows.first.data['six_mark_turns'] as num? ?? 0).toInt();

      return {
        'marksPerTurn': marksPerTurn,
        'hitRate': hitRate,
        'sixMarkTurns': sixMarkTurns,
        'nineMarkTurns': nineMarkTurns,
      };
    } catch (e) {
      return {
        'marksPerTurn': null,
        'hitRate': null,
        'sixMarkTurns': 0,
        'nineMarkTurns': 0,
      };
    }
  }

  /// Number of legs played by [playerId] across completed games of [gameType].
  Future<int> _getLegsPlayedByPlayer(
      String playerId, GameType? gameType) async {
    try {
      String gameTypeFilter = '';
      List<Variable<Object>> vars = [Variable.withString(playerId)];

      if (gameType != null) {
        gameTypeFilter = 'AND g.game_type = ?';
        vars.add(Variable.withString(gameType.name));
      }

      final sql = '''
        SELECT COUNT(*) AS legs_played
        FROM game_events ge
        JOIN games g ON ge.game_id = g.game_id
        WHERE ge.event_type = 'LegCompleted'
        AND g.is_complete = 1
        AND g.game_id IN (
          SELECT DISTINCT game_id FROM dart_throws WHERE player_id = ?
        )
        $gameTypeFilter
      ''';

      final rows = await _db.customSelect(sql, variables: vars).get();
      final raw = rows.first.data['legs_played'];
      if (raw == null) return 0;
      return (raw as num).toInt();
    } catch (e) {
      return 0;
    }
  }

  /// Total legs played in a single game (all LegCompleted events).
  Future<int> _getLegsPlayedInGame(String gameId) async {
    try {
      final events = await (_db.select(_db.gameEvents)
            ..where((e) =>
                e.gameId.equals(gameId) & e.eventType.equals('LegCompleted')))
          .get();
      return events.length;
    } catch (e) {
      return 0;
    }
  }

  /// Bust rate for [playerId] across the given scope.
  Future<double> _calculateBustRate(
    String playerId,
    GameType? gameType, {
    String? gameId,
  }) async {
    try {
      String scopeFilter;
      List<String> args;

      if (gameId != null) {
        scopeFilter = 'AND game_id = ?';
        args = [playerId, gameId];
      } else if (gameType != null) {
        scopeFilter =
            "AND game_id IN (SELECT game_id FROM games WHERE game_type = ?)";
        args = [playerId, gameType.name];
      } else {
        scopeFilter = '';
        args = [playerId];
      }

      final bustSql = '''
        SELECT COUNT(*) AS bust_count
        FROM game_events
        WHERE event_type = 'TurnEnded'
        AND JSON_EXTRACT(payload_json, '\$.player_id') = ?
        AND JSON_EXTRACT(payload_json, '\$.reason') = 'bust'
        $scopeFilter
      ''';

      final turnSql = '''
        SELECT COUNT(*) AS turn_count
        FROM game_events
        WHERE event_type = 'TurnEnded'
        AND JSON_EXTRACT(payload_json, '\$.player_id') = ?
        $scopeFilter
      ''';

      final bustVars = [for (final a in args) Variable.withString(a)];
      final turnVars = [for (final a in args) Variable.withString(a)];

      final bustRows =
          await _db.customSelect(bustSql, variables: bustVars).get();
      final turnRows =
          await _db.customSelect(turnSql, variables: turnVars).get();

      final bustCount =
          (bustRows.first.data['bust_count'] as num? ?? 0).toInt();
      final turnCount =
          (turnRows.first.data['turn_count'] as num? ?? 0).toInt();

      return turnCount > 0 ? bustCount / turnCount : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Legs won by competitor in a single game (Dart-side JSON parsing).
  Future<int> _getLegsWonForCompetitor(
      String competitorId, String gameId) async {
    try {
      final events = await (_db.select(_db.gameEvents)
            ..where((e) =>
                e.gameId.equals(gameId) &
                e.eventType.equals('LegCompleted')))
          .get();

      int legsWon = 0;
      for (final event in events) {
        final payload =
            jsonDecode(event.payloadJson) as Map<String, dynamic>;
        if (payload['winner_competitor_id'] == competitorId) {
          legsWon++;
        }
      }
      return legsWon;
    } catch (e) {
      return 0;
    }
  }

  /// Legs won by player in a single game (Dart-side JSON parsing).
  Future<int> _getLegsWonForPlayerInGame(
      String playerId, String gameId) async {
    try {
      final events = await (_db.select(_db.gameEvents)
            ..where((e) =>
                e.gameId.equals(gameId) &
                e.eventType.equals('LegCompleted')))
          .get();

      int legsWon = 0;
      for (final event in events) {
        final payload =
            jsonDecode(event.payloadJson) as Map<String, dynamic>;
        if (payload['winner_player_id'] == playerId) {
          legsWon++;
        }
      }
      return legsWon;
    } catch (e) {
      return 0;
    }
  }

  /// Checkout percentage for [playerId] in a single game (Dart-side JSON parsing).
  Future<double?> _calculateCheckoutPercentageForGame(
      String playerId, String gameId) async {
    try {
      final events = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.equals(gameId))
            ..orderBy([(e) => OrderingTerm.asc(e.localSequence)]))
          .get();

      if (events.isEmpty) return null;

      int checkoutAttempts = 0;
      int successfulCheckouts = 0;
      bool inCheckoutRange = false;

      for (final event in events) {
        final payload =
            jsonDecode(event.payloadJson) as Map<String, dynamic>;
        final eventType = event.eventType;

        if (eventType == 'TurnStarted') {
          final turnPlayerId = payload['player_id'] as String?;
          final startingScore = payload['starting_score'] as int?;
          if (turnPlayerId == playerId &&
              startingScore != null &&
              startingScore <= 170) {
            inCheckoutRange = true;
            checkoutAttempts++;
          }
        } else if (eventType == 'LegCompleted') {
          final winnerPlayerId = payload['winner_player_id'] as String?;
          if (winnerPlayerId == playerId && inCheckoutRange) {
            successfulCheckouts++;
          }
          inCheckoutRange = false;
        } else if (eventType == 'TurnEnded') {
          inCheckoutRange = false;
        }
      }

      return checkoutAttempts > 0
          ? (successfulCheckouts / checkoutAttempts) * 100
          : null;
    } catch (e) {
      return null;
    }
  }

  /// Highest checkout score for [playerId] in a single game (Dart-side JSON parsing).
  Future<int?> _calculateHighestCheckoutForGame(
      String playerId, String gameId) async {
    try {
      final events = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.equals(gameId)))
          .get();

      int? highestCheckout;

      for (final event in events) {
        if (event.eventType != 'LegCompleted') continue;
        final payload =
            jsonDecode(event.payloadJson) as Map<String, dynamic>;
        final winnerPlayerId = payload['winner_player_id'] as String?;
        final checkoutScore = payload['checkout_score'] as int?;

        if (winnerPlayerId == playerId && checkoutScore != null) {
          if (highestCheckout == null || checkoutScore > highestCheckout) {
            highestCheckout = checkoutScore;
          }
        }
      }

      return highestCheckout;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<PlayerLegSnapshot>> getPlayerLegHistory(
    String playerId, {
    GameType? gameType,
    int? startingScore,
    String? variant,
    int? limit,
  }) async {
    // Minimal implementation — returns empty list (web debug target only)
    return [];
  }

  @override
  Future<List<int>> getPlayerX01StartingScores(String playerId) async {
    // Minimal implementation — returns empty list (web debug target only)
    return [];
  }

  @override
  Future<List<String>> getPlayerCricketVariants(String playerId) async {
    try {
      final sql = '''
        SELECT DISTINCT JSON_EXTRACT(g.config_json, '\$.variant') AS variant
        FROM games g
        JOIN dart_throws dt ON dt.game_id = g.game_id
        WHERE g.game_type = 'cricket'
        AND g.is_complete = 1
        AND dt.player_id = ?
        AND JSON_EXTRACT(g.config_json, '\$.variant') IS NOT NULL
      ''';

      final rows = await _db
          .customSelect(sql, variables: [Variable.withString(playerId)]).get();
      return rows
          .map((r) => r.data['variant'] as String?)
          .whereType<String>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Aggregate X01 checkout stats for [playerId] across all relevant games.
  Future<Map<String, dynamic>> _calculateX01Statistics(
      String playerId, GameType? gameType) async {
    try {
      // Find all completed X01 games for this player
      final query = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.gameId])
        ..join([
          innerJoin(
              _db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
        ])
        ..where(_db.dartThrows.playerId.equals(playerId) &
            _db.games.gameType.equals(GameType.x01.name) &
            _db.games.isComplete.equals(1))
        ..groupBy([_db.dartThrows.gameId]);

      final rows = await query.get();
      final gameIds =
          rows.map((r) => r.read(_db.dartThrows.gameId)).whereType<String>().toList();

      if (gameIds.isEmpty) {
        return {'checkoutPercentage': null, 'highestCheckout': null};
      }

      double checkoutPercentageSum = 0.0;
      int checkoutAttemptCount = 0;
      int? highestCheckout;

      for (final gId in gameIds) {
        final pct = await _calculateCheckoutPercentageForGame(playerId, gId);
        final hc = await _calculateHighestCheckoutForGame(playerId, gId);

        if (pct != null) {
          checkoutPercentageSum += pct;
          checkoutAttemptCount++;
        }
        if (hc != null &&
            (highestCheckout == null || hc > highestCheckout)) {
          highestCheckout = hc;
        }
      }

      final double? avgCheckoutPct = checkoutAttemptCount > 0
          ? checkoutPercentageSum / checkoutAttemptCount
          : null;

      return {
        'checkoutPercentage': avgCheckoutPct,
        'highestCheckout': highestCheckout,
      };
    } catch (e) {
      return {'checkoutPercentage': null, 'highestCheckout': null};
    }
  }

  /// X01 score bucket counts (60+, 100+, 140+, 180) by replaying DartThrown /
  /// TurnEnded events from the given game IDs in Dart code.
  Future<Map<String, int>> _calculateX01ScoreBuckets(
      String playerId, List<String> gameIds) async {
    if (gameIds.isEmpty) {
      return {
        'sixtyPlus': 0,
        'oneHundredPlus': 0,
        'oneFortyPlus': 0,
        'oneEighty': 0,
      };
    }

    int sixtyPlus = 0;
    int oneHundredPlus = 0;
    int oneFortyPlus = 0;
    int oneEighty = 0;

    for (final gId in gameIds) {
      final events = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.equals(gId))
            ..orderBy([(e) => OrderingTerm.asc(e.localSequence)]))
          .get();

      int currentTurnScore = 0;

      for (final event in events) {
        final payload =
            jsonDecode(event.payloadJson) as Map<String, dynamic>;

        if (event.eventType == 'DartThrown') {
          final pid = payload['player_id'] as String?;
          if (pid != playerId) continue;
          final seg = (payload['segment'] as num?)?.toInt();
          final mult = (payload['multiplier'] as num?)?.toInt();
          final score = (seg != null && mult != null)
              ? seg * mult
              : (payload['score'] as num?)?.toInt() ?? 0;
          currentTurnScore += score;
        } else if (event.eventType == 'TurnEnded') {
          final pid = payload['player_id'] as String?;
          if (pid != playerId) {
            currentTurnScore = 0;
            continue;
          }
          final reason = payload['reason'] as String?;
          if (reason != 'bust') {
            final s = currentTurnScore;
            if (s == 180) oneEighty++;
            if (s >= 140) oneFortyPlus++;
            if (s >= 100) oneHundredPlus++;
            if (s >= 60) sixtyPlus++;
          }
          currentTurnScore = 0;
        } else if (event.eventType == 'TurnStarted') {
          currentTurnScore = 0;
        }
      }
    }

    return {
      'sixtyPlus': sixtyPlus,
      'oneHundredPlus': oneHundredPlus,
      'oneFortyPlus': oneFortyPlus,
      'oneEighty': oneEighty,
    };
  }
}
