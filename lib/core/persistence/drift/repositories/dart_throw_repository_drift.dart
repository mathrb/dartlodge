// Dart Throw Repository Drift Implementation
// Concrete implementation of DartThrowRepository interface using Drift

import 'package:drift/drift.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import '../database.dart' as drift_db;

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
    // Verify game exists and is not complete
    final gameQuery = _db.select(_db.games)
      ..where((t) => t.gameId.equals(dart.gameId))
      ..limit(1);

    final game = await gameQuery.getSingleOrNull();

    if (game == null) {
      throw GameNotFoundException(dart.gameId);
    }

    if (game.isComplete == 1) {
      throw GameAlreadyCompleteException(dart.gameId);
    }

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
      // Handle drift-specific exceptions using DriftWrappedException
      if (e is DriftWrappedException) {
        final cause = e.cause.toString();
        if (cause.contains('UNIQUE constraint failed') ||
            cause.contains('unique constraint failed') ||
            cause.contains('already exists') ||
            cause.contains('constraint failed')) {
          throw DuplicateDartException(dart.dartId);
        }
      }
      // Handle SqliteException directly
      if (e.toString().contains('UNIQUE constraint failed') ||
          e.toString().contains('unique constraint failed') ||
          e.toString().contains('already exists') ||
          e.toString().contains('constraint failed')) {
        throw DuplicateDartException(dart.dartId);
      }
      rethrow;
    }
  }

  @override
  Future<void> insertDarts(List<DartThrow> darts) async {
    if (darts.isEmpty) return;

    // Verify all darts belong to the same game and it's not complete
    final gameId = darts.first.gameId;
    final gameQuery = _db.select(_db.games)
      ..where((t) => t.gameId.equals(gameId))
      ..limit(1);

    final game = await gameQuery.getSingleOrNull();

    if (game == null) {
      throw GameNotFoundException(gameId);
    }

    if (game.isComplete == 1) {
      throw GameAlreadyCompleteException(gameId);
    }

    await _db.transaction(() async {
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
          // Handle drift-specific exceptions using DriftWrappedException
          if (e is DriftWrappedException) {
            final cause = e.cause.toString();
            if (cause.contains('UNIQUE constraint failed') ||
                cause.contains('unique constraint failed') ||
                cause.contains('already exists') ||
                cause.contains('constraint failed')) {
              throw DuplicateDartException(dart.dartId);
            }
          }
          // Handle SqliteException directly
          if (e.toString().contains('UNIQUE constraint failed') ||
              e.toString().contains('unique constraint failed') ||
              e.toString().contains('already exists') ||
              e.toString().contains('constraint failed')) {
            throw DuplicateDartException(dart.dartId);
          }
          rethrow;
        }
      }
    });
  }

  @override
  Future<void> deleteDart(String dartId) async {
    // Get the dart to verify it exists and get game info
    final dartQuery = _db.select(_db.dartThrows)
      ..where((t) => t.dartId.equals(dartId))
      ..limit(1);

    final dart = await dartQuery.getSingleOrNull();

    if (dart == null) {
      throw DartNotFoundException(dartId);
    }

    final gameId = dart.gameId;

    // Verify game is not complete
    final gameQuery = _db.select(_db.games)
      ..where((t) => t.gameId.equals(gameId))
      ..limit(1);

    final game = await gameQuery.getSingleOrNull();

    if (game == null) {
      throw GameNotFoundException(gameId);
    }

    if (game.isComplete == 1) {
      throw GameAlreadyCompleteException(gameId);
    }

    await (_db.delete(_db.dartThrows)
      ..where((t) => t.dartId.equals(dartId)))
      .go();
  }
}