// Player Repository Implementation
// Concrete implementation of PlayerRepository interface using SQLite

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import 'package:dart_lodge/core/error/repository_exception.dart' hide DatabaseException;

class PlayerRepositoryImpl implements PlayerRepository {
  final Database _db;

  PlayerRepositoryImpl(this._db);

  @override
  Future<List<Player>> getAllPlayers() async {
    final results = await _db.query(
      'players',
      orderBy: 'last_active DESC',
    );

    return results.map((json) => Player.fromJson(json)).toList();
  }

  @override
  Future<Player?> getPlayer(String playerId) async {
    final result = await _db.query(
      'players',
      where: 'player_id = ?',
      whereArgs: [playerId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Player.fromJson(result.first);
  }

  @override
  Future<void> createPlayer(Player player) async {
    try {
      await _db.insert(
        'players',
        {
          'player_id': player.playerId,
          'name': player.name,
          'created_at': player.createdAt.toIso8601String(),
          'last_active': player.lastActive.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DuplicatePlayerException(player.playerId);
      }
      rethrow;
    }
  }

  @override
  Future<void> updatePlayerName(String playerId, String name) async {
    final rowsAffected = await _db.update(
      'players',
      {
        'name': name,
        'last_active': DateTime.now().toIso8601String(),
      },
      where: 'player_id = ?',
      whereArgs: [playerId],
    );

    if (rowsAffected == 0) {
      throw PlayerNotFoundException(playerId);
    }
  }

  @override
  Future<void> touchPlayer(String playerId) async {
    final rowsAffected = await _db.update(
      'players',
      {
        'last_active': DateTime.now().toIso8601String(),
      },
      where: 'player_id = ?',
      whereArgs: [playerId],
    );

    if (rowsAffected == 0) {
      throw PlayerNotFoundException(playerId);
    }
  }

  @override
  Future<void> deletePlayer(String playerId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM competitor_players WHERE player_id = ?',
      [playerId],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    if (count > 0) {
      throw const PlayerHasGameHistoryException('Player has game history');
    }

    final rowsAffected = await _db.delete(
      'players',
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
    if (rowsAffected == 0) throw PlayerNotFoundException(playerId);
  }

  @override
  Stream<List<Player>> watchAllPlayers() {
    return Stream.fromFuture(getAllPlayers());
  }
}