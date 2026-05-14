// Game Event Repository Interface
// Defines the contract for game event data access

import '../entities/game_event.dart';

abstract interface class GameEventRepository {
  // Queries

  /// Returns all events for [gameId] ordered by [localSequence] ascending.
  Future<List<GameEvent>> getEventsForGame(String gameId);

  /// Returns events for [gameId] with [localSequence] greater than
  /// [afterSequence], ordered ascending. Used for incremental replay.
  Future<List<GameEvent>> getEventsSince(String gameId, int afterSequence);

  /// Returns all events that have not yet been confirmed by the backend
  /// ([synced = false]), ordered by (game_id, local_sequence).
  Future<List<GameEvent>> getUnsyncedEvents();

  /// Returns the highest [localSequence] for [gameId], or 0 if no events
  /// exist. Callers compute `getLatestSequence(...) + 1` to assign the next
  /// sequence; with the 0 sentinel, the first event of every game lands at
  /// `local_sequence = 1` (1-based, restarts per game).
  Future<int> getLatestSequence(String gameId);

  // Writes

  /// Appends a single event. Silently ignores a duplicate [event.eventId].
  /// Throws [GameNotFoundException] if [event.gameId] does not exist.
  /// Throws [GameNotEditableException] if the target game is already complete
  /// (the event log is read-only after `completeGame`).
  /// Throws [SequenceConflictException] if [event.localSequence] is already
  /// taken by a different event ID for the same game.
  Future<void> appendEvent(GameEvent event);

  /// Appends multiple events in a single transaction. All-or-nothing.
  /// All events must share the same [gameId]; otherwise throws
  /// [ValidationException].
  /// Throws [GameNotFoundException] if the target game does not exist, or
  /// [GameNotEditableException] if the target game is already complete.
  /// Throws [SequenceConflictException] on any sequence collision (rolls back).
  Future<void> appendEvents(List<GameEvent> events);

  /// Marks [eventIds] as synced ([synced = true]) inside a single transaction.
  /// Throws [EventNotFoundException] if any ID does not exist; on failure the
  /// transaction is rolled back so no partial updates land.
  Future<void> markSynced(List<String> eventIds);

  /// Updates the [globalSequence] for specific events after server confirmation,
  /// inside a single transaction. Throws [EventNotFoundException] if any ID
  /// does not exist; on failure the transaction is rolled back so no partial
  /// updates land.
  Future<void> updateGlobalSequences(Map<String, int> eventIdToSequence);

  // Streams

  /// Emits the full ordered event list for [gameId] whenever a new event
  /// is appended. Used for live game state reconstruction.
  Stream<List<GameEvent>> watchEventsForGame(String gameId);
}