// Statistics Repository Drift Implementation
// Concrete implementation of StatisticsRepository interface using Drift

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart' as domain;
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:dart_lodge/features/statistics/domain/event_leg_limiter.dart';
import 'package:dart_lodge/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_segment_utils.dart';
import '../database.dart' as drift_db;

class StatisticsRepositoryDrift implements StatisticsRepository {
  final drift_db.AppDatabase _db;
  final PlayerStatsAssembler _assembler;

  StatisticsRepositoryDrift(this._db, {PlayerStatsAssembler? assembler})
      : _assembler = assembler ?? const PlayerStatsAssembler();

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
      final gameRow = await (_db.select(_db.games)
            ..where((g) => g.gameId.equals(gameId))
            ..limit(1))
          .getSingleOrNull();
      if (gameRow == null) {
        throw GameNotFoundException(gameId);
      }
      final gameType = GameType.values.firstWhere(
        (t) => t.name == gameRow.gameType,
        orElse: () => GameType.x01,
      );

      // 2. Load throws for the game.
      final dartThrows = await (_db.select(_db.dartThrows)
            ..where((t) => t.gameId.equals(gameId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.turnNumber),
              (t) => OrderingTerm.asc(t.dartNumber),
            ]))
          .get();

      if (dartThrows.isEmpty) {
        return GameStats(
          gameId: gameId,
          byCompetitor: const [],
          gameType: gameRow.gameType,
        );
      }

      final throws = dartThrows
          .map((t) => (
                competitorId: t.competitorId,
                playerId: t.playerId,
                score: t.score,
              ))
          .toList();

      // 3. Resolve competitor names.
      final competitorIds =
          throws.map((t) => t.competitorId).toSet().toList();
      final competitorRows = await (_db.select(_db.competitors)
            ..where((c) => c.competitorId.isIn(competitorIds)))
          .get();
      final competitorNames = <String, String>{
        for (final c in competitorRows) c.competitorId: c.name,
      };

      // 4. Load events for projection-based stats.
      final eventRows = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.equals(gameId))
            ..orderBy([(e) => OrderingTerm.asc(e.localSequence)]))
          .get();
      final events = eventRows
          .map((row) => domain.GameEvent(
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
              ))
          .toList();

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
      // 1. Verify player exists.
      final playerExists = await (_db.select(_db.players)
                ..where((p) => p.playerId.equals(playerId))
                ..limit(1))
              .getSingleOrNull() !=
          null;
      if (!playerExists) {
        throw PlayerNotFoundException(playerId);
      }

      // 2. Query games for this player + gameType + completed (+ from/to).
      final gamesQuery = _db.selectOnly(_db.games)
        ..addColumns([
          _db.games.gameId,
          _db.games.configJson,
          _db.games.startTime,
        ])
        ..join([
          innerJoin(_db.competitors,
              _db.competitors.gameId.equalsExp(_db.games.gameId)),
          innerJoin(_db.competitorPlayers,
              _db.competitorPlayers.competitorId
                  .equalsExp(_db.competitors.competitorId)),
        ])
        ..where(_db.competitorPlayers.playerId.equals(playerId) &
            _db.games.isComplete.equals(1) &
            _db.games.gameType.equals(gameType.name))
        ..groupBy([_db.games.gameId]);
      if (from != null) {
        gamesQuery.where(
            _db.games.startTime.isBiggerOrEqualValue(from.toIso8601String()));
      }
      if (to != null) {
        gamesQuery.where(
            _db.games.startTime.isSmallerOrEqualValue(to.toIso8601String()));
      }

      final gameRows = await gamesQuery.get();
      var games = gameRows
          .map((r) => (
                gameId: r.read(_db.games.gameId)!,
                configJson: r.read(_db.games.configJson),
                startTime: r.read(_db.games.startTime)!,
              ))
          .toList();

      // 3. Filter by startingScore / variant in Dart (config_json is opaque).
      if (startingScore != null) {
        games = games.where((g) {
          final cj = g.configJson;
          if (cj == null) return false;
          try {
            final cfg = jsonDecode(cj) as Map<String, dynamic>;
            return cfg['starting_score'] == startingScore;
          } catch (_) {
            return false;
          }
        }).toList();
      }
      if (variant != null) {
        games = games.where((g) {
          final cj = g.configJson;
          if (cj == null) return false;
          try {
            final cfg = jsonDecode(cj) as Map<String, dynamic>;
            return cfg['variant'] == variant;
          } catch (_) {
            return false;
          }
        }).toList();
      }

      if (games.isEmpty) {
        return _createEmptyPlayerStats(playerId, gameType);
      }

      final gameIds = games.map((g) => g.gameId).toList();
      final totalGames = gameIds.length;

      // 4. Total dart count for this player across these games.
      final dartCountQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.dartId.count()])
        ..where(_db.dartThrows.playerId.equals(playerId) &
            _db.dartThrows.gameId.isIn(gameIds));
      final dartCountResult = await dartCountQuery.getSingle();
      final totalDartsThrown =
          dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

      // 5. Load events ordered by (game_id, local_sequence) — local_sequence
      //    is per-game and starts at 1 for each game, so ordering by it alone
      //    interleaves events from different games and corrupts projection
      //    state. Trim to the requested leg window.
      final eventRows = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.isIn(gameIds))
            ..orderBy([
              (e) => OrderingTerm.asc(e.gameId),
              (e) => OrderingTerm.asc(e.localSequence),
            ]))
          .get();
      final events = EventLegLimiter.trim(
        eventRows
            .map((row) => domain.GameEvent(
                  eventId: row.eventId,
                  gameId: row.gameId,
                  eventType: row.eventType,
                  localSequence: row.localSequence,
                  occurredAt: DateTime.parse(row.occurredAt),
                  payload:
                      jsonDecode(row.payloadJson) as Map<String, dynamic>,
                  synced: row.synced == 1,
                  actorId: row.actorId,
                  globalSequence: row.globalSequence,
                  source: EventSource.client,
                ))
            .toList(),
        legLimit,
      );

      // 6. Extract in/out strategy + ATC variant from latest game's config.
      String inStrategy = 'straight';
      String outStrategy = 'double';
      String atcVariant = 'standard';
      final sortedGames = [...games]
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      final latestConfigJson = sortedGames.first.configJson;
      if (latestConfigJson != null) {
        try {
          final cfg = jsonDecode(latestConfigJson) as Map<String, dynamic>;
          inStrategy = cfg['in_strategy'] as String? ?? inStrategy;
          outStrategy = cfg['out_strategy'] as String? ?? outStrategy;
          atcVariant = cfg['variant'] as String? ?? atcVariant;
        } catch (_) {}
      }

      // 7. Delegate projection replay + snapshot mapping to the assembler.
      return _assembler.fromEvents(
        playerId: playerId,
        gameType: gameType,
        events: events,
        totalGames: totalGames,
        totalDartsThrown: totalDartsThrown,
        inStrategy: inStrategy,
        outStrategy: outStrategy,
        atcVariant: atcVariant,
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
      // 1. Verify game exists, grab gameType.
      final game = await (_db.select(_db.games)
            ..where((g) => g.gameId.equals(gameId))
            ..limit(1))
          .getSingleOrNull();
      if (game == null) {
        throw GameNotFoundException(gameId);
      }
      final gameType = GameType.values.firstWhere(
        (type) => type.name == game.gameType,
        orElse: () => GameType.x01,
      );

      // 2. Verify player participated and aggregate their darts/score.
      final playerThrows = await (_db.select(_db.dartThrows)
            ..where((t) =>
                t.playerId.equals(playerId) & t.gameId.equals(gameId)))
          .get();
      if (playerThrows.isEmpty) {
        throw PlayerNotFoundException(playerId);
      }
      final playerDartsInGame = playerThrows.length;
      final playerScoreInGame =
          playerThrows.fold<int>(0, (sum, t) => sum + t.score);

      // 3. Load events for projection-based stats.
      final eventRows = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.equals(gameId))
            ..orderBy([(e) => OrderingTerm.asc(e.localSequence)]))
          .get();
      final events = eventRows
          .map((row) => domain.GameEvent(
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
              ))
          .toList();

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
}
