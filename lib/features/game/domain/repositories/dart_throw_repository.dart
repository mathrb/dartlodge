// Dart Throw Repository Interface
// Defines the contract for dart throw data access

import '../entities/dart_throw.dart';

abstract interface class DartThrowRepository {
  // Queries

  /// Returns all dart throws for [gameId] ordered by
  /// (turn_number ASC, dart_number ASC).
  Future<List<DartThrow>> getDartsForGame(String gameId);

  /// Returns all dart throws in [gameId] for [competitorId], ordered by
  /// (turn_number ASC, dart_number ASC).
  Future<List<DartThrow>> getDartsForCompetitor(
      String gameId, String competitorId);

  /// Returns all dart throws by [playerId] across all games, ordered by
  /// insertion time descending. Supports pagination.
  Future<List<DartThrow>> getDartsForPlayer(
    String playerId, {
    int limit = 100,
    int offset = 0,
  });

  // Writes

  /// Inserts a single dart throw.
  /// Throws [DuplicateDartException] if [dart.dartId] already exists.
  /// Throws [GameNotFoundException] if [dart.gameId] does not exist.
  /// Throws [GameAlreadyCompleteException] if the game is already complete.
  Future<void> insertDart(DartThrow dart);

  /// Inserts multiple dart throws in a single transaction.
  /// All-or-nothing: if any insert fails, none are committed.
  Future<void> insertDarts(List<DartThrow> darts);

  /// Deletes the dart throw with [dartId].
  /// Used exclusively by the undo mechanism — only the most recent dart
  /// in an active game may be deleted.
  /// Throws [DartNotFoundException] if [dartId] does not exist.
  /// Throws [GameAlreadyCompleteException] if the game is already complete.
  Future<void> deleteDart(String dartId);
}