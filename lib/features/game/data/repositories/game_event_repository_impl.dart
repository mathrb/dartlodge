// Game Event Repository Implementation
// Concrete implementation of GameEventRepository interface using SQLite

import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../../domain/entities/game_event.dart';
import '../../domain/repositories/game_event_repository.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/utils/constants.dart';

class GameEventRepositoryImpl implements GameEventRepository {
  final Database _db;

  GameEventRepositoryImpl(this._db);

  @override
  Future<List<GameEvent>> getEventsForGame(String gameId) async {
    final results = await _db.query(
      'game_events',
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'local_sequence ASC',
    );

    return results.map((json) => GameEvent.fromJson(json)).toList();
  }

  @override
  Future<List<GameEvent>> getEventsSince(String gameId, int afterSequence) async {
    final results = await _db.query(
      'game_events',
      where: 'game_id = ? AND local_sequence > ?',
      whereArgs: [gameId, afterSequence],
      orderBy: 'local_sequence ASC',
    );

    return results.map((json) => GameEvent.fromJson(json)).toList();
  }

  @override
  Future<List<GameEvent>> getUnsyncedEvents() async {
    final results = await _db.query(
      'game_events',
      where: 'synced = 0',
      orderBy: 'game_id ASC, local_sequence ASC',
    );

    return results.map((json) => GameEvent.fromJson(json)).toList();
  }

  @override
  Future<int> getLatestSequence(String gameId) async {
    final results = await _db.query(
      'game_events',
      columns: ['local_sequence'],
      where: 'game_id = ?',
      whereArgs: [gameId],
      orderBy: 'local_sequence DESC',
      limit: 1,
    );

    if (results.isEmpty) return -1;
    return results.first['local_sequence'] as int;
  }

  @override
  Future<void> appendEvent(GameEvent event) async {
    // Check if game exists
    final game = await _db.query(
      'games',
      where: 'game_id = ?',
      whereArgs: [event.gameId],
      limit: 1,
    );

    if (game.isEmpty) {
      throw GameNotFoundException(event.gameId);
    }

    try {
      await _db.insert(
        'game_events',
        {
          'event_id': event.eventId,
          'game_id': event.gameId,
          'event_type': event.eventType,
          'local_sequence': event.localSequence,
          'occurred_at': event.occurredAt.toIso8601String(),
          'payload_json': jsonEncode(event.payload),
          'synced': event.synced ? 1 : 0,
          'actor_id': event.actorId,
          'global_sequence': event.globalSequence,
          'source': event.source.value,
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        // 1. Check if it's an idempotent insert (same event_id already exists)
        final sameId = await _db.query(
          'game_events',
          where: 'event_id = ?',
          whereArgs: [event.eventId],
          limit: 1,
        );
        if (sameId.isNotEmpty) {
          return; // Idempotent success
        }

        // 2. Check if it's a sequence conflict (different event_id for same sequence)
        final existing = await _db.query(
          'game_events',
          where: 'game_id = ? AND local_sequence = ?',
          whereArgs: [event.gameId, event.localSequence],
          limit: 1,
        );

        if (existing.isNotEmpty && existing.first['event_id'] != event.eventId) {
          throw SequenceConflictException(event.gameId, event.localSequence);
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> appendEvents(List<GameEvent> events) async {
    if (events.isEmpty) return;

    // Validate all events belong to the same game
    assert(events.map((e) => e.gameId).toSet().length == 1,
        'appendEvents requires all events to belong to the same game');

    // Verify all events belong to existing games
    // For simplicity, we'll check the first gameId
    final gameId = events.first.gameId;
    final game = await _db.query(
      'games',
      where: 'game_id = ?',
      whereArgs: [gameId],
      limit: 1,
    );

    if (game.isEmpty) {
      throw GameNotFoundException(gameId);
    }

    await _db.transaction((txn) async {
      for (final event in events) {
        try {
          await txn.insert(
            'game_events',
            {
              'event_id': event.eventId,
              'game_id': event.gameId,
              'event_type': event.eventType,
              'local_sequence': event.localSequence,
              'occurred_at': event.occurredAt.toIso8601String(),
              'payload_json': jsonEncode(event.payload),
              'synced': event.synced ? 1 : 0,
              'actor_id': event.actorId,
              'global_sequence': event.globalSequence,
              'source': event.source.value,
            },
            conflictAlgorithm: ConflictAlgorithm.fail,
          );
        } on DatabaseException catch (e) {
          if (e.isUniqueConstraintError()) {
            final sameId = await txn.query(
              'game_events',
              where: 'event_id = ?',
              whereArgs: [event.eventId],
              limit: 1,
            );
            if (sameId.isNotEmpty) {
              continue; // Skip idempotent
            }

            final existing = await txn.query(
              'game_events',
              where: 'game_id = ? AND local_sequence = ?',
              whereArgs: [event.gameId, event.localSequence],
              limit: 1,
            );

            if (existing.isNotEmpty && existing.first['event_id'] != event.eventId) {
              throw SequenceConflictException(event.gameId, event.localSequence);
            }
          }
          rethrow;
        }
      }
    });
  }

  @override
  Future<void> markSynced(List<String> eventIds) async {
    if (eventIds.isEmpty) return;

    await _db.update(
      'game_events',
      {'synced': 1},
      where: 'event_id IN (${List.filled(eventIds.length, '?').join(',')})',
      whereArgs: eventIds,
    );
  }

  @override
  Stream<List<GameEvent>> watchEventsForGame(String gameId) {
    return Stream.fromFuture(getEventsForGame(gameId));
  }

  @override
  Future<void> updateGlobalSequences(Map<String, int> eventIdToSequence) async {
    if (eventIdToSequence.isEmpty) return;

    await _db.transaction((txn) async {
      for (final entry in eventIdToSequence.entries) {
        await txn.update(
          'game_events',
          {'global_sequence': entry.value},
          where: 'event_id = ?',
          whereArgs: [entry.key],
        );
      }
    });
  }
}
