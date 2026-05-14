// Game Event Repository Contract Tests
// Shared test suite for all GameEventRepository implementations

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';

void runGameEventRepositoryContractTests({
  required Future<GameEventRepository> Function() factory,
  required Future<GameRepository> Function() gameRepoFactory,
}) {
  late GameEventRepository repo;
  late GameRepository gameRepo;

  setUp(() async {
    repo = await factory();
    gameRepo = await gameRepoFactory();
  });

  group('appendEvent', () {
    test('should append and retrieve events for a game', () async {
      final gameId = 'g1';
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
          startTime: DateTime.now(),
        ),
        [], // Empty competitors for simplicity in event test if supported by implementation
      );

      final event = GameEvent(
        eventId: 'e1',
        gameId: gameId,
        eventType: 'GameCreated',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'ruleset': 'X01'},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

      await repo.appendEvent(event);

      final events = await repo.getEventsForGame(gameId);
      expect(events.length, 1);
      expect(events[0].eventId, 'e1');
      expect(events[0].payload['ruleset'], 'X01');
    });

    test('should silently ignore duplicate eventId (idempotency)', () async {
      final gameId = 'g1';
      await gameRepo.createGame(Game(gameId: gameId, gameType: GameType.x01, config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'), startTime: DateTime.now()), []);

      final event = GameEvent(
        eventId: 'e1',
        gameId: gameId,
        eventType: 'GameCreated',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'ruleset': 'X01'},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

      await repo.appendEvent(event);
      // Append same event ID again
      await repo.appendEvent(event.copyWith(localSequence: 2));

      final events = await repo.getEventsForGame(gameId);
      expect(events.length, 1); // Still only 1 because ID matched
    });

    test('should throw GameNotFoundException for non-existent game', () async {
      expect(
        () => repo.appendEvent(GameEvent(
          eventId: 'e-nonexistent',
          gameId: 'no-such-game',
          eventType: 'GameCreated',
          localSequence: 1,
          occurredAt: DateTime.now(),
          payload: {},
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        )),
        throwsA(isA<GameNotFoundException>()),
      );
    });

    test('should throw SequenceConflictException on duplicate localSequence with different ID', () async {
      final gameId = 'g1';
      await gameRepo.createGame(Game(gameId: gameId, gameType: GameType.x01, config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'), startTime: DateTime.now()), []);

      await repo.appendEvent(GameEvent(
        eventId: 'e1',
        gameId: gameId,
        eventType: 'GameCreated',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      ));

      await expectLater(
        () => repo.appendEvent(GameEvent(
          eventId: 'e2', // Different ID
          gameId: gameId,
          eventType: 'SomethingElse',
          localSequence: 1, // SAME sequence!
          occurredAt: DateTime.now(),
          payload: {},
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        )),
        throwsA(isA<SequenceConflictException>()),
      );
    });
  });

  group('appendEvents', () {
    test('should throw ValidationException when events from different games are mixed', () {
      // Asserts are stripped in release; the contract is a real exception.
      final events = [
        GameEvent(
          eventId: 'e1',
          gameId: 'g1',
          eventType: 'GameCreated',
          localSequence: 1,
          occurredAt: DateTime.now(),
          payload: {'ruleset': 'X01'},
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        ),
        GameEvent(
          eventId: 'e2',
          gameId: 'g2', // Different game!
          eventType: 'GameCreated',
          localSequence: 1,
          occurredAt: DateTime.now(),
          payload: {'ruleset': 'X01'},
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        ),
      ];

      expect(
        () => repo.appendEvents(events),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('markSynced', () {
    test('should mark events as synced', () async {
      final gameId = 'g1';
      await gameRepo.createGame(Game(gameId: gameId, gameType: GameType.x01, config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'), startTime: DateTime.now()), []);

      await repo.appendEvent(GameEvent(
        eventId: 'e1',
        gameId: gameId,
        eventType: 'GameCreated',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      ));

      await repo.markSynced(['e1']);

      final unsynced = await repo.getUnsyncedEvents();
      expect(unsynced, isEmpty);
    });

    test('should throw EventNotFoundException for an unknown id', () async {
      final gameId = 'g1';
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(
              startingScore: 501,
              inStrategy: 'straight',
              outStrategy: 'double'),
          startTime: DateTime.now(),
        ),
        [],
      );

      await expectLater(
        () => repo.markSynced(['no-such-event']),
        throwsA(isA<EventNotFoundException>()),
      );
    });

    test(
        'should throw and roll back when mixing valid and unknown ids (fail-fast)',
        () async {
      final gameId = 'g1';
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(
              startingScore: 501,
              inStrategy: 'straight',
              outStrategy: 'double'),
          startTime: DateTime.now(),
        ),
        [],
      );

      await repo.appendEvent(GameEvent(
        eventId: 'e1',
        gameId: gameId,
        eventType: 'GameCreated',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      ));

      await expectLater(
        () => repo.markSynced(['e1', 'no-such-event']),
        throwsA(isA<EventNotFoundException>()),
      );

      // The valid id must NOT have been marked synced — the whole call
      // rolled back inside the transaction.
      final unsynced = await repo.getUnsyncedEvents();
      expect(unsynced.length, 1);
      expect(unsynced.first.eventId, 'e1');
      expect(unsynced.first.synced, isFalse);
    });
  });

  group('updateGlobalSequences', () {
    test('should throw EventNotFoundException for an unknown id', () async {
      final gameId = 'g1';
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(
              startingScore: 501,
              inStrategy: 'straight',
              outStrategy: 'double'),
          startTime: DateTime.now(),
        ),
        [],
      );

      await expectLater(
        () => repo.updateGlobalSequences({'no-such-event': 42}),
        throwsA(isA<EventNotFoundException>()),
      );
    });

    test(
        'should throw and roll back when mixing valid and unknown ids (fail-fast)',
        () async {
      final gameId = 'g1';
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(
              startingScore: 501,
              inStrategy: 'straight',
              outStrategy: 'double'),
          startTime: DateTime.now(),
        ),
        [],
      );

      await repo.appendEvent(GameEvent(
        eventId: 'e1',
        gameId: gameId,
        eventType: 'GameCreated',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      ));

      await expectLater(
        () => repo
            .updateGlobalSequences({'e1': 100, 'no-such-event': 200}),
        throwsA(isA<EventNotFoundException>()),
      );

      // The valid id must NOT have had its global_sequence set — the whole
      // call rolled back inside the transaction.
      final events = await repo.getEventsForGame(gameId);
      expect(events.length, 1);
      expect(events.first.eventId, 'e1');
      expect(events.first.globalSequence, isNull);
    });
  });

  group('appendEvent on completed game', () {
    test('should throw GameNotEditableException for single append', () async {
      final gameId = 'g1';
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(
              startingScore: 501,
              inStrategy: 'straight',
              outStrategy: 'double'),
          startTime: DateTime.now(),
          isComplete: false,
        ),
        [],
      );

      // Per CLAUDE.md ordering: create with isComplete: false, then call
      // completeGame so we can append-after-complete.
      await gameRepo.completeGame(
        gameId: gameId,
        winnerCompetitorId: null,
        endTime: DateTime.now(),
      );

      await expectLater(
        () => repo.appendEvent(GameEvent(
          eventId: 'e-after',
          gameId: gameId,
          eventType: 'DartThrown',
          localSequence: 1,
          occurredAt: DateTime.now(),
          payload: {},
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        )),
        throwsA(isA<GameNotEditableException>()),
      );
    });

    test('should throw GameNotEditableException for batch append', () async {
      final gameId = 'g1';
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(
              startingScore: 501,
              inStrategy: 'straight',
              outStrategy: 'double'),
          startTime: DateTime.now(),
          isComplete: false,
        ),
        [],
      );
      await gameRepo.completeGame(
        gameId: gameId,
        winnerCompetitorId: null,
        endTime: DateTime.now(),
      );

      final events = [
        GameEvent(
          eventId: 'e-after-1',
          gameId: gameId,
          eventType: 'DartThrown',
          localSequence: 1,
          occurredAt: DateTime.now(),
          payload: {},
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        ),
        GameEvent(
          eventId: 'e-after-2',
          gameId: gameId,
          eventType: 'DartThrown',
          localSequence: 2,
          occurredAt: DateTime.now(),
          payload: {},
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        ),
      ];

      await expectLater(
        () => repo.appendEvents(events),
        throwsA(isA<GameNotEditableException>()),
      );
    });
  });
}
