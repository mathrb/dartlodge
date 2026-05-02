// Dart Throw Repository Implementation
// Concrete implementation of DartThrowRepository interface using SQLite

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/dart_throw.dart';
import '../../domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/core/error/repository_exception.dart' hide DatabaseException;

class DartThrowRepositoryImpl implements DartThrowRepository {
  final Database _db;

  DartThrowRepositoryImpl(this._db);

  @override
  Future<List<DartThrow>> getDartsForGame(String gameId) async {
    final results = await _db.query(
      'dart_throws',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'turn_number ASC, dart_number ASC',
    );

    return results.map((json) => DartThrow.fromJson(json)).toList();
  }

  @override
  Future<List<DartThrow>> getDartsForCompetitor(
      String gameId, String competitorId) async {
    final results = await _db.query(
      'dart_throws',
      where: 'game_id = ? AND competitor_id = ?',
      whereArgs: [gameId, competitorId],
      orderBy: 'turn_number ASC, dart_number ASC',
    );

    return results.map((json) => DartThrow.fromJson(json)).toList();
  }

  @override
  Future<List<DartThrow>> getDartsForPlayer(
    String playerId, {
    int limit = 100,
    int offset = 0,
  }) async {
    // Join with games to sort by game start_time descending (insertion proxy),
    // then by turn/dart number descending within each game.
    final results = await _db.rawQuery('''
      SELECT dt.*
      FROM dart_throws dt
      JOIN games g ON dt.game_id = g.game_id
      WHERE dt.player_id = ?
      ORDER BY g.start_time DESC, dt.turn_number DESC, dt.dart_number DESC
      LIMIT ? OFFSET ?
    ''', [playerId, limit, offset]);

    return results.map((json) => DartThrow.fromJson(json)).toList();
  }

  @override
  Future<void> insertDart(DartThrow dart) async {
    // Verify game exists and is not complete
    final game = await _db.query(
      'games',
      where: 'game_id = ?',
      whereArgs: [dart.gameId],
      limit: 1,
    );

    if (game.isEmpty) {
      throw GameNotFoundException(dart.gameId);
    }

    if (game.first['is_complete'] == 1) {
      throw GameAlreadyCompleteException(dart.gameId);
    }

    try {
      await _db.insert(
        'dart_throws',
        {
          'dart_id': dart.dartId,
          'game_id': dart.gameId,
          'competitor_id': dart.competitorId,
          'player_id': dart.playerId,
          'turn_number': dart.turnNumber,
          'dart_number': dart.dartNumber,
          'segment': dart.segment,
          'score': dart.score,
          'x': dart.x,
          'y': dart.y,
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
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
    final game = await _db.query(
      'games',
      where: 'game_id = ?',
      whereArgs: [gameId],
      limit: 1,
    );

    if (game.isEmpty) {
      throw GameNotFoundException(gameId);
    }

    if (game.first['is_complete'] == 1) {
      throw GameAlreadyCompleteException(gameId);
    }

    await _db.transaction((txn) async {
      for (final dart in darts) {
        try {
          await txn.insert(
            'dart_throws',
            {
              'dart_id': dart.dartId,
              'game_id': dart.gameId,
              'competitor_id': dart.competitorId,
              'player_id': dart.playerId,
              'turn_number': dart.turnNumber,
              'dart_number': dart.dartNumber,
              'segment': dart.segment,
              'score': dart.score,
              'x': dart.x,
              'y': dart.y,
            },
            conflictAlgorithm: ConflictAlgorithm.fail,
          );
        } on DatabaseException catch (e) {
          if (e.isUniqueConstraintError()) {
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
    final dart = await _db.query(
      'dart_throws',
      where: 'dart_id = ?',
      whereArgs: [dartId],
      limit: 1,
    );

    if (dart.isEmpty) {
      throw DartNotFoundException(dartId);
    }

    final gameId = dart.first['game_id'] as String;

    // Verify game is not complete
    final game = await _db.query(
      'games',
      where: 'game_id = ?',
      whereArgs: [gameId],
      limit: 1,
    );

    if (game.isEmpty) {
      throw GameNotFoundException(gameId);
    }

    if (game.first['is_complete'] == 1) {
      throw GameAlreadyCompleteException(gameId);
    }

    await _db.delete(
      'dart_throws',
      where: 'dart_id = ?',
      whereArgs: [dartId],
    );
  }
}