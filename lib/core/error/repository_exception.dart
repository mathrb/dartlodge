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

/// Thrown by the data layer when a player INSERT conflicts on the primary
/// key (i.e. the [playerId] UUID is already in use). The Drift repository
/// surfaces this when `INSERT INTO players` violates the UNIQUE constraint.
/// For "a player with this NAME already exists" use
/// [DuplicatePlayerNameException] instead.
final class DuplicatePlayerException extends RepositoryException {
  final String playerId;
  const DuplicatePlayerException(this.playerId)
      : super('Player already exists: $playerId');
}

/// Thrown by the domain use case when a new player's name collides with an
/// existing player (case-insensitive). Distinct from [DuplicatePlayerException]
/// which is the data-layer's primary-key conflict signal.
final class DuplicatePlayerNameException extends RepositoryException {
  final String name;
  const DuplicatePlayerNameException(this.name)
      : super('A player with this name already exists: $name');
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

/// Thrown by [GameRepository.completeGame] when called against a game that
/// has already been finalized (`is_complete == 1`). Semantically scoped to
/// "completing a game twice"; for "editing after completion" use
/// [GameNotEditableException] instead.
final class GameAlreadyCompleteException extends RepositoryException {
  final String gameId;
  const GameAlreadyCompleteException(this.gameId)
      : super('Game is already complete: $gameId');
}

/// Thrown when an attempt is made to mutate a finalized game's event log or
/// throw history (`appendEvent`, `appendEvents`, `insertDart`, etc.) — i.e.
/// the target game has `is_complete == 1`.
///
/// Distinguished from [GameAlreadyCompleteException], which is reserved for
/// the `completeGame` double-finalization path. Both carry [gameId]; this
/// type signals "the game is frozen, the operation is rejected" rather than
/// "you can't complete a game twice".
final class GameNotEditableException extends RepositoryException {
  final String gameId;
  const GameNotEditableException(this.gameId)
      : super('Game is complete and not editable: $gameId');
}

final class ActiveGameAlreadyExistsException extends RepositoryException {
  const ActiveGameAlreadyExistsException()
      : super('An active game already exists - only one game can be active at a time');
}

final class InvalidCompetitorException extends RepositoryException {
  const InvalidCompetitorException(super.reason);
}

// Statistics Exceptions
final class StatisticsException extends RepositoryException {
  const StatisticsException(super.message);
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

// Game Engine Exceptions
final class InvalidGameStateException extends RepositoryException {
  const InvalidGameStateException(super.reason);
}

final class NoDartsToUndoException extends RepositoryException {
  final String gameId;
  const NoDartsToUndoException(this.gameId)
      : super('No darts to undo in current turn for game: $gameId');
}

// Infrastructure Exceptions
final class DatabaseException extends RepositoryException {
  final Object? cause;
  const DatabaseException(super.message, {this.cause});
}

// Game Event Exceptions
final class SequenceConflictException extends RepositoryException {
  final String gameId;
  final int localSequence;
  const SequenceConflictException(this.gameId, this.localSequence)
      : super('Sequence $localSequence already taken in game $gameId');
}

final class EventNotFoundException extends RepositoryException {
  final String eventId;
  const EventNotFoundException(this.eventId)
      : super('Event not found: $eventId');
}

// Validation Exceptions
final class ValidationException extends RepositoryException {
  const ValidationException(super.message);
}