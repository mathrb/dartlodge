// Statistics Repository Implementation
// Concrete implementation of StatisticsRepository interface
// Statistics are computed as projections from game events and dart throws

import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' show min;
import '../../domain/entities/player_stats.dart';
import '../../domain/entities/game_stats.dart';
import '../../domain/repositories/statistics_repository.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/core/error/repository_exception.dart' hide DatabaseException;
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_runner.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_average_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_bust_rate_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_checkout_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_darts_per_leg_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_double_out_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_first_dart_in_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_highest_checkout_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_highest_turn_score_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_legs_projection.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_win_rate_projection.dart';


class StatisticsRepositoryImpl implements StatisticsRepository {
  final Database _db;

  StatisticsRepositoryImpl(this._db);

  @override
  Future<GameStats> getGameStats(String gameId) async {
    try {
      // Verify game exists
      final gameResult = await _db.query(
        'games',
        where: 'game_id = ?',
        whereArgs: [gameId],
        limit: 1,
      );

      if (gameResult.isEmpty) {
        throw GameNotFoundException(gameId);
      }

      // Get all dart throws for this game
      final dartThrows = await _db.query(
        'dart_throws',
        where: 'game_id = ?',
        whereArgs: [gameId],
        orderBy: 'turn_number ASC, dart_number ASC',
      );

      if (dartThrows.isEmpty) {
        return GameStats(
          gameId: gameId,
          byCompetitor: [],
        );
      }

      // Group by competitor
      final Map<String, List<Map<String, dynamic>>> byCompetitor = {};
      for (final throwData in dartThrows) {
        final competitorId = throwData['competitor_id'] as String;
        byCompetitor.putIfAbsent(competitorId, () => []).add(throwData);
      }

      // Build competitor stats
      final List<CompetitorStats> competitorStats = [];
      for (final entry in byCompetitor.entries) {
        final competitorId = entry.key;
        final throws = entry.value;

        // Get competitor info
        final competitorData = await _db.query(
          'competitors',
          where: 'competitor_id = ?',
          whereArgs: [competitorId],
          limit: 1,
        );

        if (competitorData.isEmpty) continue;

        final competitorName = competitorData.first['name'] as String;

        // Group by player within competitor
        final Map<String, List<Map<String, dynamic>>> byPlayer = {};
        for (final throwData in throws) {
          final playerId = throwData['player_id'] as String;
          byPlayer.putIfAbsent(playerId, () => []).add(throwData);
        }

        // Calculate player turn stats
        final List<PlayerTurnStats> playerTurnStats = [];
        for (final playerEntry in byPlayer.entries) {
          final playerId = playerEntry.key;
          final playerThrows = playerEntry.value;

          int playerDarts = playerThrows.length;
          int playerScore = playerThrows.fold(0, (sum, throwData) => sum + (throwData['score'] as int));
          double playerAvg = playerDarts > 0 ? (playerScore / playerDarts) * 3 : 0.0;

          playerTurnStats.add(PlayerTurnStats(
            playerId: playerId,
            threeDartAverage: playerAvg,
            dartsThrown: playerDarts,
          ));
        }

        // Calculate competitor totals
        int totalDarts = throws.length;
        int totalScore = throws.fold(0, (sum, throwData) => sum + (throwData['score'] as int));
        double threeDartAverage = totalDarts > 0 ? (totalScore / totalDarts) * 3 : 0.0;

        // Get legs won from game events
        final legsWon = await _getLegsWonForCompetitor(competitorId, gameId);

        competitorStats.add(CompetitorStats(
          competitorId: competitorId,
          competitorName: competitorName,
          byPlayer: playerTurnStats,
          threeDartAverage: threeDartAverage,
          legsWon: legsWon,
          totalDartsThrown: totalDarts,
        ));
      }

      return GameStats(
        gameId: gameId,
        byCompetitor: competitorStats,
      );
    } on RepositoryException {
      rethrow;
    } on DatabaseException catch (e) {
      print('Database error in getGameStats: ${e.toString()}');
      throw StatisticsException('Failed to retrieve game statistics: ${e.toString()}');
    } catch (e) {
      print('Unexpected error in getGameStats: ${e.toString()}');
      throw StatisticsException('Failed to retrieve game statistics');
    }
  }

  @override
  Stream<GameStats> watchGameStats(String gameId) {
    return Stream.periodic(const Duration(seconds: 5), (_) {})
      .asyncMap((_) async => getGameStats(gameId))
      .distinct()
      .handleError((error) {
        if (error is RepositoryException) throw error;
        throw StatisticsException('Failed to watch game statistics: ${error.toString()}');
      });
  }

  @override
  Future<PlayerStats> getPlayerStats(
    String playerId, {
    GameType? gameType,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      // Verify player exists
      final playerResult = await _db.query(
        'players',
        where: 'player_id = ?',
        whereArgs: [playerId],
        limit: 1,
      );

      if (playerResult.isEmpty) {
        throw PlayerNotFoundException(playerId);
      }

      final stats = await _buildPlayerStatsViaProjection(
        playerId,
        gameType: gameType,
        from: from,
        to: to,
      );
      return stats ?? _createEmptyPlayerStats(playerId, gameType);
    } on RepositoryException {
      rethrow;
    } on DatabaseException catch (e) {
      throw StatisticsException('Failed to retrieve player statistics: ${e.toString()}');
    } catch (e) {
      throw StatisticsException('Failed to retrieve player statistics');
    }
  }

  @override
  Future<PlayerStats> getPlayerStatsForGame(String playerId, String gameId) async {
    try {
      // Verify game exists and player participated
      final participationCheck = await _db.query(
        'dart_throws',
        where: 'player_id = ? AND game_id = ?',
        whereArgs: [playerId, gameId],
        limit: 1,
      );

      if (participationCheck.isEmpty) {
        // Check if game exists first to throw the right exception
        final gameCheck = await _db.query(
          'games',
          where: 'game_id = ?',
          whereArgs: [gameId],
          limit: 1,
        );
        
        if (gameCheck.isEmpty) {
          throw GameNotFoundException(gameId);
        } else {
          throw PlayerNotFoundException(playerId);
        }
      }

      // Get game type
      final gameResult = await _db.query(
        'games',
        where: 'game_id = ?',
        whereArgs: [gameId],
        limit: 1,
      );

      if (gameResult.isEmpty) {
        throw GameNotFoundException(gameId);
      }

      final gameType = GameType.values.firstWhere(
        (type) => type.name == gameResult.first['game_type'] as String,
        orElse: () => GameType.x01,
      );

      // Get all dart throws for this player in this game
      final dartThrows = await _db.query(
        'dart_throws',
        where: 'player_id = ? AND game_id = ?',
        whereArgs: [playerId, gameId],
        orderBy: 'turn_number ASC, dart_number ASC',
      );

      if (dartThrows.isEmpty) {
        return _createEmptyPlayerStats(playerId, gameType);
      }

      // Calculate statistics for this game only
      int totalDarts = dartThrows.length;
      int totalScore = dartThrows.fold(0, (sum, throwData) => sum + (throwData['score'] as int));
      double threeDartAverage = totalDarts > 0 ? (totalScore / totalDarts) * 3 : 0.0;

      // Calculate game-specific metrics
      final highestTurnScore = await _calculateHighestTurnScore(playerId, gameType, gameId: gameId);
      final checkoutPercentage = await _calculateCheckoutPercentageForGame(playerId, gameId);
      final highestCheckout = await _calculateHighestCheckoutForGame(playerId, gameId);
      final bustRate = await _calculateBustRate(playerId, gameType, gameId: gameId);

      // For per-game stats, legs won is either 0 or 1 (assuming single leg games for now)
      final legsWon = await _getLegsWonForPlayerInGame(playerId, gameId);
      double dartsPerLeg = legsWon > 0 ? totalDarts / legsWon : 0.0;

      return PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: 1, // This is for a single game
        gamesWon: legsWon > 0 ? 1 : 0, // Simplified for per-game stats
        winRate: legsWon > 0 ? 1.0 : 0.0,
        threeDartAverage: threeDartAverage,
        checkoutPercentage: checkoutPercentage,
        highestCheckout: highestCheckout,
        highestTurnScore: highestTurnScore,
        totalDartsThrown: totalDarts,
        dartsPerLeg: dartsPerLeg,
        bustRate: bustRate,
      );
    } on RepositoryException {
      rethrow;
    } on DatabaseException catch (e) {
      print('Database error in getPlayerStatsForGame: ${e.toString()}');
      throw StatisticsException('Failed to retrieve player game statistics: ${e.toString()}');
    } catch (e) {
      print('Unexpected error in getPlayerStatsForGame: ${e.toString()}');
      throw StatisticsException('Failed to retrieve player game statistics');
    }
  }

  @override
  Stream<PlayerStats> watchPlayerStats(String playerId, {GameType? gameType}) {
    return Stream.periodic(const Duration(seconds: 5), (_) {})
      .asyncMap((_) async {
        final stats = await _buildPlayerStatsViaProjection(playerId, gameType: gameType);
        return stats ?? _createEmptyPlayerStats(playerId, gameType);
      })
      .distinct()
      .handleError((error) {
        if (error is RepositoryException) throw error;
        throw StatisticsException('Failed to watch player statistics: ${error.toString()}');
      });
  }

  @override
  Future<List<PlayerStats>> getLeaderboard({
    required GameType gameType,
    int minGames = 1,
    int limit = 50,
  }) async {
    try {
      // Get all players with at least minGames games
      final playersQuery = '''
        SELECT DISTINCT player_id
        FROM dart_throws
        WHERE game_id IN (
          SELECT game_id FROM games WHERE game_type = ?
        )
        GROUP BY player_id
        HAVING COUNT(DISTINCT game_id) >= ?
      ''';

      final playersResult = await _db.rawQuery(playersQuery, [gameType.name, minGames]);

      // Calculate stats for each player
      final List<PlayerStats> leaderboard = [];
      for (final playerRow in playersResult) {
        final playerId = playerRow['player_id'] as String;
        final stats = await getPlayerStats(playerId, gameType: gameType);
        leaderboard.add(stats);
      }

      // Sort by 3-dart average descending
      leaderboard.sort((a, b) => b.threeDartAverage.compareTo(a.threeDartAverage));

      // Apply limit
      return leaderboard.take(limit).toList();
    } on RepositoryException {
      rethrow;
    } on DatabaseException catch (e) {
      print('Database error in getLeaderboard: ${e.toString()}');
      throw StatisticsException('Failed to retrieve leaderboard: ${e.toString()}');
    } catch (e) {
      print('Unexpected error in getLeaderboard: ${e.toString()}');
      throw StatisticsException('Failed to retrieve leaderboard');
    }
  }

  // Helper method to create empty player stats
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

  Future<PlayerStats?> _buildPlayerStatsViaProjection(
    String playerId, {
    GameType? gameType,
    DateTime? from,
    DateTime? to,
  }) async {
    // 1. Query games involving this player
    String gamesQuery = '''
      SELECT DISTINCT g.game_id, g.config_json, g.game_type, g.start_time
      FROM games g
      JOIN competitors c ON g.game_id = c.game_id
      JOIN competitor_players cp ON c.competitor_id = cp.competitor_id
      WHERE cp.player_id = ?
    ''';
    final List<dynamic> gamesArgs = [playerId];

    if (gameType != null) {
      gamesQuery += ' AND g.game_type = ?';
      gamesArgs.add(gameType.name);
    }
    if (from != null) {
      gamesQuery += ' AND g.start_time >= ?';
      gamesArgs.add(from.toIso8601String());
    }
    if (to != null) {
      gamesQuery += ' AND g.start_time <= ?';
      gamesArgs.add(to.toIso8601String());
    }

    final gamesResult = await _db.rawQuery(gamesQuery, gamesArgs);
    if (gamesResult.isEmpty) return null;

    final gameIds = gamesResult.map((r) => r['game_id'] as String).toList();
    final totalGames = gameIds.length;
    final effectiveGameType = gameType ?? GameType.x01;

    // 2. Get totalDartsThrown from dart_throws (SQL fallback — projections
    //    count DartThrown events, but contract tests insert throws without events)
    final placeholders = gameIds.map((_) => '?').join(',');
    final throwsResult = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM dart_throws WHERE player_id = ? AND game_id IN ($placeholders)',
      [playerId, ...gameIds],
    );
    final totalDartsThrown = throwsResult.first['cnt'] as int? ?? 0;

    // 3. Query all events for those games ordered by local_sequence
    final eventsResult = await _db.rawQuery(
      'SELECT * FROM game_events WHERE game_id IN ($placeholders) ORDER BY local_sequence ASC',
      gameIds,
    );
    final events = eventsResult.map((row) => GameEvent.fromJson(row)).toList();

    // 4. Extract in/out strategy from most recent game's config_json
    String inStrategy = 'straight';
    String outStrategy = 'double';
    final sortedGames = [...gamesResult]
      ..sort((a, b) => (b['start_time'] as String).compareTo(a['start_time'] as String));
    final latestConfigJson = sortedGames.first['config_json'] as String?;
    if (latestConfigJson != null) {
      try {
        final config = jsonDecode(latestConfigJson) as Map<String, dynamic>;
        inStrategy = config['in_strategy'] as String? ?? inStrategy;
        outStrategy = config['out_strategy'] as String? ?? outStrategy;
      } catch (_) {}
    }

    // 5. Build context and run projections
    final context = ProjectionContext(
      playerId: playerId,
      gameType: effectiveGameType,
      inStrategy: inStrategy,
      outStrategy: outStrategy,
      playerIds: [playerId],
    );

    final runner = ProjectionRunner([
      X01AverageProjection(),
      X01BustRateProjection(),
      X01CheckoutProjection(),
      X01DartsPerLegProjection(),
      X01DoubleOutProjection(),
      X01FirstDartInProjection(),
      X01HighestCheckoutProjection(),
      X01HighestTurnScoreProjection(),
      X01LegsProjection(),
      X01WinRateProjection(),
    ]);

    runner.init(context);
    runner.run(events);

    // 6. Handle DartCorrected events
    final correctedEvents = events.where((e) => e.eventType == 'DartCorrected').toList();
    if (correctedEvents.isNotEmpty) {
      final minSeq = correctedEvents.map((e) => e.localSequence).reduce(min);
      runner.replayFrom(events, minSeq);
    }

    // 7. Map snapshots to PlayerStats
    final snap = runner.snapshot();
    final avgSnap = snap['x01_average'] ?? {};
    final bustSnap = snap['x01_bust_rate'] ?? {};
    final checkoutSnap = snap['x01_checkout'] ?? {};
    final dartsPerLegSnap = snap['x01.dartsPerLeg'] ?? {};
    final highestCheckoutSnap = snap['x01_highest_checkout'] ?? {};
    final highestTurnSnap = snap['x01_highest_turn_score'] ?? {};
    final winSnap = snap['x01.winRate'] ?? {};

    return PlayerStats(
      playerId: playerId,
      gameType: effectiveGameType,
      totalGames: totalGames,
      totalDartsThrown: totalDartsThrown,
      threeDartAverage: (avgSnap['threeDartAverage'] as num?)?.toDouble() ?? 0.0,
      bustRate: (bustSnap['bustRate'] as num?)?.toDouble() ?? 0.0,
      checkoutPercentage: (checkoutSnap['checkoutPercentage'] as num?)?.toDouble(),
      highestCheckout: highestCheckoutSnap['highestCheckout'] as int?,
      highestTurnScore: highestTurnSnap['highestTurnScore'] as int? ?? 0,
      dartsPerLeg: (dartsPerLegSnap['dartsPerLeg'] as num?)?.toDouble() ?? 0.0,
      winRate: (winSnap['winRate'] as num?)?.toDouble() ?? 0.0,
      gamesWon: winSnap['gamesWon'] as int? ?? 0,
    );
  }

  // Helper method to get legs won for a competitor
  Future<int> _getLegsWonForCompetitor(String competitorId, String gameId) async {
    try {
      // Look for LegCompleted events where this competitor is the winner
      final events = await _db.query(
        'game_events',
        where: 'game_id = ? AND event_type = ?',
        whereArgs: [gameId, 'LegCompleted'],
      );

      int legsWon = 0;
      for (final event in events) {
        final payload = jsonDecode(event['payload_json'] as String) as Map<String, dynamic>;
        if (payload['winner_competitor_id'] == competitorId) {
          legsWon++;
        }
      }

      return legsWon;
    } catch (e) {
      print('Error parsing legs won: ${e.toString()}');
      return 0;
    }
  }

  // Helper method to get games won by player
  Future<int> _getGamesWonByPlayer(String playerId, GameType? gameType) async {
    try {
      String query = '''
        SELECT COUNT(DISTINCT g.game_id) as games_won
        FROM games g
        JOIN competitors c ON g.winner_competitor_id = c.competitor_id
        JOIN competitor_players cp ON c.competitor_id = cp.competitor_id
        WHERE cp.player_id = ?
        AND g.is_complete = 1
      ''';

      List<dynamic> args = [playerId];

      if (gameType != null) {
        query += ' AND g.game_type = ?';
        args.add(gameType.name);
      }

      final result = await _db.rawQuery(query, args);
      return result.first['games_won'] as int? ?? 0;
    } catch (e) {
      print('Error getting games won: ${e.toString()}');
      return 0;
    }
  }

  // Helper method to calculate X01 specific statistics
  Future<Map<String, dynamic>> _calculateX01Statistics(String playerId, GameType? gameType) async {
    try {
      // Get all X01 games for this player
      String gameFilter = gameType == null 
        ? 'g.game_type = ?' 
        : 'g.game_type = ? AND g.game_type = ?';
      List<dynamic> gameArgs = gameType == null 
        ? ['x01'] 
        : ['x01', gameType.name];

      final gamesQuery = '''
        SELECT g.game_id
        FROM games g
        JOIN dart_throws dt ON g.game_id = dt.game_id
        WHERE dt.player_id = ? AND $gameFilter
        AND g.is_complete = 1
      ''';

      final gamesResult = await _db.rawQuery(gamesQuery, [playerId, ...gameArgs]);
      
      if (gamesResult.isEmpty) {
        return {
          'checkoutPercentage': null,
          'highestCheckout': null,
        };
      }

      final gameIds = gamesResult.map((row) => row['game_id'] as String).toList();

      // Calculate checkout percentage
      double checkoutPercentage = 0.0;
      int checkoutAttempts = 0;

      // Calculate highest checkout
      int? highestCheckout;

      for (final gameId in gameIds) {
        final gameCheckoutPercentage = await _calculateCheckoutPercentageForGame(playerId, gameId);
        final gameHighestCheckout = await _calculateHighestCheckoutForGame(playerId, gameId);
        
        if (gameCheckoutPercentage != null) {
          checkoutPercentage += gameCheckoutPercentage;
          checkoutAttempts++;
        }

        if (gameHighestCheckout != null && (highestCheckout == null || gameHighestCheckout > highestCheckout)) {
          highestCheckout = gameHighestCheckout;
        }
      }

      checkoutPercentage = checkoutAttempts > 0 ? checkoutPercentage / checkoutAttempts : 0.0;

      return {
        'checkoutPercentage': checkoutPercentage,
        'highestCheckout': highestCheckout,
      };
    } catch (e) {
      print('Error calculating X01 statistics: ${e.toString()}');
      return {
        'checkoutPercentage': null,
        'highestCheckout': null,
      };
    }
  }

  // Helper method to calculate checkout percentage for a specific game
  Future<double?> _calculateCheckoutPercentageForGame(String playerId, String gameId) async {
    try {
      // Get all events for this game
      final events = await _db.query(
        'game_events',
        where: 'game_id = ?',
        whereArgs: [gameId],
        orderBy: 'local_sequence ASC',
      );

      if (events.isEmpty) return null;

      int checkoutAttempts = 0;
      int successfulCheckouts = 0;
      bool inCheckoutRange = false;

      for (final event in events) {
        final payload = jsonDecode(event['payload_json'] as String) as Map<String, dynamic>;
        final eventType = event['event_type'] as String;

        if (eventType == 'TurnStarted') {
          final turnPlayerId = payload['player_id'] as String?;
          final startingScore = payload['starting_score'] as int?;
          
          if (turnPlayerId == playerId && startingScore != null && startingScore <= 170) {
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

      return checkoutAttempts > 0 ? (successfulCheckouts / checkoutAttempts) * 100 : null;
    } catch (e) {
      print('Error calculating checkout percentage for game $gameId: ${e.toString()}');
      return null;
    }
  }

  // Helper method to calculate highest checkout for a specific game
  Future<int?> _calculateHighestCheckoutForGame(String playerId, String gameId) async {
    try {
      // Get all events for this game
      final events = await _db.query(
        'game_events',
        where: 'game_id = ?',
        whereArgs: [gameId],
        orderBy: 'local_sequence ASC',
      );

      int? highestCheckout;

      for (final event in events) {
        final payload = jsonDecode(event['payload_json'] as String) as Map<String, dynamic>;
        final eventType = event['event_type'] as String;

        if (eventType == 'LegCompleted') {
          final winnerPlayerId = payload['winner_player_id'] as String?;
          final checkoutScore = payload['checkout_score'] as int?;
          
          if (winnerPlayerId == playerId && checkoutScore != null) {
            if (highestCheckout == null || checkoutScore > highestCheckout) {
              highestCheckout = checkoutScore;
            }
          }
        }
      }

      return highestCheckout;
    } catch (e) {
      print('Error calculating highest checkout for game $gameId: ${e.toString()}');
      return null;
    }
  }

  // Helper method to calculate highest turn score
  Future<int> _calculateHighestTurnScore(String playerId, GameType? gameType, {String? gameId}) async {
    try {
      String query = '''
        SELECT MAX(turn_score) as highest_turn_score
        FROM (
          SELECT turn_number, SUM(score) as turn_score
          FROM dart_throws
          WHERE player_id = ?
      ''';

      List<dynamic> args = [playerId];

      if (gameId != null) {
        query += ' AND game_id = ?';
        args.add(gameId);
      } else if (gameType != null) {
        query += ' AND game_id IN (SELECT game_id FROM games WHERE game_type = ?)';
        args.add(gameType.name);
      }

      query += '''
          GROUP BY game_id, turn_number
        )
      ''';

      final result = await _db.rawQuery(query, args);
      return result.first['highest_turn_score'] as int? ?? 0;
    } catch (e) {
      print('Error calculating highest turn score: ${e.toString()}');
      return 0;
    }
  }

  // Helper method to get legs won by player
  Future<int> _getLegsWonByPlayer(String playerId, GameType? gameType) async {
    try {
      String query = '''
        SELECT COUNT(*) as legs_won
        FROM game_events ge
        JOIN games g ON ge.game_id = g.game_id
        WHERE ge.event_type = 'LegCompleted'
        AND JSON_EXTRACT(ge.payload_json, '\$.winner_player_id') = ?
        AND g.is_complete = 1
      ''';

      List<dynamic> args = [playerId];

      if (gameType != null) {
        query += ' AND g.game_type = ?';
        args.add(gameType.name);
      }

      final result = await _db.rawQuery(query, args);
      return result.first['legs_won'] as int? ?? 0;
    } catch (e) {
      print('Error getting legs won by player: ${e.toString()}');
      return 0;
    }
  }

  // Helper method to get legs won for player in specific game
  Future<int> _getLegsWonForPlayerInGame(String playerId, String gameId) async {
    try {
      final events = await _db.query(
        'game_events',
        where: 'game_id = ? AND event_type = ?',
        whereArgs: [gameId, 'LegCompleted'],
      );

      int legsWon = 0;
      for (final event in events) {
        final payload = jsonDecode(event['payload_json'] as String) as Map<String, dynamic>;
        if (payload['winner_player_id'] == playerId) {
          legsWon++;
        }
      }

      return legsWon;
    } catch (e) {
      print('Error getting legs won in game: ${e.toString()}');
      return 0;
    }
  }

  // Helper method to calculate bust rate
  Future<double> _calculateBustRate(String playerId, GameType? gameType, {String? gameId}) async {
    try {
      // Get all turn ended events that were busts
      String query = '''
        SELECT COUNT(*) as bust_count
        FROM game_events
        WHERE event_type = 'TurnEnded'
        AND JSON_EXTRACT(payload_json, '\$.player_id') = ?
        AND JSON_EXTRACT(payload_json, '\$.reason') = 'bust'
      ''';

      List<dynamic> args = [playerId];

      if (gameId != null) {
        query += ' AND game_id = ?';
        args.add(gameId);
      } else if (gameType != null) {
        query += ' AND game_id IN (SELECT game_id FROM games WHERE game_type = ?)';
        args.add(gameType.name);
      }

      final bustResult = await _db.rawQuery(query, args);
      int bustCount = bustResult.first['bust_count'] as int? ?? 0;

      // Get total turn count
      String turnQuery = '''
        SELECT COUNT(*) as turn_count
        FROM game_events
        WHERE event_type = 'TurnEnded'
        AND JSON_EXTRACT(payload_json, '\$.player_id') = ?
      ''';

      List<dynamic> turnArgs = [playerId];

      if (gameId != null) {
        turnQuery += ' AND game_id = ?';
        turnArgs.add(gameId);
      } else if (gameType != null) {
        turnQuery += ' AND game_id IN (SELECT game_id FROM games WHERE game_type = ?)';
        turnArgs.add(gameType.name);
      }

      final turnResult = await _db.rawQuery(turnQuery, turnArgs);
      int turnCount = turnResult.first['turn_count'] as int? ?? 1; // Avoid division by zero

      return turnCount > 0 ? bustCount / turnCount : 0.0;
    } catch (e) {
      print('Error calculating bust rate: ${e.toString()}');
      return 0.0;
    }
  }
}
