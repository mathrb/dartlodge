// Game Repository Interface
// Defines the contract for game data access

import '../entities/game.dart';
import '../entities/competitor.dart';
import '../../../../core/utils/constants.dart';

abstract interface class GameRepository {
  // Queries
  
  /// Returns the single active (non-complete) game, or null if none exists.
  Future<Game?> getActiveGame();

  /// Returns the game with [gameId], including its competitors.
  /// Returns null if not found.
  Future<Game?> getGame(String gameId);

  /// Returns all completed games ordered by [endTime] descending.
  /// [limit] and [offset] support pagination.
  Future<List<Game>> getCompletedGames({
    int limit = 20,
    int offset = 0,
    GameType? filterByType,
  });

  /// Returns all competitors for [gameId], each with their player roster.
  Future<List<Competitor>> getCompetitors(String gameId);

  // Writes

  /// Inserts [game] and all of its [competitors] atomically.
  /// [competitors] must contain at least one entry.
  /// Throws [DuplicateGameException] if [game.gameId] already exists.
  /// Throws [InvalidCompetitorException] if a player appears in more than
  /// one competitor.
  Future<void> createGame(Game game, List<Competitor> competitors);

  /// Overwrites the [activeState] column for [gameId].
  /// Throws [GameNotFoundException] if [gameId] does not exist.
  /// Throws [GameAlreadyCompleteException] if the game is already marked complete.
  Future<void> saveGameState(String gameId, Map<String, dynamic> state);

  /// Marks the game as complete: sets [isComplete = true], [endTime],
  /// and [winnerCompetitorId]. Clears [activeState].
  /// Throws [GameNotFoundException] if [gameId] does not exist.
  /// Throws [GameAlreadyCompleteException] if already complete.
  Future<void> completeGame({
    required String gameId,
    required String? winnerCompetitorId,
    required DateTime endTime,
  });

  // Streams

  /// Emits the active game (or null) whenever the active game row changes.
  Stream<Game?> watchActiveGame();

  /// Emits the completed games list whenever any game is completed.
  Stream<List<Game>> watchCompletedGames({GameType? filterByType});
}