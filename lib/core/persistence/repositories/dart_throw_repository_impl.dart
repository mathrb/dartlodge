// Dart Throw Repository Implementation
// Concrete implementation of DartThrowRepository interface using SQLite

import 'package:sqflite/sqflite.dart';

import '../../../features/game/domain/entities/dart_throw.dart';
import '../../../features/game/domain/repositories/dart_throw_repository.dart';
import '../../../core/error/repository_exception.dart';
import '../database_helper.dart';

class DartThrowRepositoryImpl implements DartThrowRepository {
  final DatabaseHelper _dbHelper;

  DartThrowRepositoryImpl(this._dbHelper);

  @override
  Future<List<DartThrow>> getDartsForGame(String gameId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
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
    final db = await _dbHelper.database;
    final results = await db.query(
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
    final db = await _dbHelper.database;
    final results = await db.query(
      'dart_throws',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'game_id DESC, turn_number DESC, dart_number DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((json) => DartThrow.fromJson(json)).toList();
  }

  @override
  Future<void> insertDart(DartThrow dart) async {
    final db = await _dbHelper.database;

    // Verify game exists and is not complete
    final game = await db.query(
      'games',
      where: 'game_id = ? AND is_complete = 0',
      whereArgs: [dart.gameId],
      limit: 1,
    );

    if (game.isEmpty) {
      throw GameAlreadyCompleteException(dart.gameId);
    }

    await db.insert(
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
  }

  @override
  Future<void> insertDarts(List<DartThrow> darts) async {
    if (darts.isEmpty) return;

    final db = await _dbHelper.database;

    // Verify all darts belong to the same game and it's not complete
    final gameId = darts.first.gameId;
    final game = await db.query(
      'games',
      where: 'game_id = ? AND is_complete = 0',
      whereArgs: [gameId],
      limit: 1,
    );

    if (game.isEmpty) {
      throw GameAlreadyCompleteException(gameId);
    }

    await db.transaction((txn) async {
      for (final dart in darts) {
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
      }
    });
  }

  @override
  Future<void> deleteDart(String dartId) async {
    final db = await _dbHelper.database;

    // Get the dart to verify it exists and get game info
    final dart = await db.query(
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
    final game = await db.query(
      'games',
      where: 'game_id = ? AND is_complete = 0',
      whereArgs: [gameId],
      limit: 1,
    );

    if (game.isEmpty) {
      throw GameAlreadyCompleteException(gameId);
    }

    await db.delete(
      'dart_throws',
      where: 'dart_id = ?',
      whereArgs: [dartId],
    );
  }
}