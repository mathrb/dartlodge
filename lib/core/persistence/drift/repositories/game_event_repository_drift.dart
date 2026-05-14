// Game Event Repository Drift Implementation
// Concrete implementation of GameEventRepository interface using Drift

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import '../database.dart' as drift_db;
import '../sqlite_error_codes.dart';

class GameEventRepositoryDrift implements GameEventRepository {
  final drift_db.AppDatabase _db;

  GameEventRepositoryDrift(this._db);

  @override
  Future<List<GameEvent>> getEventsSince(String gameId, int afterSequence) async {
    final query = _db.select(_db.gameEvents)
      ..where((t) => t.gameId.equals(gameId) & t.localSequence.isBiggerThanValue(afterSequence))
      ..orderBy([
        (t) => OrderingTerm(expression: t.localSequence, mode: OrderingMode.asc),
      ]);

    final results = await query.get();

    return results.map((row) => GameEvent(
      eventId: row.eventId,
      gameId: row.gameId,
      eventType: row.eventType,
      localSequence: row.localSequence,
      occurredAt: DateTime.parse(row.occurredAt),
      payload: json.decode(row.payloadJson),
      synced: row.synced == 1,
      actorId: row.actorId,
      globalSequence: row.globalSequence,
      source: _parseEventSource(row.source),
    )).toList();
  }

  @override
  Future<int> getLatestSequence(String gameId) async {
    final query = _db.selectOnly(_db.gameEvents)
      ..addColumns([_db.gameEvents.localSequence.max()])
      ..where(_db.gameEvents.gameId.equals(gameId));

    final result = await query.getSingleOrNull();
    final maxSequence = result?.read(_db.gameEvents.localSequence.max());

    // Returns 0 when no events exist. Callers compute `getLatestSequence + 1`
    // so the first event of every game lands at `local_sequence = 1`
    // (1-based, restarts per game). See docs/DATABASE_DDL.md.
    return maxSequence ?? 0;
  }

  @override
  Future<void> appendEvent(GameEvent event) async {
    // Wrap the existence + is-complete checks together with the insert in a
    // single transaction so the gate is atomic against a concurrent
    // `completeGame` — a check outside the transaction would have a TOCTOU
    // window between the read and the insert.
    await _db.transaction(() async {
      final gameRow = await (_db.select(_db.games)
        ..where((t) => t.gameId.equals(event.gameId))
        ..limit(1))
        .getSingleOrNull();
      if (gameRow == null) throw GameNotFoundException(event.gameId);
      if (gameRow.isComplete == 1) {
        throw GameNotEditableException(event.gameId);
      }

      try {
        await _db.into(_db.gameEvents).insert(
          drift_db.GameEventsCompanion.insert(
            eventId: event.eventId,
            gameId: event.gameId,
            eventType: event.eventType,
            localSequence: event.localSequence,
            occurredAt: event.occurredAt.toIso8601String(),
            payloadJson: json.encode(event.payload),
            synced: Value(event.synced ? 1 : 0),
            actorId: event.actorId,
            globalSequence: Value.absentIfNull(event.globalSequence),
            source: Value(event.source.index),
          ),
          mode: InsertMode.insertOrFail,
        );
      } on Exception catch (e) {
        if (isUniqueConstraintViolation(e)) {
          // Check if it's an idempotent insert (same event_id already exists)
          final existing = await (_db.select(_db.gameEvents)
            ..where((t) => t.eventId.equals(event.eventId))
            ..limit(1))
            .getSingleOrNull();
          if (existing != null) return; // Idempotent success

          // Check if it's a sequence conflict (different event_id, same sequence)
          final seqExisting = await (_db.select(_db.gameEvents)
            ..where((t) =>
                t.gameId.equals(event.gameId) &
                t.localSequence.equals(event.localSequence))
            ..limit(1))
            .getSingleOrNull();
          if (seqExisting != null && seqExisting.eventId != event.eventId) {
            throw SequenceConflictException(event.gameId, event.localSequence);
          }
        }
        if (e is RepositoryException) rethrow;
        throw DatabaseException(
          'Failed to append game event ${event.eventId} to game ${event.gameId}',
          cause: e,
        );
      }
    });
  }

  @override
  Future<void> appendEvents(List<GameEvent> events) async {
    if (events.isEmpty) return;

    // Reject mixed-game batches with a real exception (asserts strip in release).
    final gameIds = events.map((e) => e.gameId).toSet();
    if (gameIds.length != 1) {
      throw const ValidationException(
        'appendEvents requires all events to belong to the same game',
      );
    }

    final gameId = events.first.gameId;
    // Wrap the existence + is-complete checks together with the inserts in a
    // single transaction so the gate is atomic against a concurrent
    // `completeGame`.
    await _db.transaction(() async {
      final gameRow = await (_db.select(_db.games)
        ..where((t) => t.gameId.equals(gameId))
        ..limit(1))
        .getSingleOrNull();
      if (gameRow == null) throw GameNotFoundException(gameId);
      if (gameRow.isComplete == 1) {
        throw GameNotEditableException(gameId);
      }

      for (final event in events) {
        try {
          await _db.into(_db.gameEvents).insert(
            drift_db.GameEventsCompanion.insert(
              eventId: event.eventId,
              gameId: event.gameId,
              eventType: event.eventType,
              localSequence: event.localSequence,
              occurredAt: event.occurredAt.toIso8601String(),
              payloadJson: json.encode(event.payload),
              synced: Value(event.synced ? 1 : 0),
              actorId: event.actorId,
              globalSequence: Value.absentIfNull(event.globalSequence),
              source: Value(event.source.index),
            ),
            mode: InsertMode.insertOrFail,
          );
        } on Exception catch (e) {
          if (isUniqueConstraintViolation(e)) {
            // Check if it's an idempotent insert (same event_id already exists)
            final existing = await (_db.select(_db.gameEvents)
              ..where((t) => t.eventId.equals(event.eventId))
              ..limit(1))
              .getSingleOrNull();
            if (existing != null) continue; // Idempotent success

            // Check if it's a sequence conflict
            final seqExisting = await (_db.select(_db.gameEvents)
              ..where((t) =>
                  t.gameId.equals(event.gameId) &
                  t.localSequence.equals(event.localSequence))
              ..limit(1))
              .getSingleOrNull();
            if (seqExisting != null && seqExisting.eventId != event.eventId) {
              throw SequenceConflictException(event.gameId, event.localSequence);
            }
          }
          if (e is RepositoryException) rethrow;
          throw DatabaseException(
            'Failed to append game event ${event.eventId} to game ${event.gameId}',
            cause: e,
          );
        }
      }
    });
  }

  @override
  Future<void> markSynced(List<String> eventIds) async {
    if (eventIds.isEmpty) return;

    await _db.transaction(() async {
      // Verify all requested IDs exist before issuing any writes. If any are
      // missing we throw inside the transaction so the whole call is rolled
      // back (fail-fast — caller sees a clean state).
      final existing = await (_db.select(_db.gameEvents)
            ..where((t) => t.eventId.isIn(eventIds)))
          .map((row) => row.eventId)
          .get();
      final existingSet = existing.toSet();
      for (final id in eventIds) {
        if (!existingSet.contains(id)) {
          throw EventNotFoundException(id);
        }
      }

      await _db.batch((b) {
        for (final id in eventIds) {
          b.update(
            _db.gameEvents,
            drift_db.GameEventsCompanion(synced: Value(1)),
            where: (t) => t.eventId.equals(id),
          );
        }
      });
    });
  }

  @override
  Future<void> updateGlobalSequences(Map<String, int> eventIdToSequence) async {
    if (eventIdToSequence.isEmpty) return;

    await _db.transaction(() async {
      final ids = eventIdToSequence.keys.toList();
      final existing = await (_db.select(_db.gameEvents)
            ..where((t) => t.eventId.isIn(ids)))
          .map((row) => row.eventId)
          .get();
      final existingSet = existing.toSet();
      for (final id in ids) {
        if (!existingSet.contains(id)) {
          throw EventNotFoundException(id);
        }
      }

      await _db.batch((b) {
        for (final entry in eventIdToSequence.entries) {
          b.update(
            _db.gameEvents,
            drift_db.GameEventsCompanion(globalSequence: Value(entry.value)),
            where: (t) => t.eventId.equals(entry.key),
          );
        }
      });
    });
  }

  @override
  Future<List<GameEvent>> getEventsForGame(String gameId) async {
    final query = _db.select(_db.gameEvents)
      ..where((t) => t.gameId.equals(gameId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.localSequence, mode: OrderingMode.asc),
      ]);

    final results = await query.get();

    return results.map((row) => GameEvent(
      eventId: row.eventId,
      gameId: row.gameId,
      eventType: row.eventType,
      localSequence: row.localSequence,
      occurredAt: DateTime.parse(row.occurredAt),
      payload: json.decode(row.payloadJson),
      synced: row.synced == 1,
      actorId: row.actorId,
      globalSequence: row.globalSequence,
      source: _parseEventSource(row.source),
    )).toList();
  }



  @override
  Future<List<GameEvent>> getUnsyncedEvents() async {
    final query = _db.select(_db.gameEvents)
      ..where((t) => t.synced.equals(0))
      ..orderBy([
        (t) => OrderingTerm(expression: t.gameId, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.localSequence, mode: OrderingMode.asc),
      ]);

    final results = await query.get();

    return results.map((row) => GameEvent(
      eventId: row.eventId,
      gameId: row.gameId,
      eventType: row.eventType,
      localSequence: row.localSequence,
      occurredAt: DateTime.parse(row.occurredAt),
      payload: json.decode(row.payloadJson),
      synced: row.synced == 1,
      actorId: row.actorId,
      globalSequence: row.globalSequence,
      source: _parseEventSource(row.source),
    )).toList();
  }

  @override
  Stream<List<GameEvent>> watchEventsForGame(String gameId) {
    return (_db.select(_db.gameEvents)
      ..where((t) => t.gameId.equals(gameId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.localSequence, mode: OrderingMode.asc),
      ]))
      .watch()
      .map((rows) => rows.map((row) => GameEvent(
            eventId: row.eventId,
            gameId: row.gameId,
            eventType: row.eventType,
            localSequence: row.localSequence,
            occurredAt: DateTime.parse(row.occurredAt),
            payload: json.decode(row.payloadJson),
            synced: row.synced == 1,
            actorId: row.actorId,
            globalSequence: row.globalSequence,
            source: _parseEventSource(row.source),
          )).toList());
  }

  // Helper method to parse event source from int
  EventSource _parseEventSource(int sourceInt) {
    return EventSource.values.firstWhere(
      (source) => source.index == sourceInt,
      orElse: () => EventSource.values.first,
    );
  }

}
