// Player Repository Implementation
// Concrete implementation of PlayerRepository interface using SQLite

import 'package:sqflite/sqflite.dart';

import '../../../features/players/domain/entities/player.dart';
import '../../../features/players/domain/repositories/player_repository.dart';
import '../../../core/error/repository_exception.dart';
import '../database_helper.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final DatabaseHelper _dbHelper;

  PlayerRepositoryImpl(this._dbHelper);

  @override
  Future<Player?> getPlayer(String playerId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'players',
      where: 'player_id = ?',
      whereArgs: [playerId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Player.fromJson(result.first);
  }

  @override
  Future<List<Player>> getAllPlayers() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'players',
      orderBy: 'name ASC',
    );

    return results.map((json) => Player.fromJson(json)).toList();
  }

  @override
  Future<void> createPlayer(Player player) async {
    final db = await _dbHelper.database;

    // Check if player with same name already exists
    final existing = await db.query(
      'players',
      where: 'name = ?',
      whereArgs: [player.name],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw DuplicatePlayerException('Player with name "${player.name}" already exists');
    }

    await db.insert(
      'players',
      {
        'player_id': player.playerId,
        'name': player.name,
        'created_at': player.createdAt.toIso8601String(),
        'last_active': player.lastActive.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<void> updatePlayer(Player player) async {
    final db = await _dbHelper.database;

    // Check if player exists
    final existing = await db.query(
      'players',
      where: 'player_id = ?',
      whereArgs: [player.playerId],
      limit: 1,
    );

    if (existing.isEmpty) {
      throw PlayerNotFoundException(player.playerId);
    }

    await db.update(
      'players',
      {
        'name': player.name,
        'last_active': player.lastActive.toIso8601String(),
      },
      where: 'player_id = ?',
      whereArgs: [player.playerId],
    );
  }

  Future<void> deletePlayer(String playerId) async {
    final db = await _dbHelper.database;

    // Check if player has any dart throws (can't delete if they have game history)
    final dartThrows = await db.query(
      'dart_throws',
      where: 'player_id = ?',
      whereArgs: [playerId],
      limit: 1,
    );

    if (dartThrows.isNotEmpty) {
      throw PlayerHasGameHistoryException(
        'Cannot delete player with game history'
      );
    }

    // Check if player is in any competitors
    final competitors = await db.query(
      'competitor_players',
      where: 'player_id = ?',
      whereArgs: [playerId],
      limit: 1,
    );

    if (competitors.isNotEmpty) {
      throw PlayerHasGameHistoryException(
        'Cannot delete player who is part of a competitor'
      );
    }

    await db.delete(
      'players',
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
  }

  Future<void> updatePlayerLastActive(String playerId, DateTime lastActive) async {
    final db = await _dbHelper.database;

    await db.update(
      'players',
      {
        'last_active': lastActive.toIso8601String(),
      },
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
  }

  @override
  Future<void> updatePlayerName(String playerId, String name) async {
    final db = await _dbHelper.database;

    // Check if player exists
    final existing = await db.query(
      'players',
      where: 'player_id = ?',
      whereArgs: [playerId],
      limit: 1,
    );

    if (existing.isEmpty) {
      throw PlayerNotFoundException(playerId);
    }

    await db.update(
      'players',
      {
        'name': name,
      },
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
  }

  @override
  Future<void> touchPlayer(String playerId) async {
    final db = await _dbHelper.database;

    // Check if player exists
    final existing = await db.query(
      'players',
      where: 'player_id = ?',
      whereArgs: [playerId],
      limit: 1,
    );

    if (existing.isEmpty) {
      throw PlayerNotFoundException(playerId);
    }

    await db.update(
      'players',
      {
        'last_active': DateTime.now().toIso8601String(),
      },
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
  }

  @override
  Stream<List<Player>> watchAllPlayers() {
    // TODO: Implement stream for player changes
    throw UnimplementedError('watchAllPlayers not yet implemented');
  }
}