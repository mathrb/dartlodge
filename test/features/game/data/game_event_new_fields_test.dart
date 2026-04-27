// Test for new GameEvent fields (actorId, globalSequence, source).
// Uses the canonical migrations script with PRAGMA foreign_keys = ON so tests
// match production.
import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/persistence/database_migrations.dart';
import 'package:my_darts/features/game/data/repositories/game_event_repository_impl.dart';
import 'package:my_darts/features/game/data/repositories/game_repository_impl.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late GameEventRepositoryImpl repo;
  late GameRepositoryImpl gameRepo;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON;');
    await DatabaseMigrations.createSchema(db);
    repo = GameEventRepositoryImpl(db);
    gameRepo = GameRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('should store and retrieve new fields (actorId, globalSequence, source)', () async {
    final gameId = 'test-game';
    await gameRepo.createGame(
      Game(
        gameId: gameId,
        gameType: GameType.x01,
        config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
        startTime: DateTime.now(),
      ), [],
    );

    // Create event with new fields
    final event = GameEvent(
      eventId: 'event-1',
      gameId: gameId,
      eventType: 'DartThrown',
      localSequence: 0,
      occurredAt: DateTime.now(),
      payload: {'segment': 20, 'multiplier': 1},
      synced: false,
      actorId: 'player-123',
      globalSequence: 100,
      source: EventSource.client,
    );

    await repo.appendEvent(event);
    
    // Retrieve and verify
    final events = await repo.getEventsForGame(gameId);
    expect(events.length, 1);
    
    final retrievedEvent = events[0];
    expect(retrievedEvent.actorId, 'player-123');
    expect(retrievedEvent.globalSequence, 100);
    expect(retrievedEvent.source, EventSource.client);
  });

  test('should update globalSequence with updateGlobalSequences', () async {
    final gameId = 'test-game';
    await gameRepo.createGame(
      Game(
        gameId: gameId,
        gameType: GameType.x01,
        config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
        startTime: DateTime.now(),
      ), [],
    );

    // Create event without global sequence
    final event = GameEvent(
      eventId: 'event-1',
      gameId: gameId,
      eventType: 'DartThrown',
      localSequence: 0,
      occurredAt: DateTime.now(),
      payload: {'segment': 20, 'multiplier': 1},
      synced: false,
      actorId: 'player-123',
      globalSequence: null, // Initially null
      source: EventSource.client,
    );

    await repo.appendEvent(event);
    
    // Update global sequence
    await repo.updateGlobalSequences({'event-1': 500});
    
    // Verify update
    final events = await repo.getEventsForGame(gameId);
    expect(events[0].globalSequence, 500);
  });

  test('should handle different source values', () async {
    final gameId = 'test-game';
    await gameRepo.createGame(
      Game(
        gameId: gameId,
        gameType: GameType.x01,
        config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
        startTime: DateTime.now(),
      ), [],
    );

    // Test all source values
    final sources = [
      GameEvent(
        eventId: 'event-1',
        gameId: gameId,
        eventType: 'Test',
        localSequence: 0,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      ),
      GameEvent(
        eventId: 'event-2',
        gameId: gameId,
        eventType: 'Test',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
        actorId: 'system',
        source: EventSource.server,
      ),
      GameEvent(
        eventId: 'event-3',
        gameId: gameId,
        eventType: 'Test',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
        actorId: 'system',
        source: EventSource.vision,
      ),
    ];

    for (final event in sources) {
      await repo.appendEvent(event);
    }
    
    // Verify all sources are stored correctly
    final events = await repo.getEventsForGame(gameId);
    expect(events.length, 3);
    expect(events[0].source, EventSource.client);
    expect(events[1].source, EventSource.server);
    expect(events[2].source, EventSource.vision);
  });
}
