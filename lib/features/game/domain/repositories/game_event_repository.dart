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

  /// Returns the highest [localSequence] for [gameId], or -1 if no events
  /// exist. Used to assign the next sequence number before insertion.
  Future<int> getLatestSequence(String gameId);

  // Writes

  /// Appends a single event. Silently ignores a duplicate [event.eventId].
  /// Throws [GameNotFoundException] if [event.gameId] does not exist.
  /// Throws [SequenceConflictException] if [event.localSequence] is already
  /// taken by a different event ID for the same game.
  Future<void> appendEvent(GameEvent event);

  /// Appends multiple events in a single transaction. All-or-nothing.
  Future<void> appendEvents(List<GameEvent> events);

  /// Marks [eventIds] as synced ([synced = true]).
  /// Silently skips IDs that are already marked synced or do not exist.
  Future<void> markSynced(List<String> eventIds);

  // Streams

  /// Emits the full ordered event list for [gameId] whenever a new event
  /// is appended. Used for live game state reconstruction.
  Stream<List<GameEvent>> watchEventsForGame(String gameId);
}