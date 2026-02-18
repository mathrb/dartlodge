// Game Repository Implementation
// Concrete implementation of GameRepository interface using SQLite

import 'package:sqflite/sqflite.dart';

import 'dart:convert';

import '../../../features/game/domain/entities/game.dart';
import '../../../features/game/domain/entities/competitor.dart';
import '../../../features/game/domain/repositories/game_repository.dart';
import '../../../core/error/repository_exception.dart';
import '../../../core/utils/constants.dart';
import '../database_helper.dart';

class GameRepositoryImpl implements GameRepository {
  final DatabaseHelper _dbHelper;

  GameRepositoryImpl(this._dbHelper);

  @override
  Future<Game?> getActiveGame() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'games',
      where: 'is_complete = 0',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Game.fromJson(result.first);
  }

  @override
  Future<Game?> getGame(String gameId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'games',
      where: 'game_id = ?',
      whereArgs: [gameId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Game.fromJson(result.first);
  }

  @override
  Future<List<Game>> getCompletedGames({
    int limit = 20,
    int offset = 0,
    GameType? filterByType,
  }) async {
    final db = await _dbHelper.database;
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (filterByType != null) {
      whereClause = 'is_complete = 1 AND game_type = ?';
      whereArgs = [filterByType.name];
    } else {
      whereClause = 'is_complete = 1';
    }

    final results = await db.query(
      'games',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'end_time DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((json) => Game.fromJson(json)).toList();
  }

  @override
  Future<List<Competitor>> getCompetitors(String gameId) async {
    final db = await _dbHelper.database;
    
    // Get competitors for the game
    final competitorsResult = await db.query(
      'competitors',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
    
    if (competitorsResult.isEmpty) return [];
    
    final competitors = <Competitor>[];
    
    for (final competitorRow in competitorsResult) {
      // Get players for this competitor
      final playersResult = await db.query(
        'competitor_players',
        where: 'competitor_id = ?',
        whereArgs: [competitorRow['competitor_id'] as String],
        orderBy: 'rotation_position ASC',
      );
      
      final competitorPlayers = playersResult.map((row) => CompetitorPlayer(
        playerId: row['player_id'] as String,
        rotationPosition: row['rotation_position'] as int,
      )).toList();
      
      competitors.add(Competitor(
        competitorId: competitorRow['competitor_id'] as String,
        gameId: competitorRow['game_id'] as String,
        type: competitorRow['type'] == 'solo' ? CompetitorType.solo : CompetitorType.team,
        name: competitorRow['name'] as String,
        players: competitorPlayers,
      ));
    }
    
    return competitors;
  }

  @override
  Future<void> createGame(Game game, List<Competitor> competitors) async {
    final db = await _dbHelper.database;
    
    // Validate no player appears in multiple competitors
    final playerIds = <String>{};
    for (final competitor in competitors) {
      for (final player in competitor.players) {
        if (playerIds.contains(player.playerId)) {
          throw InvalidCompetitorException(
            'Player ${player.playerId} appears in multiple competitors'
          );
        }
        playerIds.add(player.playerId);
      }
    }
    
    await db.transaction((txn) async {
      // Insert game
      await txn.insert(
        'games',
        {
          'game_id': game.gameId,
          'game_type': game.gameType.name,
          'config_json': jsonEncode(game.config),
          'start_time': game.startTime.toIso8601String(),
          'end_time': game.endTime?.toIso8601String(),
          'winner_competitor_id': game.winnerCompetitorId,
          'is_complete': game.isComplete == true ? 1 : 0,
          'game_state_json': game.activeState != null ? jsonEncode(game.activeState) : null,
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      // Insert competitors
      for (final competitor in competitors) {
        await txn.insert(
          'competitors',
          {
            'competitor_id': competitor.competitorId,
            'game_id': competitor.gameId,
            'type': competitor.type.name,
            'name': competitor.name,
          },
          conflictAlgorithm: ConflictAlgorithm.fail,
        );

        // Insert competitor players
        for (final player in competitor.players) {
          await txn.insert(
            'competitor_players',
            {
              'competitor_id': competitor.competitorId,
              'player_id': player.playerId,
              'rotation_position': player.rotationPosition,
            },
            conflictAlgorithm: ConflictAlgorithm.fail,
          );
        }
      }
    });
  }

  @override
  Future<void> saveGameState(String gameId, Map<String, dynamic> state) async {
    final db = await _dbHelper.database;
    
    // Check if game exists and is not complete
    final game = await db.query(
      'games',
      where: 'game_id = ? AND is_complete = 0',
      whereArgs: [gameId],
      limit: 1,
    );
    
    if (game.isEmpty) {
      throw GameNotFoundException(gameId);
    }
    
    await db.update(
      'games',
      {
        'game_state_json': jsonEncode(state),
      },
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
  }

  @override
  Future<void> completeGame({
    required String gameId,
    required String? winnerCompetitorId,
    required DateTime endTime,
  }) async {
    final db = await _dbHelper.database;
    
    // Check if game exists and is not already complete
    final game = await db.query(
      'games',
      where: 'game_id = ? AND is_complete = 0',
      whereArgs: [gameId],
      limit: 1,
    );
    
    if (game.isEmpty) {
      throw GameNotFoundException(gameId);
    }
    
    await db.update(
      'games',
      {
        'is_complete': 1,
        'end_time': endTime.toIso8601String(),
        'winner_competitor_id': winnerCompetitorId,
        'game_state_json': null, // Clear active state
      },
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
  }

  @override
  Stream<Game?> watchActiveGame() {
    // TODO: Implement stream for active game changes
    throw UnimplementedError('watchActiveGame not yet implemented');
  }

  @override
  Stream<List<Game>> watchCompletedGames({GameType? filterByType}) {
    // TODO: Implement stream for completed games changes
    throw UnimplementedError('watchCompletedGames not yet implemented');
  }
}