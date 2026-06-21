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
import 'package:dart_lodge/features/statistics/domain/entities/dart_position.dart';
import '../database.dart' as drift_db;
import '../repository_parsers.dart';

class StatisticsRepositoryDrift implements StatisticsRepository {
  final drift_db.AppDatabase _db;
  final PlayerStatsAssembler _assembler;

  StatisticsRepositoryDrift(this._db, {PlayerStatsAssembler? assembler})
      : _assembler = assembler ?? const PlayerStatsAssembler();

  /// Reads the `outStrategy` from a game's opaque `config_json`, defaulting to
  /// `'double'` for missing/legacy/unparseable configs. The X01 checkout-%
  /// projection is out-strategy-aware (#637), so per-game and per-leg stats
  /// must thread the game's real out strategy, not assume double-out.
  static String _outStrategyFromConfig(String? configJson) {
    if (configJson == null) return 'double';
    try {
      final cfg = jsonDecode(configJson) as Map<String, dynamic>;
      return cfg['outStrategy'] as String? ?? 'double';
    } catch (_) {
      return 'double';
    }
  }

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
      final gameType = parseGameTypeFromColumn(gameRow.gameType);

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
                source: parseEventSourceFromColumn(row.source),
              ))
          .toList();

      // 5. Delegate.
      return _assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: gameType,
        throws: throws,
        competitorNames: competitorNames,
        events: events,
        outStrategy: _outStrategyFromConfig(gameRow.configJson),
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
    // Watch both `dart_throws` and `game_events`. Events appended without a
    // same-transaction dart insert (LegCompleted, GameCompleted, empty-turn
    // busts via TurnEnded) must re-trigger the stream — watching dart_throws
    // alone misses those updates (issue #129).
    final tableUpdates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.dartThrows, _db.gameEvents]),
    );

    return _emitInitialThenOn(tableUpdates)
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
    String cricketTargetMode = 'fixed',
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
            return cfg['startingScore'] == startingScore;
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
            // New configs serialize cricket scoring under `scoring`; legacy
            // payloads use `variant`. See cricket target-modes design §2.
            final scoring = cfg['scoring'] ?? cfg['variant'];
            return scoring == variant;
          } catch (_) {
            return false;
          }
        }).toList();
      }
      // Cricket target-mode cohort filter: each mode's stats are kept
      // separate so Random/Crazy don't pollute Standard Cricket career
      // numbers (the canonical target sets differ, so closure rate and MPR
      // are not directly comparable). Legacy games carry no `targetMode`
      // field and map to `fixed`. Crazy lands in #238. See
      // `docs/plans/2026-05-19-cricket-target-modes-design.md` §6.
      if (gameType == GameType.cricket) {
        games = games.where((g) {
          final cj = g.configJson;
          if (cj == null) return cricketTargetMode == 'fixed';
          try {
            final cfg = jsonDecode(cj) as Map<String, dynamic>;
            final mode = cfg['targetMode'] ?? 'fixed';
            return mode == cricketTargetMode;
          } catch (_) {
            return cricketTargetMode == 'fixed';
          }
        }).toList();
      }

      if (games.isEmpty) {
        return _createEmptyPlayerStats(playerId, gameType);
      }

      final gameIds = games.map((g) => g.gameId).toList();
      final totalGames = gameIds.length;

      // Identify solo (single-competitor) games so leg projections can exclude
      // them — legs played/won is a multiplayer-only metric (see issue #106).
      final soloGameIds = <String>{};
      if (gameIds.isNotEmpty) {
        final competitorCountQuery = _db.selectOnly(_db.competitors)
          ..addColumns(
              [_db.competitors.gameId, _db.competitors.competitorId.count()])
          ..where(_db.competitors.gameId.isIn(gameIds))
          ..groupBy([_db.competitors.gameId]);
        final competitorCountRows = await competitorCountQuery.get();
        for (final row in competitorCountRows) {
          final gid = row.read(_db.competitors.gameId);
          final cnt =
              row.read(_db.competitors.competitorId.count()) ?? 0;
          if (gid != null && cnt <= 1) {
            soloGameIds.add(gid);
          }
        }
      }

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
                  source: parseEventSourceFromColumn(row.source),
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
          inStrategy = cfg['inStrategy'] as String? ?? inStrategy;
          outStrategy = cfg['outStrategy'] as String? ?? outStrategy;
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
        soloGameIds: soloGameIds,
      );
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve player statistics: ${e.toString()}');
    }
  }

  @override
  Future<AchievementMetricsData> achievementMetricsForPlayer(
      String playerId) async {
    try {
      // 1. Verify player exists (parity with getPlayerStats).
      final playerExists = await (_db.select(_db.players)
                ..where((p) => p.playerId.equals(playerId))
                ..limit(1))
              .getSingleOrNull() !=
          null;
      if (!playerExists) {
        throw PlayerNotFoundException(playerId);
      }

      // 2. All completed games the player participated in, ANY type. The
      //    assembler partitions by gameTypesById internally, so no type filter.
      final gamesQuery = _db.selectOnly(_db.games)
        ..addColumns([_db.games.gameId, _db.games.gameType])
        ..join([
          innerJoin(_db.competitors,
              _db.competitors.gameId.equalsExp(_db.games.gameId)),
          innerJoin(_db.competitorPlayers,
              _db.competitorPlayers.competitorId
                  .equalsExp(_db.competitors.competitorId)),
        ])
        ..where(_db.competitorPlayers.playerId.equals(playerId) &
            _db.games.isComplete.equals(1))
        ..groupBy([_db.games.gameId]);
      final gameRows = await gamesQuery.get();

      final gameTypesById = <String, GameType>{
        for (final r in gameRows)
          r.read(_db.games.gameId)!:
              parseGameTypeFromColumn(r.read(_db.games.gameType)!),
      };
      final gameIds = gameTypesById.keys.toList();

      if (gameIds.isEmpty) {
        return (
          total180s: 0,
          highestCheckout: 0,
          totalWins: 0,
          totalDartsThrown: 0,
          games501Played: 0,
          hasNineDarter: false,
        );
      }

      // 3. Total dart count for the player across these games.
      final dartCountQuery = _db.selectOnly(_db.dartThrows)
        ..addColumns([_db.dartThrows.dartId.count()])
        ..where(_db.dartThrows.playerId.equals(playerId) &
            _db.dartThrows.gameId.isIn(gameIds));
      final dartCountResult = await dartCountQuery.getSingle();
      final totalDartsThrown =
          dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

      // 4. Full event history ordered (game_id, local_sequence) — no leg limit.
      final eventRows = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.isIn(gameIds))
            ..orderBy([
              (e) => OrderingTerm.asc(e.gameId),
              (e) => OrderingTerm.asc(e.localSequence),
            ]))
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
                source: parseEventSourceFromColumn(row.source),
              ))
          .toList();

      // 5. Delegate to the assembler (statistics owns the projection wiring).
      return _assembler.achievementMetricsFromEvents(
        playerId: playerId,
        events: events,
        totalDartsThrown: totalDartsThrown,
        gameTypesById: gameTypesById,
      );
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException(
          'Failed to compute achievement metrics: ${e.toString()}');
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
      final gameType = parseGameTypeFromColumn(game.gameType);

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
                source: parseEventSourceFromColumn(row.source),
              ))
          .toList();

      // 4. Delegate.
      return _assembler.playerStatsForGameFromEvents(
        playerId: playerId,
        gameType: gameType,
        playerDartsInGame: playerDartsInGame,
        playerScoreInGame: playerScoreInGame,
        events: events,
        outStrategy: _outStrategyFromConfig(game.configJson),
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
    // Watch both `dart_throws` and `game_events`. Event-only writes
    // (LegCompleted, GameCompleted, empty-turn busts via TurnEnded) must
    // re-trigger the stream — watching dart_throws alone misses them
    // (issue #129). We can't filter to this player at the table-update layer
    // since updates are table-granular; `getPlayerStats` does the per-player
    // scoping on each refresh.
    final tableUpdates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.dartThrows, _db.gameEvents]),
    );

    return _emitInitialThenOn(tableUpdates)
        .asyncMap((_) async => getPlayerStats(playerId, gameType: gameType))
        .handleError((error) {
      if (error is RepositoryException) throw error;
      throw StatisticsException(
          'Failed to watch player statistics: ${error.toString()}');
    });
  }

  @override
  Future<List<DartPosition>> getDartPositions({
    String? gameId,
    required String playerId,
    GameType? gameType,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      // 1. Verify player exists (parity with the other per-player methods).
      final playerExists = await (_db.select(_db.players)
                ..where((p) => p.playerId.equals(playerId))
                ..limit(1))
              .getSingleOrNull() !=
          null;
      if (!playerExists) {
        throw PlayerNotFoundException(playerId);
      }

      // Raw per-dart positions — read `dart_throws` directly (NOT via the
      // assembler; positions are facts, not a computed stat). Only located
      // darts (x/y not NULL) are returned. The `games` join is always present
      // so we can gate on `is_complete = 1` — in-progress darts must never leak
      // into any result, matching every other stats query here.
      final query = _db.selectOnly(_db.dartThrows)
        ..addColumns([
          _db.dartThrows.x,
          _db.dartThrows.y,
          _db.dartThrows.segment,
        ])
        ..join([
          innerJoin(_db.games,
              _db.games.gameId.equalsExp(_db.dartThrows.gameId)),
        ]);
      query.where(_db.dartThrows.playerId.equals(playerId) &
          _db.dartThrows.x.isNotNull() &
          _db.dartThrows.y.isNotNull() &
          _db.games.isComplete.equals(1));
      if (gameId != null) {
        query.where(_db.dartThrows.gameId.equals(gameId));
      }
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

      final rows = await query.get();
      return rows
          .map((r) => DartPosition(
                x: r.read(_db.dartThrows.x)!,
                y: r.read(_db.dartThrows.y)!,
                segment: r.read(_db.dartThrows.segment),
              ))
          .toList();
    } on RepositoryException {
      rethrow;
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve dart positions: ${e.toString()}');
    }
  }

  // ── Helper methods ──────────────────────────────────────────────────────────

  /// Yields once immediately, then again on every table update emission.
  ///
  /// `_db.tableUpdates(...)` only fires on actual writes, so a fresh listener
  /// would otherwise wait for a write before receiving anything. The watched
  /// stats streams contract requires a prompt initial emission so consumers
  /// can render the current snapshot (see the `watchPlayerStats` "emits an
  /// initial value promptly without waiting on a poll tick" regression test
  /// in the contract suite). Emitting a leading `null` synthesises that
  /// initial tick without losing any subsequent table-update notifications.
  Stream<void> _emitInitialThenOn(Stream<dynamic> updates) async* {
    yield null;
    yield* updates;
  }

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
    String cricketTargetMode = 'fixed',
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
            return cfg['startingScore'] == startingScore;
          } catch (_) {
            return false;
          }
        }).toList();
      }
      if (variant != null) {
        filtered = filtered.where((g) {
          try {
            final cfg = jsonDecode(g.configJson) as Map<String, dynamic>;
            // New configs serialize cricket scoring under `scoring`; legacy
            // payloads use `variant`. See cricket target-modes design §2.
            final scoring = cfg['scoring'] ?? cfg['variant'];
            return scoring == variant;
          } catch (_) {
            return false;
          }
        }).toList();
      }
      // Cricket target-mode cohort filter (see counterpart comment on
      // getPlayerStats for rationale).
      if (gameType == GameType.cricket) {
        filtered = filtered.where((g) {
          try {
            final cfg = jsonDecode(g.configJson) as Map<String, dynamic>;
            final mode = cfg['targetMode'] ?? 'fixed';
            return mode == cricketTargetMode;
          } catch (_) {
            return cricketTargetMode == 'fixed';
          }
        }).toList();
      }

      if (filtered.isEmpty) return [];

      // Per-leg accumulation lives in `PlayerStatsAssembler.legHistoryFromEvents`
      // (CLAUDE.md "Statistics loader vs computation"). The loader's job is
      // limited to: load events for the filtered games, materialise them as
      // domain events, group by gameId, delegate; concatenate; apply the
      // trailing limit.
      //
      // Single batched event query (replaces the previous N+1 — one query
      // per game). Sorted by (game_id, local_sequence) per the CLAUDE.md
      // rule that `local_sequence` is per-game and any multi-game event
      // query MUST sort that way so projection state doesn't bleed across
      // game boundaries.
      final gameIds = [for (final g in filtered) g.gameId];
      final eventRows = await (_db.select(_db.gameEvents)
            ..where((e) => e.gameId.isIn(gameIds))
            ..orderBy([
              (e) => OrderingTerm.asc(e.gameId),
              (e) => OrderingTerm.asc(e.localSequence),
            ]))
          .get();

      final eventsByGame = <String, List<domain.GameEvent>>{};
      for (final event in eventRows) {
        (eventsByGame[event.gameId] ??= <domain.GameEvent>[]).add(
          domain.GameEvent(
            eventId: event.eventId,
            gameId: event.gameId,
            eventType: event.eventType,
            localSequence: event.localSequence,
            occurredAt: DateTime.parse(event.occurredAt),
            payload: jsonDecode(event.payloadJson) as Map<String, dynamic>,
            synced: event.synced == 1,
            actorId: event.actorId,
            globalSequence: event.globalSequence,
            source: parseEventSourceFromColumn(event.source),
          ),
        );
      }

      final List<PlayerLegSnapshot> snapshots = [];
      int legIndex = 0;

      // Iterate `filtered` to preserve the start_time ASC ordering set up
      // by the games query.
      for (final gameRow in filtered) {
        final gameId = gameRow.gameId;
        final gameDate =
            DateTime.tryParse(gameRow.startTime) ?? DateTime.now();
        int? gamStartingScore;
        String gameAtcVariant = 'standard';
        String gameOutStrategy = 'double';
        try {
          final cfg = jsonDecode(gameRow.configJson) as Map<String, dynamic>;
          gamStartingScore = cfg['startingScore'] as int?;
          gameAtcVariant = cfg['variant'] as String? ?? gameAtcVariant;
          gameOutStrategy = cfg['outStrategy'] as String? ?? gameOutStrategy;
        } catch (_) {}

        final domainEvents =
            eventsByGame[gameId] ?? const <domain.GameEvent>[];

        final gameSnapshots = _assembler.legHistoryFromEvents(
          playerId: playerId,
          gameId: gameId,
          gameDate: gameDate,
          gameType: gameType,
          startingScore: gamStartingScore,
          events: domainEvents,
          startingLegIndex: legIndex,
          atcVariant: gameAtcVariant,
          outStrategy: gameOutStrategy,
        );
        snapshots.addAll(gameSnapshots);
        legIndex += gameSnapshots.length;
      }

      // Apply limit by taking last N items (most recent legs).
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
          final score = cfg['startingScore'] as int?;
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
      // Join through competitors/competitor_players (the "this player
      // participated" relation) rather than dart_throws. The previous join
      // dropped cricket games where the player was registered as a
      // competitor but threw no darts — e.g. a game they joined then
      // abandoned, or a multi-competitor game that ended before they took
      // a turn. Sister method getPlayerX01StartingScores already uses this
      // join shape (#193).
      //
      // New configs serialise the cricket scoring axis as `scoring`; legacy
      // configs use the single `variant` key. `COALESCE` lets one query
      // surface both. Restricted to `targetMode = 'fixed'` (or absent =
      // legacy) so the picker doesn't list Random/Crazy values here once
      // those modes land — they get their own cohort.
      final sql = '''
        SELECT DISTINCT COALESCE(
          JSON_EXTRACT(g.config_json, '\$.scoring'),
          JSON_EXTRACT(g.config_json, '\$.variant')
        ) AS variant
        FROM games g
        JOIN competitors c ON g.game_id = c.game_id
        JOIN competitor_players cp ON c.competitor_id = cp.competitor_id
        WHERE g.game_type = 'cricket'
        AND g.is_complete = 1
        AND cp.player_id = ?
        AND COALESCE(JSON_EXTRACT(g.config_json, '\$.targetMode'), 'fixed') = 'fixed'
        AND COALESCE(
          JSON_EXTRACT(g.config_json, '\$.scoring'),
          JSON_EXTRACT(g.config_json, '\$.variant')
        ) IS NOT NULL
      ''';

      final rows = await _db
          .customSelect(sql, variables: [Variable.withString(playerId)]).get();
      return rows
          .map((r) => r.data['variant'] as String?)
          .whereType<String>()
          .toList();
    } catch (e) {
      throw StatisticsException(
          'Failed to retrieve cricket variants: ${e.toString()}');
    }
  }

  /// Aggregate X01 checkout stats for [playerId] across all relevant games.
}
