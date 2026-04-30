// Statistics Repository Drift Implementation
// Concrete implementation of StatisticsRepository interface using Drift

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart' as domain;
import 'package:dart_lodge/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_runner.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_checkout_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_high_score_buckets_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_highest_checkout_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_segment_utils.dart';
import '../database.dart' as drift_db;

class StatisticsRepositoryDrift implements StatisticsRepository {
  final drift_db.AppDatabase _db;

  StatisticsRepositoryDrift(this._db);

  static const _practiceGameTypes = {
    GameType.aroundTheClock,
    GameType.bobs27,
    GameType.shanghai,
    GameType.catch40,
    GameType.checkoutPractice,
  };

  @override
  Future<GameStats> getGameStats(String gameId) async {
    try {
      // Verify game exists and determine game type in a single query
      final gameRow = await (_db.select(_db.games)
            ..where((g) => g.gameId.equals(gameId))
            ..limit(1))
          .getSingleOrNull();

      if (gameRow == null) {
        throw GameNotFoundException(gameId);
      }

      final isX01 = gameRow.gameType == GameType.x01.name;

      // Pre-fetch game events once for X01 projections
      List<domain.GameEvent> gameEvents = [];
      if (isX01) {
        final eventRows = await (_db.select(_db.gameEvents)
              ..where((e) => e.gameId.equals(gameId))
              ..orderBy([(e) => OrderingTerm.asc(e.localSequence)]))
            .get();
        gameEvents = eventRows.map((row) => domain.GameEvent(
          eventId: row.eventId,
          gameId: row.gameId,
          eventType: row.eventType,
          localSequence: row.localSequence,
          occurredAt: DateTime.parse(row.occurredAt),
          payload: jsonDecode(row.payloadJson) as Map<String, dynamic>,
          synced: row.synced == 1,
          actorId: row.actorId,
          globalSequence: row.globalSequence,
          source: EventSource.client,
        )).toList();
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

        // X01-specific stats via projection engine
        int totalOneEighty = 0, totalSixtyPlus = 0, totalHundredPlus = 0, totalFortyPlus = 0;
        int totalCheckoutAttempts = 0, totalSuccessfulCheckouts = 0;
        int? competitorHighestCheckout;

        if (isX01) {
          final playerIds = byPlayer.keys.toList();
          for (final playerId in playerIds) {
            final runner = ProjectionRunner([
              X01CheckoutProjection(),
              X01HighScoreBucketsProjection(),
              X01HighestCheckoutProjection(),
            ]);
            runner.init(ProjectionContext(
              playerId: playerId,
              gameType: GameType.x01,
              inStrategy: 'straight',
              outStrategy: 'double',
              playerIds: playerIds,
            ));
            runner.run(gameEvents);
            final snap = runner.snapshot();

            final buckets = snap['x01.highScoreBuckets'] ?? {};
            totalOneEighty += (buckets['oneEightyTurns'] as int? ?? 0);
            totalFortyPlus += (buckets['oneFortyPlusTurns'] as int? ?? 0);
            totalHundredPlus += (buckets['oneHundredPlusTurns'] as int? ?? 0);
            totalSixtyPlus += (buckets['sixtyPlusTurns'] as int? ?? 0);

            final checkout = snap['x01_checkout'] ?? {};
            totalCheckoutAttempts += (checkout['checkoutAttempts'] as int? ?? 0);
            totalSuccessfulCheckouts += (checkout['successfulCheckouts'] as int? ?? 0);

            final hcSnap = snap['x01_highest_checkout'] ?? {};
            final hc = hcSnap['highestCheckout'] as int?;
            if (hc != null && (competitorHighestCheckout == null || hc > competitorHighestCheckout!)) {
              competitorHighestCheckout = hc;
            }
          }
        }

        final checkoutPercentage = totalCheckoutAttempts > 0
            ? (totalSuccessfulCheckouts / totalCheckoutAttempts) * 100
            : null;

        competitorStats.add(CompetitorStats(
          competitorId: competitorId,
          competitorName: competitor.name,
          byPlayer: playerTurnStats,
          threeDartAverage: threeDartAverage,
          legsWon: legsWon,
          totalDartsThrown: totalDarts,
          checkoutPercentage: checkoutPercentage,
          highestCheckout: competitorHighestCheckout,
          oneEightyTurns: totalOneEighty,
          sixtyPlusTurns: totalSixtyPlus,
          oneHundredPlusTurns: totalHundredPlus,
          oneFortyPlusTurns: totalFortyPlus,
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
    required GameType gameType,
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

      // Build dart count query — always join games to filter by is_complete
      final dartCountQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.dartId.count()])
        ..where(_db.dartThrows.playerId.equals(playerId));
      final joinedDartCountQuery = dartCountQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ])..where(_db.games.isComplete.equals(1));

      // Build avg score query — always join games to filter by is_complete
      final avgScoreQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.score.avg()])
        ..where(_db.dartThrows.playerId.equals(playerId));
      final joinedAvgScoreQuery = avgScoreQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ])..where(_db.games.isComplete.equals(1));

      joinedDartCountQuery.where(_db.games.gameType.equals(gameType.name));
      joinedAvgScoreQuery.where(_db.games.gameType.equals(gameType.name));
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
      final dartCount = dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

      final avgScoreResult = await joinedAvgScoreQuery.getSingle();
      final avgScore = avgScoreResult.read(_db.dartThrows.score.avg()) ?? 0;

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

      // Practice game types: compute stats from event log
      if (_practiceGameTypes.contains(gameType)) {
        return await _computePracticeStatsDrift(
            playerId, gameType, totalGames, dartCount);
      }

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
      if (gameType == GameType.x01) {
        final x01Stats = await _calculateX01Statistics(playerId, gameType);
        checkoutPercentage = x01Stats['checkoutPercentage'] as double?;
        highestCheckout = x01Stats['highestCheckout'] as int?;
      }

      // Score buckets (60+, 100+, 140+, 180) and First 9 PPR — computed from game_events
      Map<String, int> scoreBuckets = {};
      double? firstNinePpr;
      double? bestLegPpr;
      double? bestFirstNinePpr;
      double? avgCheckoutScore;
      double? bestGameCheckoutPercentage;
      if (gameType == GameType.x01) {
        // Collect game IDs for this player
        final gameIdsQuery = _db.selectOnly(_db.dartThrows)
          ..addColumns([_db.dartThrows.gameId])
          ..join([
            innerJoin(
                _db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
          ])
          ..where(_db.dartThrows.playerId.equals(playerId) &
              _db.games.gameType.equals(GameType.x01.name) &
              _db.games.isComplete.equals(1))
          ..groupBy([_db.dartThrows.gameId]);
        final gameIdRows = await gameIdsQuery.get();
        final gameIds = gameIdRows
            .map((r) => r.read(_db.dartThrows.gameId))
            .whereType<String>()
            .toList();
        final x01Stats = await _calculateX01EventStats(playerId, gameIds);
        scoreBuckets = x01Stats.scoreBuckets;
        firstNinePpr = x01Stats.firstNinePpr;
        bestLegPpr = x01Stats.bestLegPpr;
        bestFirstNinePpr = x01Stats.bestFirstNinePpr;
        avgCheckoutScore = x01Stats.avgCheckoutScore;
        bestGameCheckoutPercentage = x01Stats.bestGameCheckoutPercentage;
        highestCheckout = x01Stats.highestCheckout;
      }

      return PlayerStats(
        playerId: playerId,
        gameType: gameType,
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
        firstNinePpr: firstNinePpr,
        bestLegPpr: bestLegPpr,
        bestFirstNinePpr: bestFirstNinePpr,
        avgCheckoutScore: avgCheckoutScore,
        bestGameCheckoutPercentage: bestGameCheckoutPercentage,
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
      {required GameType gameType}) {
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
  }

  @override
  Future<List<PlayerStats>> getLeaderboard({
    required GameType gameType,
    int minGames = 1,
    int limit = 50,
  }) async {
    try {
      final gamesPerPlayerQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.playerId, _db.dartThrows.gameId.count(distinct: true)])
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
        final gameCount = row.read(_db.dartThrows.gameId.count(distinct: true)) ?? 0;
        if (pId != null && gameCount >= minGames) {
          playerGameCounts[pId] = gameCount;
        }
      }

      final leaderboard = await Future.wait(
        playerGameCounts.keys.map((pId) => getPlayerStats(pId, gameType: gameType)),
      );

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

  PlayerStats _createEmptyPlayerStats(String playerId, GameType gameType) {
    return PlayerStats(
      playerId: playerId,
      gameType: gameType,
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

      final sql = '''
        SELECT
          COUNT(*) AS turn_count,
          SUM(CASE WHEN JSON_EXTRACT(payload_json, '\$.reason') = 'bust' THEN 1 ELSE 0 END) AS bust_count
        FROM game_events
        WHERE event_type = 'TurnEnded'
        AND JSON_EXTRACT(payload_json, '\$.player_id') = ?
        $scopeFilter
      ''';

      final rows = await _db.customSelect(
        sql,
        variables: [for (final a in args) Variable.withString(a)],
      ).get();

      final bustCount = (rows.first.data['bust_count'] as num? ?? 0).toInt();
      final turnCount = (rows.first.data['turn_count'] as num? ?? 0).toInt();

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
    try {
      // 1. Find completed games for this player
      final gamesQuery = _db.select(_db.games).join([
        innerJoin(_db.competitors,
            _db.competitors.gameId.equalsExp(_db.games.gameId)),
        innerJoin(_db.competitorPlayers,
            _db.competitorPlayers.competitorId
                .equalsExp(_db.competitors.competitorId)),
      ])
        ..where(_db.competitorPlayers.playerId.equals(playerId) &
            _db.games.isComplete.equals(1))
        ..orderBy([OrderingTerm.asc(_db.games.startTime)]);

      if (gameType != null) {
        gamesQuery.where(_db.games.gameType.equals(gameType.name));
      }

      final gamesResult = await gamesQuery.get();

      // Deduplicate (a player may appear via multiple competitors in theory)
      final seen = <String>{};
      final gameRows = <drift_db.Game>[];
      for (final row in gamesResult) {
        final g = row.readTable(_db.games);
        if (seen.add(g.gameId)) gameRows.add(g);
      }

      // Filter by startingScore / variant in Dart (config_json is opaque)
      var filtered = gameRows;
      if (startingScore != null) {
        filtered = filtered.where((g) {
          try {
            final cfg = jsonDecode(g.configJson) as Map<String, dynamic>;
            return cfg['starting_score'] == startingScore;
          } catch (_) {
            return false;
          }
        }).toList();
      }
      if (variant != null) {
        filtered = filtered.where((g) {
          try {
            final cfg = jsonDecode(g.configJson) as Map<String, dynamic>;
            return cfg['variant'] == variant;
          } catch (_) {
            return false;
          }
        }).toList();
      }

      if (filtered.isEmpty) return [];

      final isPracticeGame =
          gameType != null && _practiceGameTypes.contains(gameType);

      final List<PlayerLegSnapshot> snapshots = [];
      int legIndex = 0;

      for (final gameRow in filtered) {
        final gameId = gameRow.gameId;
        final gameDate =
            DateTime.tryParse(gameRow.startTime) ?? DateTime.now();
        int? gamStartingScore;
        try {
          final cfg = jsonDecode(gameRow.configJson) as Map<String, dynamic>;
          gamStartingScore = cfg['starting_score'] as int?;
        } catch (_) {}

        // Get events for this game
        final events = await (_db.select(_db.gameEvents)
              ..where((e) => e.gameId.equals(gameId))
              ..orderBy([(e) => OrderingTerm.asc(e.localSequence)]))
            .get();

        // Scan events to accumulate per-leg stats
        int legDartCount = 0;
        int legScoreTotal = 0;
        int legTotalMarks = 0;
        int legTotalTurns = 0;
        int currentTurnMarks = 0;

        // ATC hit-rate tracking
        int atcDartsAtTarget = 0;
        int atcHits = 0;
        int atcCurrentTarget = 1;
        bool atcInPlayerTurn = false;

        for (final event in events) {
          final payload =
              jsonDecode(event.payloadJson) as Map<String, dynamic>;

          switch (event.eventType) {
            case 'TurnStarted':
              final pid = payload['player_id'] as String?;
              if (pid != playerId) break;
              currentTurnMarks = 0;
              atcInPlayerTurn = true;
            case 'DartThrown':
              final pid = payload['player_id'] as String?;
              if (pid != playerId) break;
              legDartCount++;
              final seg = (payload['segment'] as num?)?.toInt();
              final mult = (payload['multiplier'] as num?)?.toInt();
              final score = (seg != null && mult != null)
                  ? seg * mult
                  : (payload['score'] as num?)?.toInt() ?? 0;
              legScoreTotal += score;
              // Cricket marks
              final rawSeg = payload['segment'];
              if (rawSeg is String) {
                currentTurnMarks += cricketMarksForSegment(rawSeg);
              } else if (rawSeg is num) {
                final segInt = rawSeg.toInt();
                final multInt =
                    (payload['multiplier'] as num?)?.toInt() ?? 1;
                if (kCricketTargets.contains(segInt)) {
                  currentTurnMarks += multInt.clamp(0, 3);
                }
              }
              // ATC hit tracking
              if (isPracticeGame &&
                  gameType == GameType.aroundTheClock &&
                  atcInPlayerTurn) {
                final segVal =
                    (payload['segment'] as num?)?.toInt() ?? 0;
                if (atcCurrentTarget <= 20) {
                  atcDartsAtTarget++;
                  if (segVal == atcCurrentTarget) {
                    atcHits++;
                    atcCurrentTarget++;
                  }
                }
              }
            case 'TurnEnded':
              final pid = payload['player_id'] as String?;
              if (pid != playerId) break;
              legTotalMarks += currentTurnMarks;
              legTotalTurns++;
              currentTurnMarks = 0;
              atcInPlayerTurn = false;
            case 'LegCompleted':
              legIndex++;
              final ppr = legDartCount > 0
                  ? (legScoreTotal / legDartCount) * 3
                  : 0.0;
              final mpt = legTotalTurns > 0
                  ? legTotalMarks / legTotalTurns
                  : null;

              final checkoutAttempts =
                  payload['checkout_attempts'] as int?;
              final checkoutScore = payload['checkout_score'] as int?;
              double? checkoutPct;
              if (checkoutAttempts != null &&
                  checkoutAttempts > 0 &&
                  checkoutScore != null) {
                checkoutPct = (1 / checkoutAttempts) * 100;
              }

              double? practiceScore;
              if (isPracticeGame) {
                if (gameType == GameType.aroundTheClock) {
                  practiceScore = atcDartsAtTarget > 0
                      ? atcHits / atcDartsAtTarget
                      : null;
                } else {
                  practiceScore = legScoreTotal.toDouble();
                }
              }

              snapshots.add(PlayerLegSnapshot(
                gameId: gameId,
                legIndex: legIndex,
                gameDate: gameDate,
                ppr: ppr,
                checkoutPct: checkoutPct,
                startingScore: gamStartingScore,
                mpt: mpt,
                practiceScore: practiceScore,
              ));

              // Reset for next leg
              legDartCount = 0;
              legScoreTotal = 0;
              legTotalMarks = 0;
              legTotalTurns = 0;
              currentTurnMarks = 0;
              atcDartsAtTarget = 0;
              atcHits = 0;
              atcCurrentTarget = 1;
              atcInPlayerTurn = false;
          }
        }
      }

      // Apply limit by taking last N items (most recent legs)
      if (limit != null && snapshots.length > limit) {
        return snapshots.sublist(snapshots.length - limit);
      }
      return snapshots;
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve leg history: ${e.toString()}');
    }
  }

  @override
  Future<List<int>> getPlayerX01StartingScores(String playerId) async {
    try {
      final sql = '''
        SELECT DISTINCT g.config_json
        FROM games g
        JOIN competitors c ON g.game_id = c.game_id
        JOIN competitor_players cp ON c.competitor_id = cp.competitor_id
        WHERE cp.player_id = ? AND g.game_type = ? AND g.is_complete = 1
      ''';

      final rows = await _db.customSelect(sql, variables: [
        Variable.withString(playerId),
        Variable.withString(GameType.x01.name),
      ]).get();

      final Set<int> scores = {};
      for (final row in rows) {
        final configJson = row.data['config_json'] as String?;
        if (configJson == null) continue;
        try {
          final cfg = jsonDecode(configJson) as Map<String, dynamic>;
          final score = cfg['starting_score'] as int?;
          if (score != null) scores.add(score);
        } catch (_) {}
      }

      return scores.toList()..sort();
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve starting scores: ${e.toString()}');
    }
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

      int totalAttempts = 0;
      int totalSuccesses = 0;
      int? highestCheckout;

      for (final gId in gameIds) {
        final hc = await _calculateHighestCheckoutForGame(playerId, gId);
        if (hc != null &&
            (highestCheckout == null || hc > highestCheckout)) {
          highestCheckout = hc;
        }

        // Accumulate raw attempts/successes for weighted checkout percentage
        final counts = await _getCheckoutCountsForGame(playerId, gId);
        totalAttempts += counts.attempts;
        totalSuccesses += counts.successes;
      }

      final double? checkoutPercentage = totalAttempts > 0
          ? (totalSuccesses / totalAttempts) * 100
          : null;

      return {
        'checkoutPercentage': checkoutPercentage,
        'highestCheckout': highestCheckout,
      };
    } catch (e) {
      return {'checkoutPercentage': null, 'highestCheckout': null};
    }
  }

  /// Returns raw checkout attempt and success counts for a single game.
  Future<({int attempts, int successes})> _getCheckoutCountsForGame(
      String playerId, String gameId) async {
    try {
      final events = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.equals(gameId))
            ..orderBy([(e) => OrderingTerm.asc(e.localSequence)]))
          .get();

      if (events.isEmpty) return (attempts: 0, successes: 0);

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

      return (attempts: checkoutAttempts, successes: successfulCheckouts);
    } catch (e) {
      return (attempts: 0, successes: 0);
    }
  }

  /// Computes X01 score buckets, First-9 PPR, and best-of metrics
  /// in a single pass over game events for [gameIds].
  Future<({
    Map<String, int> scoreBuckets,
    double? firstNinePpr,
    double? bestLegPpr,
    double? bestFirstNinePpr,
    double? avgCheckoutScore,
    double? bestGameCheckoutPercentage,
    int? highestCheckout,
  })> _calculateX01EventStats(String playerId, List<String> gameIds) async {
    const emptyBuckets = {
      'sixtyPlus': 0,
      'oneHundredPlus': 0,
      'oneFortyPlus': 0,
      'oneEighty': 0,
    };
    if (gameIds.isEmpty) {
      return (
        scoreBuckets: emptyBuckets,
        firstNinePpr: null,
        bestLegPpr: null,
        bestFirstNinePpr: null,
        avgCheckoutScore: null,
        bestGameCheckoutPercentage: null,
        highestCheckout: null,
      );
    }

    // Score bucket accumulators
    int sixtyPlus = 0;
    int oneHundredPlus = 0;
    int oneFortyPlus = 0;
    int oneEighty = 0;

    // First-nine (avg) accumulators
    int totalFirstNinePoints = 0;
    int totalFirstNineLegs = 0;

    // Best leg PPR accumulators (per-leg; null legStartingScore = not yet captured)
    int? legStartingScore;
    int legDartsCount = 0;
    int legFirstNineScore = 0;
    double? bestLegPpr;
    double? bestFirstNinePpr;

    // Avg checkout score and highest checkout
    int checkoutScoreSum = 0;
    int checkoutCount = 0;
    int lastPlayerTurnStartingScore = 0;
    int? highestCheckout;

    // Best game CO%
    int gameAttempts = 0;
    int gameSuccesses = 0;
    double? bestGameCo;

    // Shared per-turn state
    int currentTurnScore = 0;
    int turnIndexInLeg = 0;
    bool inFirstNine = false;

    // Ordered by gameId then localSequence so per-game state doesn't bleed.
    final allEvents = await (_db.select(_db.gameEvents)
          ..where((e) => e.gameId.isIn(gameIds))
          ..orderBy([
            (e) => OrderingTerm.asc(e.gameId),
            (e) => OrderingTerm.asc(e.localSequence),
          ]))
        .get();

    String? currentGameId;

    for (final event in allEvents) {
      if (event.gameId != currentGameId) {
        currentGameId = event.gameId;
        currentTurnScore = 0;
        turnIndexInLeg = 0;
        inFirstNine = false;
        legStartingScore = null;
        legDartsCount = 0;
        legFirstNineScore = 0;
        // Note: gameAttempts/gameSuccesses reset on GameCompleted, not on new game,
        // but since we order by gameId this is fine — GameCompleted fires before next game.
      }

      final payload = jsonDecode(event.payloadJson) as Map<String, dynamic>;

      if (event.eventType == 'TurnStarted') {
        final pid = payload['player_id'] as String?;
        currentTurnScore = 0;
        inFirstNine = false;
        if (pid == playerId) {
          turnIndexInLeg++;
          inFirstNine = turnIndexInLeg <= 3;

          final startingScore = (payload['starting_score'] as num?)?.toInt();
          legStartingScore ??= startingScore ?? 0;
          lastPlayerTurnStartingScore = startingScore ?? 0;
          if ((startingScore ?? 9999) <= 170) gameAttempts++;
        }
      } else if (event.eventType == 'DartThrown') {
        final pid = payload['player_id'] as String?;
        if (pid != playerId) continue;
        final seg = (payload['segment'] as num?)?.toInt();
        final mult = (payload['multiplier'] as num?)?.toInt();
        final score = (seg != null && mult != null)
            ? seg * mult
            : (payload['score'] as num?)?.toInt() ?? 0;
        currentTurnScore += score;
        legDartsCount++;
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
          if (inFirstNine) totalFirstNinePoints += s;
          if (inFirstNine) legFirstNineScore += s;
        }
        currentTurnScore = 0;
      } else if (event.eventType == 'LegCompleted') {
        final winnerId = payload['winner_player_id'] as String?;

        if (winnerId == playerId) {
          // Best game CO%
          gameSuccesses++;

          // Avg checkout score
          checkoutScoreSum += lastPlayerTurnStartingScore;
          checkoutCount++;

          // Highest checkout
          if (lastPlayerTurnStartingScore > 0 &&
              (highestCheckout == null ||
                  lastPlayerTurnStartingScore > highestCheckout!)) {
            highestCheckout = lastPlayerTurnStartingScore;
          }

          // Best leg PPR
          if (legStartingScore != null && legDartsCount > 0) {
            final legPpr = legStartingScore! / legDartsCount * 3;
            bestLegPpr =
                bestLegPpr == null ? legPpr : (legPpr > bestLegPpr! ? legPpr : bestLegPpr!);
            if (turnIndexInLeg >= 3) {
              final f9ppr = legFirstNineScore / 9 * 3;
              bestFirstNinePpr = bestFirstNinePpr == null
                  ? f9ppr
                  : (f9ppr > bestFirstNinePpr! ? f9ppr : bestFirstNinePpr!);
            }
          }
        }

        // Reset per-leg state (all legs, not just won ones)
        if (turnIndexInLeg >= 1) totalFirstNineLegs++;
        turnIndexInLeg = 0;
        inFirstNine = false;
        currentTurnScore = 0;
        legStartingScore = null;
        legDartsCount = 0;
        legFirstNineScore = 0;
      } else if (event.eventType == 'GameCompleted') {
        if (gameAttempts > 0) {
          final gameCo = gameSuccesses / gameAttempts * 100;
          if (bestGameCo == null || gameCo > bestGameCo!) {
            bestGameCo = gameCo;
          }
        }
        gameAttempts = 0;
        gameSuccesses = 0;
      }
    }

    final firstNinePpr = totalFirstNineLegs > 0
        ? (totalFirstNinePoints / (totalFirstNineLegs * 9)) * 3
        : null;

    return (
      scoreBuckets: {
        'sixtyPlus': sixtyPlus,
        'oneHundredPlus': oneHundredPlus,
        'oneFortyPlus': oneFortyPlus,
        'oneEighty': oneEighty,
      },
      firstNinePpr: firstNinePpr,
      bestLegPpr: bestLegPpr,
      bestFirstNinePpr: bestFirstNinePpr,
      avgCheckoutScore:
          checkoutCount > 0 ? checkoutScoreSum / checkoutCount : null,
      bestGameCheckoutPercentage: bestGameCo,
      highestCheckout: highestCheckout,
    );
  }

  // ── Practice statistics ────────────────────────────────────────────────────

  PlayerStats _emptyPracticeStats(
          String playerId, GameType gameType, int totalGames, int totalDartsThrown) =>
      PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: totalGames,
        gamesWon: 0,
        winRate: 0.0,
        threeDartAverage: 0.0,
        highestTurnScore: 0,
        totalDartsThrown: totalDartsThrown,
        dartsPerLeg: 0.0,
        bustRate: 0.0,
      );

  Future<PlayerStats> _computePracticeStatsDrift(
    String playerId,
    GameType gameType,
    int totalGames,
    int totalDartsThrown,
  ) async {
    // Fetch game IDs where this player participated with the given game type
    final gameIdsQuery = _db.selectOnly(_db.dartThrows)
      ..addColumns([_db.dartThrows.gameId])
      ..join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ])
      ..where(_db.dartThrows.playerId.equals(playerId) &
          _db.games.gameType.equals(gameType.name))
      ..groupBy([_db.dartThrows.gameId]);
    final gameIdRows = await gameIdsQuery.get();
    final gameIds = gameIdRows
        .map((r) => r.read(_db.dartThrows.gameId))
        .whereType<String>()
        .toList();

    if (gameIds.isEmpty) {
      return _emptyPracticeStats(playerId, gameType, totalGames, totalDartsThrown);
    }

    // Read variant from the most-recently-started game's config_json
    String variant = 'standard';
    final gameRow = await (_db.select(_db.games)
          ..where((g) => g.gameId.isIn(gameIds))
          ..orderBy([(g) => OrderingTerm.desc(g.startTime)])
          ..limit(1))
        .getSingleOrNull();
    if (gameRow != null) {
      try {
        final cfg = jsonDecode(gameRow.configJson) as Map<String, dynamic>;
        variant = cfg['variant'] as String? ?? 'standard';
      } catch (_) {}
    }

    // Fetch all events for those games ordered by local_sequence
    final events = await (_db.select(_db.gameEvents)
          ..where((e) => e.gameId.isIn(gameIds))
          ..orderBy([(e) => OrderingTerm.asc(e.localSequence)]))
        .get();

    return switch (gameType) {
      GameType.aroundTheClock => _computeAtcStatsDrift(
          playerId, events, variant, totalGames, totalDartsThrown),
      _ => _emptyPracticeStats(playerId, gameType, totalGames, totalDartsThrown),
    };
  }

  /// Around the Clock stats computed from the event log.
  /// ATC is solo practice — no cross-player filtering needed; all events in
  /// the list already belong to this player's games.
  PlayerStats _computeAtcStatsDrift(
    String playerId,
    List<drift_db.GameEvent> events,
    String variant,
    int totalGames,
    int totalDartsThrown,
  ) {

    int totalDartsAtTargets = 0;
    int totalHits = 0;
    int completions = 0;
    int totalTurnsForCompletions = 0;
    int? bestTurns;
    final Map<int, int> segHits = {};
    final Map<int, int> segAttempts = {};

    int currentTarget = 1;
    int gameTurns = 0;
    bool inPlayerTurn = false;

    for (final event in events) {
      switch (event.eventType) {
        case 'TurnStarted':
          inPlayerTurn = true;
          gameTurns++;
        case 'DartThrown':
          if (!inPlayerTurn) break;
          final payload =
              jsonDecode(event.payloadJson) as Map<String, dynamic>;
          final seg = (payload['segment'] as num?)?.toInt() ?? 0;
          final mult = (payload['multiplier'] as num?)?.toInt() ?? 1;
          if (currentTarget <= 20) {
            totalDartsAtTargets++;
            segAttempts[currentTarget] = (segAttempts[currentTarget] ?? 0) + 1;
            final hit = variant == 'doublesOnly'
                ? (seg == currentTarget && mult == 2)
                : (seg == currentTarget);
            if (hit) {
              totalHits++;
              segHits[currentTarget] = (segHits[currentTarget] ?? 0) + 1;
              currentTarget++;
            }
          }
        case 'TurnEnded':
          inPlayerTurn = false;
        case 'LegCompleted':
          if (currentTarget > 20) {
            completions++;
            totalTurnsForCompletions += gameTurns;
            if (bestTurns == null || gameTurns < bestTurns) {
              bestTurns = gameTurns;
            }
          }
          currentTarget = 1;
          gameTurns = 0;
          inPlayerTurn = false;
        case 'GameCompleted':
          // ATC is a 1-leg practice game: GameCompleted signals drill completion
          if (currentTarget > 20) {
            completions++;
            totalTurnsForCompletions += gameTurns;
            if (bestTurns == null || gameTurns < bestTurns) {
              bestTurns = gameTurns;
            }
          }
          currentTarget = 1;
          gameTurns = 0;
          inPlayerTurn = false;
      }
    }

    final hitRate =
        totalDartsAtTargets > 0 ? totalHits / totalDartsAtTargets : null;
    final avgTurns =
        completions > 0 ? totalTurnsForCompletions / completions : null;

    return _emptyPracticeStats(playerId, GameType.aroundTheClock, totalGames, totalDartsThrown)
        .copyWith(
      atcCompletions: completions,
      atcHitRate: hitRate,
      atcAvgTurns: avgTurns,
      atcBestTurns: bestTurns,
      atcSegmentHits: segHits,
      atcSegmentAttempts: segAttempts,
    );
  }
}
