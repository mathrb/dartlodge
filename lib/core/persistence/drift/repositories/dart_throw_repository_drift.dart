// Dart Throw Repository Drift Implementation
// Concrete implementation of DartThrowRepository interface using Drift

import 'package:drift/drift.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import '../database.dart' as drift_db;
import '../sqlite_error_codes.dart';

class DartThrowRepositoryDrift implements DartThrowRepository {
  final drift_db.AppDatabase _db;

  DartThrowRepositoryDrift(this._db);

  @override
  Future<List<DartThrow>> getDartsForGame(String gameId) async {
    final query = _db.select(_db.dartThrows)
      ..where((t) => t.gameId.equals(gameId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.turnNumber, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.dartNumber, mode: OrderingMode.asc),
      ]);

    final results = await query.get();

    return results.map((row) => DartThrow(
      dartId: row.dartId,
      gameId: row.gameId,
      competitorId: row.competitorId,
      playerId: row.playerId,
      turnNumber: row.turnNumber,
      dartNumber: row.dartNumber,
      segment: row.segment,
      score: row.score,
      x: row.x,
      y: row.y,
    )).toList();
  }

  @override
  Future<List<DartThrow>> getDartsForCompetitor(
      String gameId, String competitorId) async {
    final query = _db.select(_db.dartThrows)
      ..where((t) => t.gameId.equals(gameId) & t.competitorId.equals(competitorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.turnNumber, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.dartNumber, mode: OrderingMode.asc),
      ]);

    final results = await query.get();

    return results.map((row) => DartThrow(
      dartId: row.dartId,
      gameId: row.gameId,
      competitorId: row.competitorId,
      playerId: row.playerId,
      turnNumber: row.turnNumber,
      dartNumber: row.dartNumber,
      segment: row.segment,
      score: row.score,
      x: row.x,
      y: row.y,
    )).toList();
  }

  @override
  Future<List<DartThrow>> getDartsForPlayer(
    String playerId, {
    int limit = 100,
    int offset = 0,
  }) async {
    // Join with games to sort by game start_time descending (insertion proxy),
    // then by turn/dart number descending within each game.
    final query = _db.select(_db.dartThrows).join([
      innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId)),
    ])
      ..where(_db.dartThrows.playerId.equals(playerId))
      ..orderBy([
        OrderingTerm(expression: _db.games.startTime, mode: OrderingMode.desc),
        OrderingTerm(expression: _db.dartThrows.turnNumber, mode: OrderingMode.desc),
        OrderingTerm(expression: _db.dartThrows.dartNumber, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    final results = await query.get();

    return results.map((row) {
      final dt = row.readTable(_db.dartThrows);
      return DartThrow(
        dartId: dt.dartId,
        gameId: dt.gameId,
        competitorId: dt.competitorId,
        playerId: dt.playerId,
        turnNumber: dt.turnNumber,
        dartNumber: dt.dartNumber,
        segment: dt.segment,
        score: dt.score,
        x: dt.x,
        y: dt.y,
      );
    }).toList();
  }

  @override
  Future<void> insertDart(DartThrow dart) async {
    try {
      await _db.transaction(() async {
        // Pre-check and insert are wrapped in a transaction so a concurrent
        // completeGame can't slip between the gate read and the insert and
        // leave a dart on a just-finalized game (#189).
        final game = await (_db.select(_db.games)
              ..where((t) => t.gameId.equals(dart.gameId))
              ..limit(1))
            .getSingleOrNull();
        if (game == null) {
          throw GameNotFoundException(dart.gameId);
        }
        if (game.isComplete == 1) {
          throw GameAlreadyCompleteException(dart.gameId);
        }

        await _db.into(_db.dartThrows).insert(
          drift_db.DartThrowsCompanion.insert(
            dartId: dart.dartId,
            gameId: dart.gameId,
            competitorId: dart.competitorId,
            playerId: dart.playerId,
            turnNumber: dart.turnNumber,
            dartNumber: dart.dartNumber,
            segment: dart.segment,
            score: dart.score,
            x: Value.absentIfNull(dart.x),
            y: Value.absentIfNull(dart.y),
          ),
          mode: InsertMode.insertOrFail,
        );
      });
    } on Exception catch (e) {
      if (isUniqueConstraintViolation(e)) {
        throw DuplicateDartException(dart.dartId);
      }
      if (e is RepositoryException) rethrow;
      throw DatabaseException(
        'Failed to insert dart throw ${dart.dartId} for game ${dart.gameId}',
        cause: e,
      );
    }
  }

  @override
  Future<void> insertDarts(List<DartThrow> darts) async {
    if (darts.isEmpty) return;

    // Validate ALL darts target the same gameId. Pre-fix the code only
    // checked darts.first.gameId, so a malformed batch where later darts
    // referenced a different (possibly completed) game would slip past
    // the gate and either succeed against the wrong game or trip a
    // generic FK error (#189). Mirror appendEvents' same-game check.
    final gameIds = darts.map((d) => d.gameId).toSet();
    if (gameIds.length > 1) {
      throw DatabaseException(
        'insertDarts called with darts from multiple games: $gameIds',
      );
    }
    final gameId = darts.first.gameId;

    await _db.transaction(() async {
      // Pre-check and insert wrapped in the same transaction so a
      // concurrent completeGame can't slip in between (#189).
      final game = await (_db.select(_db.games)
            ..where((t) => t.gameId.equals(gameId))
            ..limit(1))
          .getSingleOrNull();
      if (game == null) {
        throw GameNotFoundException(gameId);
      }
      if (game.isComplete == 1) {
        throw GameAlreadyCompleteException(gameId);
      }

      for (final dart in darts) {
        try {
          await _db.into(_db.dartThrows).insert(
            drift_db.DartThrowsCompanion.insert(
              dartId: dart.dartId,
              gameId: dart.gameId,
              competitorId: dart.competitorId,
              playerId: dart.playerId,
              turnNumber: dart.turnNumber,
              dartNumber: dart.dartNumber,
              segment: dart.segment,
              score: dart.score,
              x: Value.absentIfNull(dart.x),
              y: Value.absentIfNull(dart.y),
            ),
            mode: InsertMode.insertOrFail,
          );
        } on Exception catch (e) {
          if (isUniqueConstraintViolation(e)) {
            throw DuplicateDartException(dart.dartId);
          }
          if (e is RepositoryException) rethrow;
          throw DatabaseException(
            'Failed to insert dart throw ${dart.dartId} for game ${dart.gameId}',
            cause: e,
          );
        }
      }
    });
  }

  @override
  Future<void> deleteDart(String dartId) async {
    await _db.transaction(() async {
      // Look up dart + game and delete inside one transaction so a
      // concurrent completeGame can't slip between the gate read and the
      // delete and leave a half-finished undo on a just-finalized game
      // (#189).
      final dart = await (_db.select(_db.dartThrows)
            ..where((t) => t.dartId.equals(dartId))
            ..limit(1))
          .getSingleOrNull();
      if (dart == null) {
        throw DartNotFoundException(dartId);
      }

      final game = await (_db.select(_db.games)
            ..where((t) => t.gameId.equals(dart.gameId))
            ..limit(1))
          .getSingleOrNull();
      if (game == null) {
        throw GameNotFoundException(dart.gameId);
      }
      if (game.isComplete == 1) {
        throw GameAlreadyCompleteException(dart.gameId);
      }

      await (_db.delete(_db.dartThrows)
            ..where((t) => t.dartId.equals(dartId)))
          .go();
    });
  }
}