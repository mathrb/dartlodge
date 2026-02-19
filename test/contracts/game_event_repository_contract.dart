// Game Event Repository Contract Tests
// Shared test suite for all GameEventRepository implementations

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/domain/repositories/game_event_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/utils/constants.dart';

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
        localSequence: 0,
        occurredAt: DateTime.now(),
        payload: {'ruleset': 'X01'},
        synced: false,
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
        localSequence: 0,
        occurredAt: DateTime.now(),
        payload: {'ruleset': 'X01'},
        synced: false,
      );

      await repo.appendEvent(event);
      // Append same event ID again
      await repo.appendEvent(event.copyWith(localSequence: 1)); 
      
      final events = await repo.getEventsForGame(gameId);
      expect(events.length, 1); // Still only 1 because ID matched
    });

    test('should throw SequenceConflictException on duplicate localSequence with different ID', () async {
      final gameId = 'g1';
      await gameRepo.createGame(Game(gameId: gameId, gameType: GameType.x01, config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'), startTime: DateTime.now()), []);

      await repo.appendEvent(GameEvent(
        eventId: 'e1',
        gameId: gameId,
        eventType: 'GameCreated',
        localSequence: 0,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
      ));

      expect(
        () => repo.appendEvent(GameEvent(
          eventId: 'e2', // Different ID
          gameId: gameId,
          eventType: 'SomethingElse',
          localSequence: 0, // SAME sequence!
          occurredAt: DateTime.now(),
          payload: {},
          synced: false,
        )),
        throwsA(isA<SequenceConflictException>()),
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
        localSequence: 0,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
      ));

      await repo.markSynced(['e1']);
      
      final unsynced = await repo.getUnsyncedEvents();
      expect(unsynced, isEmpty);
    });
  });
}
