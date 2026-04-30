// Game Repository Drift Implementation
// Concrete implementation of GameRepository interface using Drift

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_state_snapshot.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import '../database.dart' as drift_db;




class GameRepositoryDrift implements GameRepository {
  final drift_db.AppDatabase _db;

  GameRepositoryDrift(this._db);

  @override
  Future<Game?> getGame(String gameId) async {
    final query = _db.select(_db.games)
      ..where((t) => t.gameId.equals(gameId))
      ..limit(1);

    final result = await query.getSingleOrNull();

    if (result == null) return null;
    
    return Game(
      gameId: result.gameId,
      gameType: _parseGameType(result.gameType),
      config: GameConfig.fromJson(json.decode(result.configJson)),
      startTime: DateTime.parse(result.startTime),
      endTime: result.endTime != null ? DateTime.parse(result.endTime!) : null,
      winnerCompetitorId: result.winnerCompetitorId,
      isComplete: result.isComplete == 1,
      activeState: result.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(result.gameStateJson!)) : null,
    );
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
      await _db.transaction(() async {
        // Check for duplicate game_id inside the transaction to avoid TOCTOU race.
        final existing = await (_db.select(_db.games)
              ..where((t) => t.gameId.equals(game.gameId))
              ..limit(1))
            .getSingleOrNull();
        if (existing != null) {
          throw DuplicateGameException(game.gameId);
        }

        // Insert game
        await _db.into(_db.games).insert(
          drift_db.GamesCompanion.insert(
            gameId: game.gameId,
            gameType: game.gameType.name,
            configJson: json.encode(game.config.toJson()),
            startTime: game.startTime.toIso8601String(),
            endTime: Value.absentIfNull(game.endTime?.toIso8601String()),
            winnerCompetitorId: Value.absentIfNull(game.winnerCompetitorId),
            isComplete: Value(game.isComplete == true ? 1 : 0),
            gameStateJson: Value.absentIfNull(game.activeState?.toJson() != null ? json.encode(game.activeState!.toJson()) : null),
          ),
          mode: InsertMode.insertOrFail,
        );

        // Insert competitors
        for (final competitor in competitors) {
          await _db.into(_db.competitors).insert(
            drift_db.CompetitorsCompanion.insert(
              competitorId: competitor.competitorId,
              gameId: game.gameId,
              type: competitor.type.name,
              name: competitor.name,
            ),
            mode: InsertMode.insertOrFail,
          );

          // Insert competitor players
          for (final player in competitor.players) {
            await _db.into(_db.competitorPlayers).insert(
              drift_db.CompetitorPlayersCompanion.insert(
                competitorId: competitor.competitorId,
                playerId: player.playerId,
                rotationPosition: player.rotationPosition,
              ),
              mode: InsertMode.insertOrFail,
            );
          }
        }
      });
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('is_complete') || msg.contains('idx_games_single_active')) {
        throw const ActiveGameAlreadyExistsException();
      }
      rethrow;
    }
  }

  @override
  Future<void> completeGame({
    required String gameId,
    required String? winnerCompetitorId,
    required DateTime endTime,
  }) async {
    // Pre-check: game must exist and not already be complete
    final existing = await (_db.select(_db.games)
          ..where((t) => t.gameId.equals(gameId))
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      throw GameNotFoundException(gameId);
    }

    if (existing.isComplete == 1) {
      throw GameAlreadyCompleteException(gameId);
    }

    await (_db.update(_db.games)
      ..where((t) => t.gameId.equals(gameId)))
      .write(
        drift_db.GamesCompanion(
          isComplete: const Value(1),
          winnerCompetitorId: Value(winnerCompetitorId),
          endTime: Value(endTime.toIso8601String()),
          gameStateJson: const Value(null), // Clear active state
        ),
      );
  }

  @override
  Future<Game?> getActiveGame() async {
    final query = _db.select(_db.games)
      ..where((t) => t.isComplete.equals(0))
      ..limit(1);

    final result = await query.getSingleOrNull();

    if (result == null) return null;
    
    return Game(
      gameId: result.gameId,
      gameType: _parseGameType(result.gameType),
      config: GameConfig.fromJson(json.decode(result.configJson)),
      startTime: DateTime.parse(result.startTime),
      endTime: result.endTime != null ? DateTime.parse(result.endTime!) : null,
      winnerCompetitorId: result.winnerCompetitorId,
      isComplete: result.isComplete == 1,
      activeState: result.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(result.gameStateJson!)) : null,
    );
  }

  @override
  Future<List<Competitor>> getCompetitors(String gameId) async {
    // Join competitors with competitor_players and players tables
    final query = _db.select(_db.competitors)
      ..where((c) => c.gameId.equals(gameId));

    final joinedQuery = query.join([
      leftOuterJoin(
        _db.competitorPlayers,
        _db.competitorPlayers.competitorId.equalsExp(_db.competitors.competitorId),
      ),
      leftOuterJoin(
        _db.players,
        _db.players.playerId.equalsExp(_db.competitorPlayers.playerId),
      ),
    ]);

    final results = await joinedQuery.get();

    // Group results by competitor_id to build nested structure
    final competitorMap = <String, Map<String, dynamic>>{};
    
    for (final row in results) {
      final competitorRow = row.readTable(_db.competitors);
      final competitorPlayerRow = row.readTableOrNull(_db.competitorPlayers);
      final playerRow = row.readTableOrNull(_db.players);

      // Create or get existing competitor data
      final competitorData = competitorMap.putIfAbsent(
        competitorRow.competitorId,
        () => {
          'competitorId': competitorRow.competitorId,
          'gameId': competitorRow.gameId,
          'type': _parseCompetitorType(competitorRow.type),
          'name': competitorRow.name,
          'players': <CompetitorPlayer>[],
        },
      );

      // Add player if this row has player data
      if (competitorPlayerRow != null) {
        competitorData['players'].add(CompetitorPlayer(
          playerId: competitorPlayerRow.playerId,
          rotationPosition: competitorPlayerRow.rotationPosition,
        ));
      }
    }

    // Convert to Competitor objects with proper ordering
    return competitorMap.values.map((data) {
      // Sort players by rotationPosition to ensure correct order
      final sortedPlayers = List<CompetitorPlayer>.from(data['players'] as List<CompetitorPlayer>)
        ..sort((a, b) => a.rotationPosition.compareTo(b.rotationPosition));
      
      return Competitor(
        competitorId: data['competitorId'],
        gameId: data['gameId'],
        type: data['type'],
        name: data['name'],
        players: sortedPlayers,
      );
    }).toList();
  }

  // Helper method to parse competitor type from string
  CompetitorType _parseCompetitorType(String typeString) {
    return CompetitorType.values.firstWhere(
      (type) => type.name == typeString,
      orElse: () => throw DatabaseException(
        'Unknown competitor type in database: $typeString',
      ),
    );
  }

  @override
  Future<List<Game>> getCompletedGames({
    int limit = 20,
    int offset = 0,
    GameType? filterByType,
  }) async {
    final query = _db.select(_db.games)
      ..where((t) => t.isComplete.equals(1))
      ..orderBy([(t) => OrderingTerm(expression: t.endTime, mode: OrderingMode.desc)])
      ..limit(limit, offset: offset);

    if (filterByType != null) {
      query.where((t) => t.gameType.equals(filterByType.name));
    }

    final results = await query.get();

    return results.map((row) => Game(
      gameId: row.gameId,
      gameType: _parseGameType(row.gameType),
      config: GameConfig.fromJson(json.decode(row.configJson)),
      startTime: DateTime.parse(row.startTime),
      endTime: row.endTime != null ? DateTime.parse(row.endTime!) : null,
      winnerCompetitorId: row.winnerCompetitorId,
      isComplete: row.isComplete == 1,
      activeState: row.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(row.gameStateJson!)) : null,
    )).toList();
  }

  @override
  Future<void> saveGameState(String gameId, GameStateSnapshot state) async {
    // Pre-check: game must exist and not be complete
    final existing = await (_db.select(_db.games)
          ..where((t) => t.gameId.equals(gameId))
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      throw GameNotFoundException(gameId);
    }

    if (existing.isComplete == 1) {
      throw GameAlreadyCompleteException(gameId);
    }

    await (_db.update(_db.games)
      ..where((t) => t.gameId.equals(gameId)))
      .write(
        drift_db.GamesCompanion(
          gameStateJson: Value(json.encode(state.toJson())),
        ),
      );
  }

  @override
  Stream<Game?> watchActiveGame() {
    return (_db.select(_db.games)
      ..where((t) => t.isComplete.equals(0))
      ..limit(1))
      .watchSingleOrNull()
      .map((row) => row != null ? Game(
            gameId: row.gameId,
            gameType: _parseGameType(row.gameType),
            config: GameConfig.fromJson(json.decode(row.configJson)),
            startTime: DateTime.parse(row.startTime),
            endTime: row.endTime != null ? DateTime.parse(row.endTime!) : null,
            winnerCompetitorId: row.winnerCompetitorId,
            isComplete: row.isComplete == 1,
            activeState: row.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(row.gameStateJson!)) : null,
          ) : null);
  }

  @override
  Stream<List<Game>> watchCompletedGames({GameType? filterByType}) {
    final query = _db.select(_db.games)
      ..where((t) => t.isComplete.equals(1))
      ..orderBy([(t) => OrderingTerm(expression: t.endTime, mode: OrderingMode.desc)]);

    if (filterByType != null) {
      query.where((t) => t.gameType.equals(filterByType.name));
    }

    return query.watch()
      .map((rows) => rows.map((row) => Game(
            gameId: row.gameId,
            gameType: _parseGameType(row.gameType),
            config: GameConfig.fromJson(json.decode(row.configJson)),
            startTime: DateTime.parse(row.startTime),
            endTime: row.endTime != null ? DateTime.parse(row.endTime!) : null,
            winnerCompetitorId: row.winnerCompetitorId,
            isComplete: row.isComplete == 1,
            activeState: row.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(row.gameStateJson!)) : null,
          )).toList());
  }

  // Helper method to parse game type from string
  GameType _parseGameType(String gameTypeString) {
    return GameType.values.firstWhere(
      (type) => type.name == gameTypeString,
      orElse: () => throw DatabaseException(
        'Unknown game type in database: $gameTypeString',
      ),
    );
  }

}