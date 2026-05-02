// Game Repository Implementation
// Concrete implementation of GameRepository interface using SQLite

import 'package:sqflite/sqflite.dart';

import 'dart:convert';

import '../../domain/entities/game.dart';
import '../../domain/entities/competitor.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/models/game_state_snapshot.dart';
import 'package:dart_lodge/core/error/repository_exception.dart' hide DatabaseException;
import 'package:dart_lodge/core/utils/constants.dart';

class GameRepositoryImpl implements GameRepository {
  final Database _db;

  GameRepositoryImpl(this._db);

  @override
  Future<Game?> getActiveGame() async {
    // First, check if there are multiple incomplete games
    final countResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM games WHERE is_complete = 0',
    );
    final count = countResult.first['count'] as int;
    
    if (count > 1) {
      throw const MultipleActiveGamesException();
    }

    if (count == 0) return null;

    // Only one incomplete game exists, return it
    final result = await _db.query(
      'games',
      where: 'is_complete = 0',
      limit: 1,
    );

    final map = Map<String, dynamic>.from(result.first);
    map['config_json'] = jsonDecode(map['config_json'] as String);
    if (map['game_state_json'] != null) {
      map['game_state_json'] = jsonDecode(map['game_state_json'] as String);
    }
    return Game.fromJson(map);
  }

  @override
  Future<Game?> getGame(String gameId) async {
    final result = await _db.query(
      'games',
      where: 'game_id = ?',
      whereArgs: [gameId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    final map = Map<String, dynamic>.from(result.first);
    map['config_json'] = jsonDecode(map['config_json'] as String);
    if (map['game_state_json'] != null) {
      map['game_state_json'] = jsonDecode(map['game_state_json'] as String);
    }
    return Game.fromJson(map);
  }

  @override
  Future<List<Game>> getCompletedGames({
    int limit = 20,
    int offset = 0,
    GameType? filterByType,
  }) async {
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (filterByType != null) {
      whereClause = 'is_complete = 1 AND game_type = ?';
      whereArgs = [filterByType.name];
    } else {
      whereClause = 'is_complete = 1';
    }

    final results = await _db.query(
      'games',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'end_time DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((row) {
      final map = Map<String, dynamic>.from(row);
      map['config_json'] = jsonDecode(map['config_json'] as String);
      if (map['game_state_json'] != null) {
        map['game_state_json'] = jsonDecode(map['game_state_json'] as String);
      }
      return Game.fromJson(map);
    }).toList();
  }

  @override
  Future<List<Competitor>> getCompetitors(String gameId) async {
    // Get competitors for the game
    final competitorsResult = await _db.query(
      'competitors',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
    
    if (competitorsResult.isEmpty) return [];
    
    final competitors = <Competitor>[];
    
    for (final competitorRow in competitorsResult) {
      // Get players for this competitor
      final playersResult = await _db.query(
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
    
    try {
      await _db.transaction((txn) async {
        // Check for duplicate game ID
        final existing = await txn.query(
          'games',
          where: 'game_id = ?',
          whereArgs: [game.gameId],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          throw DuplicateGameException(game.gameId);
        }

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
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        // Check if this is the active game constraint violation
        if (e.toString().contains('idx_games_single_active') || 
            e.toString().contains('is_complete')) {
          throw const ActiveGameAlreadyExistsException();
        }
        // For other unique constraint violations, check if it's a duplicate game ID
        if (e.toString().contains('game_id') || e.toString().contains('PRIMARY KEY')) {
          throw DuplicateGameException(game.gameId);
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> saveGameState(String gameId, GameStateSnapshot state) async {
    // Check if game exists and is not complete
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
    
    await _db.update(
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
    // Check if game exists and is not already complete
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
    
    await _db.update(
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
    return Stream.fromFuture(getActiveGame());
  }

  @override
  Stream<List<Game>> watchCompletedGames({GameType? filterByType}) {
    return Stream.fromFuture(getCompletedGames(filterByType: filterByType));
  }
}