// Statistics Repository Implementation
// Concrete implementation of StatisticsRepository interface
// Statistics are computed as projections from game events and dart throws

import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:async';
import '../../domain/entities/player_stats.dart';
import '../../domain/entities/game_stats.dart';
import '../../domain/repositories/statistics_repository.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/error/repository_exception.dart' hide DatabaseException;
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/core/persistence/data_change_notifier.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:dart_lodge/features/statistics/domain/event_leg_limiter.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_segment_utils.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';


class StatisticsRepositoryImpl implements StatisticsRepository {
  final Database _db;
  final PlayerStatsAssembler _assembler;
  final DataChangeNotifier? _changeNotifier;

  StatisticsRepositoryImpl(this._db,
      {PlayerStatsAssembler? assembler, DataChangeNotifier? changeNotifier})
      : _assembler = assembler ?? const PlayerStatsAssembler(),
        _changeNotifier = changeNotifier;

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
      // 1. Verify game exists + grab gameType.
      final gameResult = await _db.query(
        'games',
        where: 'game_id = ?',
        whereArgs: [gameId],
        limit: 1,
      );
      if (gameResult.isEmpty) {
        throw GameNotFoundException(gameId);
      }
      final gameTypeStr = gameResult.first['game_type'] as String?;
      final gameType = GameType.values.firstWhere(
        (t) => t.name == gameTypeStr,
        orElse: () => GameType.x01,
      );

      // 2. Load all throws for the game.
      final dartThrows = await _db.query(
        'dart_throws',
        where: 'game_id = ?',
        whereArgs: [gameId],
        orderBy: 'turn_number ASC, dart_number ASC',
      );

      if (dartThrows.isEmpty) {
        return GameStats(
          gameId: gameId,
          byCompetitor: const [],
          gameType: gameTypeStr ?? '',
        );
      }

      final throws = dartThrows
          .map((t) => (
                competitorId: t['competitor_id'] as String,
                playerId: t['player_id'] as String,
                score: t['score'] as int,
              ))
          .toList();

      // 3. Resolve competitor names for each unique competitor_id in throws.
      final competitorIds = throws.map((t) => t.competitorId).toSet().toList();
      final placeholders = competitorIds.map((_) => '?').join(',');
      final competitorRows = await _db.rawQuery(
        'SELECT competitor_id, name FROM competitors WHERE competitor_id IN ($placeholders)',
        competitorIds,
      );
      final competitorNames = <String, String>{
        for (final row in competitorRows)
          row['competitor_id'] as String: row['name'] as String,
      };

      // 4. Load events for projection-based stats.
      final eventsResult = await _db.query(
        'game_events',
        where: 'game_id = ?',
        whereArgs: [gameId],
        orderBy: 'local_sequence ASC',
      );
      final events =
          eventsResult.map((r) => GameEvent.fromJson(r)).toList();

      // 5. Delegate.
      return _assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: gameType,
        throws: throws,
        competitorNames: competitorNames,
        events: events,
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
  Stream<GameStats> watchGameStats(String gameId) async* {
    try {
      yield await getGameStats(gameId);
    } catch (error) {
      if (error is RepositoryException) rethrow;
      throw StatisticsException('Failed to watch game statistics: ${error.toString()}');
    }
    final source = _changeNotifier?.changes ?? const Stream<void>.empty();
    yield* source
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
    required GameType gameType,
    DateTime? from,
    DateTime? to,
    int? startingScore,
    String? variant,
    int? legLimit,
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
        startingScore: startingScore,
        variant: variant,
        legLimit: legLimit,
      );
      return stats ?? _createEmptyPlayerStats(playerId, gameType);
    } on RepositoryException {
      rethrow;
    } on DatabaseException catch (e) {
      throw StatisticsException('Failed to retrieve player statistics: ${e.toString()}');
    } catch (e) {
      throw StatisticsException('Failed to retrieve player statistics: $e');
    }
  }

  @override
  Future<PlayerStats> getPlayerStatsForGame(String playerId, String gameId) async {
    try {
      // 1. Verify game exists, grab gameType.
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

      // 2. Verify player participated and aggregate their darts/score.
      final dartThrows = await _db.query(
        'dart_throws',
        where: 'player_id = ? AND game_id = ?',
        whereArgs: [playerId, gameId],
        orderBy: 'turn_number ASC, dart_number ASC',
      );
      if (dartThrows.isEmpty) {
        throw PlayerNotFoundException(playerId);
      }
      final playerDartsInGame = dartThrows.length;
      final playerScoreInGame = dartThrows.fold<int>(
          0, (sum, t) => sum + (t['score'] as int));

      // 3. Load events for projection-based stats.
      final eventsResult = await _db.query(
        'game_events',
        where: 'game_id = ?',
        whereArgs: [gameId],
        orderBy: 'local_sequence ASC',
      );
      final events =
          eventsResult.map((r) => GameEvent.fromJson(r)).toList();

      // 4. Delegate.
      return _assembler.playerStatsForGameFromEvents(
        playerId: playerId,
        gameType: gameType,
        playerDartsInGame: playerDartsInGame,
        playerScoreInGame: playerScoreInGame,
        events: events,
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
  Stream<PlayerStats> watchPlayerStats(String playerId,
      {required GameType gameType}) async* {
    // Emit an initial snapshot first so subscribers don't wait for a write
    // before seeing data. Subsequent values fire in response to writes
    // published by the data-mutating repos.
    try {
      final initial = await _buildPlayerStatsViaProjection(playerId, gameType: gameType);
      yield initial ?? _createEmptyPlayerStats(playerId, gameType);
    } catch (error) {
      if (error is RepositoryException) rethrow;
      throw StatisticsException('Failed to watch player statistics: ${error.toString()}');
    }
    final source = _changeNotifier?.changes ?? const Stream<void>.empty();
    yield* source
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

      // Calculate stats for all players in parallel
      final leaderboard = await Future.wait(
        playersResult.map((row) => getPlayerStats(row['player_id'] as String, gameType: gameType)),
      );

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

  Future<PlayerStats?> _buildPlayerStatsViaProjection(
    String playerId, {
    required GameType gameType,
    DateTime? from,
    DateTime? to,
    int? startingScore,
    String? variant,
    int? legLimit,
  }) async {
    // 1. Query games involving this player
    String gamesQuery = '''
      SELECT DISTINCT g.game_id, g.config_json, g.game_type, g.start_time
      FROM games g
      JOIN competitors c ON g.game_id = c.game_id
      JOIN competitor_players cp ON c.competitor_id = cp.competitor_id
      WHERE cp.player_id = ? AND g.is_complete = 1
        AND g.game_type = ?
    ''';
    final List<dynamic> gamesArgs = [playerId, gameType.name];

    if (from != null) {
      gamesQuery += ' AND g.start_time >= ?';
      gamesArgs.add(from.toIso8601String());
    }
    if (to != null) {
      gamesQuery += ' AND g.start_time <= ?';
      gamesArgs.add(to.toIso8601String());
    }

    var gamesResult = await _db.rawQuery(gamesQuery, gamesArgs);
    if (gamesResult.isEmpty) return null;

    // Filter by startingScore in Dart (config_json is opaque — no JSON_EXTRACT in SQL)
    if (startingScore != null) {
      gamesResult = gamesResult.where((row) {
        final configJson = row['config_json'] as String?;
        if (configJson == null) return false;
        try {
          final cfg = jsonDecode(configJson) as Map<String, dynamic>;
          return cfg['starting_score'] == startingScore;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // Filter by cricket variant if specified
    if (variant != null) {
      gamesResult = gamesResult.where((row) {
        final configJson = row['config_json'] as String?;
        if (configJson == null) return false;
        try {
          final cfg = jsonDecode(configJson) as Map<String, dynamic>;
          return cfg['variant'] == variant;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    if (gamesResult.isEmpty) return null;

    var gameIds = gamesResult.map((r) => r['game_id'] as String).toList();
    final totalGames = gameIds.length;

    // Identify solo (single-competitor) games so leg projections can exclude
    // them — legs played/won is a multiplayer-only metric (see issue #106).
    final soloGameIds = <String>{};
    if (gameIds.isNotEmpty) {
      final soloPlaceholders = gameIds.map((_) => '?').join(',');
      final competitorCounts = await _db.rawQuery(
        'SELECT game_id, COUNT(*) as cnt FROM competitors '
        'WHERE game_id IN ($soloPlaceholders) GROUP BY game_id',
        gameIds,
      );
      for (final row in competitorCounts) {
        if ((row['cnt'] as int? ?? 0) <= 1) {
          soloGameIds.add(row['game_id'] as String);
        }
      }
    }

    // Apply legLimit: keep only the last legLimit completed legs by slicing game list
    // (full leg-level limit is handled after projection via legLimit on the runner snapshot)
    // For simplicity we pass legLimit into the events and trim after projection.
    // The approach: replay all events; then reconstruct limited legs in snapshot.
    // Simplest correct approach: filter game events to last legLimit LegCompleted events.

    // 2. Get totalDartsThrown from dart_throws (SQL fallback — projections
    //    count DartThrown events, but contract tests insert throws without events)
    final placeholders = gameIds.map((_) => '?').join(',');
    final throwsResult = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM dart_throws WHERE player_id = ? AND game_id IN ($placeholders)',
      [playerId, ...gameIds],
    );
    final totalDartsThrown = throwsResult.first['cnt'] as int? ?? 0;

    // 3. Query all events for those games ordered by (game_id, local_sequence).
    //    `local_sequence` is per-game and starts at 1 for each game, so ordering
    //    by it alone interleaves events from different games — corrupting the
    //    projection state. Ordering by game_id first keeps each game contiguous.
    final eventsResult = await _db.rawQuery(
      'SELECT * FROM game_events WHERE game_id IN ($placeholders) ORDER BY game_id ASC, local_sequence ASC',
      gameIds,
    );
    final events = EventLegLimiter.trim(
      eventsResult.map((row) => GameEvent.fromJson(row)).toList(),
      legLimit,
    );

    // 4. Extract in/out strategy + ATC variant from most recent game's config
    String inStrategy = 'straight';
    String outStrategy = 'double';
    String atcVariant = 'standard';
    final sortedGames = [...gamesResult]
      ..sort((a, b) => (b['start_time'] as String).compareTo(a['start_time'] as String));
    final latestConfigJson = sortedGames.first['config_json'] as String?;
    if (latestConfigJson != null) {
      try {
        final config = jsonDecode(latestConfigJson) as Map<String, dynamic>;
        inStrategy = config['in_strategy'] as String? ?? inStrategy;
        outStrategy = config['out_strategy'] as String? ?? outStrategy;
        atcVariant = config['variant'] as String? ?? atcVariant;
      } catch (_) {}
    }

    // 5. Delegate projection replay + snapshot mapping to the shared assembler.
    return _assembler.fromEvents(
      playerId: playerId,
      gameType: gameType,
      events: events,
      totalGames: totalGames,
      totalDartsThrown: totalDartsThrown,
      inStrategy: inStrategy,
      outStrategy: outStrategy,
      atcVariant: atcVariant,
      soloGameIds: soloGameIds,
    );
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
      // 1. Query games for this player
      String gamesQuery = '''
        SELECT DISTINCT g.game_id, g.config_json, g.start_time
        FROM games g
        JOIN competitors c ON g.game_id = c.game_id
        JOIN competitor_players cp ON c.competitor_id = cp.competitor_id
        WHERE cp.player_id = ?
        AND g.is_complete = 1
      ''';
      final List<dynamic> gamesArgs = [playerId];

      if (gameType != null) {
        gamesQuery += ' AND g.game_type = ?';
        gamesArgs.add(gameType.name);
      }

      gamesQuery += ' ORDER BY g.start_time ASC';

      var gamesResult = await _db.rawQuery(gamesQuery, gamesArgs);

      // Filter by startingScore in Dart (config_json is opaque)
      if (startingScore != null) {
        gamesResult = gamesResult.where((row) {
          final configJson = row['config_json'] as String?;
          if (configJson == null) return false;
          try {
            final cfg = jsonDecode(configJson) as Map<String, dynamic>;
            return cfg['starting_score'] == startingScore;
          } catch (_) {
            return false;
          }
        }).toList();
      }

      // Filter by cricket variant if specified
      if (variant != null) {
        gamesResult = gamesResult.where((row) {
          final configJson = row['config_json'] as String?;
          if (configJson == null) return false;
          try {
            final cfg = jsonDecode(configJson) as Map<String, dynamic>;
            return cfg['variant'] == variant;
          } catch (_) {
            return false;
          }
        }).toList();
      }

      if (gamesResult.isEmpty) return [];

      final List<PlayerLegSnapshot> snapshots = [];
      int legIndex = 0;

      for (final gameRow in gamesResult) {
        final gameId = gameRow['game_id'] as String;
        final gameDate = DateTime.tryParse(gameRow['start_time'] as String? ?? '') ?? DateTime.now();
        final configJson = gameRow['config_json'] as String?;
        int? gamStartingScore;
        if (configJson != null) {
          try {
            final cfg = jsonDecode(configJson) as Map<String, dynamic>;
            gamStartingScore = cfg['starting_score'] as int?;
          } catch (_) {}
        }

        // Get events for this game ordered by local_sequence
        final eventsResult = await _db.rawQuery(
          'SELECT * FROM game_events WHERE game_id = ? ORDER BY local_sequence ASC',
          [gameId],
        );

        // Get dart throws for this player in this game
        final dartsResult = await _db.rawQuery(
          'SELECT turn_number, score FROM dart_throws WHERE player_id = ? AND game_id = ? ORDER BY turn_number ASC, dart_number ASC',
          [playerId, gameId],
        );

        // Build per-turn score map
        final Map<int, int> turnScores = {};
        for (final dart in dartsResult) {
          final turn = dart['turn_number'] as int;
          final score = (dart['score'] as num?)?.toInt() ?? 0;
          turnScores[turn] = (turnScores[turn] ?? 0) + score;
        }

        final isPracticeGame = _practiceGameTypes.contains(gameType);

        // Scan events to accumulate per-leg darts and PPR/MPT
        int legDartCount = 0;
        int legScoreTotal = 0;
        int currentTurnNumber = 0;
        final Set<int> legTurnNumbers = {};

        // Cricket MPT tracking
        int legTotalMarks = 0;
        int legTotalTurns = 0;
        int currentTurnMarks = 0;

        // ATC hit-rate tracking (for practice trend chart)
        int atcDartsAtTarget = 0;
        int atcHits = 0;
        int atcCurrentTarget = 1;
        bool atcInPlayerTurn = false;

        // X01 checkout-score tracking: starting_score from this player's most
        // recent TurnStarted before LegCompleted. If they win the leg, that's
        // the score they checked out on.
        int? lastPlayerTurnStartingScore;

        for (final eventRow in eventsResult) {
          final event = GameEvent.fromJson(eventRow);
          switch (event.eventType) {
            case 'TurnStarted':
              final pid = event.payload['player_id'] as String?;
              if (pid != playerId) break;
              currentTurnNumber = event.payload['turn_number'] as int? ?? currentTurnNumber;
              currentTurnMarks = 0;
              atcInPlayerTurn = true;
              lastPlayerTurnStartingScore =
                  (event.payload['starting_score'] as num?)?.toInt();
            case 'DartThrown':
              final pid = event.payload['player_id'] as String?;
              if (pid != playerId) break;
              legDartCount++;
              final seg = (event.payload['segment'] as num?)?.toInt();
              final mult = (event.payload['multiplier'] as num?)?.toInt();
              final score = (seg != null && mult != null)
                  ? seg * mult
                  : (event.payload['score'] as num?)?.toInt() ?? 0;
              legScoreTotal += score;
              // Accumulate cricket marks (payload segment may be int or String)
              final rawSeg = event.payload['segment'];
              if (rawSeg is String) {
                currentTurnMarks += cricketMarksForSegment(rawSeg);
              } else if (rawSeg is num) {
                final segInt = rawSeg.toInt();
                final multInt = (event.payload['multiplier'] as num?)?.toInt() ?? 1;
                if (kCricketTargets.contains(segInt)) {
                  currentTurnMarks += multInt.clamp(0, 3);
                }
              }
              // ATC hit tracking
              if (isPracticeGame && gameType == GameType.aroundTheClock && atcInPlayerTurn) {
                final segVal = (event.payload['segment'] as num?)?.toInt() ?? 0;
                if (atcCurrentTarget <= 20) {
                  atcDartsAtTarget++;
                  if (segVal == atcCurrentTarget) {
                    atcHits++;
                    atcCurrentTarget++;
                  }
                }
              }
            case 'TurnEnded':
              final pid = event.payload['player_id'] as String?;
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

              final checkoutScore = event.payload['checkout_score'] as int?;
              final checkoutAttempts = event.payload['checkout_attempts'] as int?;
              double? checkoutPct;
              if (checkoutAttempts != null && checkoutAttempts > 0 && checkoutScore != null) {
                checkoutPct = (1 / checkoutAttempts) * 100;
              }

              final winnerPlayerId =
                  event.payload['winner_player_id'] as String?;
              final legCheckoutScore = winnerPlayerId == playerId
                  ? lastPlayerTurnStartingScore
                  : null;

              // Compute practiceScore for the trend chart
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
                checkoutScore: legCheckoutScore,
                startingScore: gamStartingScore,
                mpt: mpt,
                practiceScore: practiceScore,
              ));

              // Reset for next leg
              legDartCount = 0;
              legScoreTotal = 0;
              legTurnNumbers.clear();
              legTotalMarks = 0;
              legTotalTurns = 0;
              currentTurnMarks = 0;
              atcDartsAtTarget = 0;
              atcHits = 0;
              atcCurrentTarget = 1;
              atcInPlayerTurn = false;
              lastPlayerTurnStartingScore = null;
          }
        }
      }

      // Apply limit by taking last N items
      if (limit != null && snapshots.length > limit) {
        return snapshots.sublist(snapshots.length - limit);
      }
      return snapshots;
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException('Failed to retrieve leg history: ${e.toString()}');
    }
  }

  @override
  Future<List<int>> getPlayerX01StartingScores(String playerId) async {
    try {
      final gamesResult = await _db.rawQuery('''
        SELECT DISTINCT g.config_json
        FROM games g
        JOIN competitors c ON g.game_id = c.game_id
        JOIN competitor_players cp ON c.competitor_id = cp.competitor_id
        WHERE cp.player_id = ? AND g.game_type = ? AND g.is_complete = 1
      ''', [playerId, GameType.x01.name]);

      final Set<int> scores = {};
      for (final row in gamesResult) {
        final configJson = row['config_json'] as String?;
        if (configJson == null) continue;
        try {
          final cfg = jsonDecode(configJson) as Map<String, dynamic>;
          final score = cfg['starting_score'] as int?;
          if (score != null) scores.add(score);
        } catch (_) {}
      }

      return scores.toList()..sort();
    } catch (e) {
      throw StatisticsException('Failed to retrieve starting scores: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getPlayerCricketVariants(String playerId) async {
    try {
      final gamesResult = await _db.rawQuery('''
        SELECT DISTINCT g.config_json
        FROM games g
        JOIN competitors c ON g.game_id = c.game_id
        JOIN competitor_players cp ON c.competitor_id = cp.competitor_id
        WHERE cp.player_id = ? AND g.game_type = ? AND g.is_complete = 1
      ''', [playerId, GameType.cricket.name]);

      final Set<String> variants = {};
      for (final row in gamesResult) {
        final configJson = row['config_json'] as String?;
        if (configJson == null) continue;
        try {
          final cfg = jsonDecode(configJson) as Map<String, dynamic>;
          final v = cfg['variant'] as String?;
          if (v != null) variants.add(v);
        } catch (_) {}
      }

      return variants.toList()..sort();
    } catch (e) {
      throw StatisticsException('Failed to retrieve cricket variants: ${e.toString()}');
    }
  }

}
