// Repository Exception Hierarchy
// Defines all exceptions thrown by repository implementations

sealed class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);
}

// Player Exceptions
final class PlayerNotFoundException extends RepositoryException {
  final String playerId;
  const PlayerNotFoundException(this.playerId)
      : super('Player not found: $playerId');
}

final class DuplicatePlayerException extends RepositoryException {
  final String playerId;
  const DuplicatePlayerException(this.playerId)
      : super('Player already exists: $playerId');
}

final class PlayerHasGameHistoryException extends RepositoryException {
  const PlayerHasGameHistoryException(super.reason);
}

// Game Exceptions
final class GameNotFoundException extends RepositoryException {
  final String gameId;
  const GameNotFoundException(this.gameId)
      : super('Game not found: $gameId');
}

final class DuplicateGameException extends RepositoryException {
  final String gameId;
  const DuplicateGameException(this.gameId)
      : super('Game already exists: $gameId');
}

final class GameAlreadyCompleteException extends RepositoryException {
  final String gameId;
  const GameAlreadyCompleteException(this.gameId)
      : super('Game is already complete: $gameId');
}

final class InvalidCompetitorException extends RepositoryException {
  const InvalidCompetitorException(super.reason);
}

// Dart Throw Exceptions
final class DartNotFoundException extends RepositoryException {
  final String dartId;
  const DartNotFoundException(this.dartId)
      : super('Dart throw not found: $dartId');
}

final class DuplicateDartException extends RepositoryException {
  final String dartId;
  const DuplicateDartException(this.dartId)
      : super('Dart throw already exists: $dartId');
}

// Game Event Exceptions
final class SequenceConflictException extends RepositoryException {
  final String gameId;
  final int localSequence;
  const SequenceConflictException(this.gameId, this.localSequence)
      : super('Sequence $localSequence already taken in game $gameId');
}