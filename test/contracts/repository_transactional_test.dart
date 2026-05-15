// Drift-specific transactional + TOCTOU regression tests for #189.
//
// Covers the gate-read-then-write methods that pre-fix performed the check
// outside the transaction, allowing a concurrent completeGame to slip in
// between and leave a dart on a finalized game / let two completeGame
// callers race their writes. Also covers the insertDarts multi-game gameId
// validation.
//
// These tests live next to the contract suite (not inside it) because they
// need direct DB access via DriftTestBase.

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../drift_test_base.dart';

void main() {
  group('repository transactional invariants (#189)', () {
    final base = DriftTestBase();

    setUp(() async {
      await base.setUp();
    });

    tearDown(() async {
      await base.tearDown();
    });

    Future<void> seedPlayer(String id) async {
      final repo = await base.createPlayerRepository();
      final now = DateTime(2026, 5, 15);
      await repo.createPlayer(Player(
        playerId: id,
        name: 'Player $id',
        createdAt: now,
        lastActive: now,
      ));
    }

    Future<void> seedGame({required String gameId, required String playerId}) async {
      final gameRepo = await base.createGameRepository();
      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(
            startingScore: 501,
            inStrategy: 'straight',
            outStrategy: 'double',
          ),
          startTime: DateTime(2026, 5, 15),
          isComplete: false,
        ),
        [
          Competitor(
            competitorId: 'c1-$gameId',
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Player $playerId',
            players: [
              CompetitorPlayer(playerId: playerId, rotationPosition: 0),
            ],
          ),
        ],
      );
    }

    DartThrow makeDart({
      required String dartId,
      required String gameId,
      required String competitorId,
      required String playerId,
    }) =>
        DartThrow(
          dartId: dartId,
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          turnNumber: 0,
          dartNumber: 1,
          segment: '20',
          score: 20,
        );

    test('insertDarts rejects darts from multiple gameIds', () async {
      // The validation fires before the transaction opens, so we don't
      // need both games to actually exist — the DB schema only permits
      // one active game at a time anyway (idx_games_single_active).
      await seedPlayer('p1');
      await seedGame(gameId: 'gA', playerId: 'p1');

      final dartRepo = await base.createDartThrowRepository();
      final mixed = [
        makeDart(
          dartId: 'd1',
          gameId: 'gA',
          competitorId: 'c1-gA',
          playerId: 'p1',
        ),
        makeDart(
          dartId: 'd2',
          gameId: 'gB-nonexistent',
          competitorId: 'c1-gB-nonexistent',
          playerId: 'p1',
        ),
      ];

      await expectLater(
        () => dartRepo.insertDarts(mixed),
        throwsA(isA<DatabaseException>().having(
          (e) => e.message,
          'message',
          contains('multiple games'),
        )),
      );

      // Verify nothing landed on gA — the rejection must short-circuit
      // before any insert.
      final inGameA = await dartRepo.getDartsForGame('gA');
      expect(inGameA, isEmpty);
    });

    test(
        'completeGame: two concurrent calls — exactly one succeeds, '
        'second throws GameAlreadyCompleteException', () async {
      await seedPlayer('p1');
      await seedGame(gameId: 'g1', playerId: 'p1');

      final gameRepo = await base.createGameRepository();

      // Drift's transaction lock serialises these on a single in-memory
      // connection — the second call observes is_complete=1 inside its own
      // transaction and throws.
      final f1 = gameRepo.completeGame(
        gameId: 'g1',
        winnerCompetitorId: 'c1-g1',
        endTime: DateTime(2026, 5, 15, 10),
      );
      final f2 = gameRepo.completeGame(
        gameId: 'g1',
        winnerCompetitorId: null,
        endTime: DateTime(2026, 5, 15, 11),
      );

      final results = await Future.wait([
        f1.then((_) => 'ok').catchError((e) => e.runtimeType.toString()),
        f2.then((_) => 'ok').catchError((e) => e.runtimeType.toString()),
      ]);

      // Exactly one 'ok', exactly one GameAlreadyCompleteException.
      final okCount = results.where((r) => r == 'ok').length;
      final alreadyComplete = results
          .where((r) => r == 'GameAlreadyCompleteException')
          .length;
      expect(okCount, 1, reason: 'exactly one completeGame must win the race');
      expect(alreadyComplete, 1,
          reason: 'loser must throw GameAlreadyCompleteException, not silently '
              'overwrite winner/endTime');
    });

    test(
        'insertDart on a just-completed game throws '
        'GameAlreadyCompleteException', () async {
      // Sequential demonstration of the gate behavior — the transactional
      // wrapping is exercised here too (single connection serialisation).
      await seedPlayer('p1');
      await seedGame(gameId: 'g1', playerId: 'p1');

      final gameRepo = await base.createGameRepository();
      await gameRepo.completeGame(
        gameId: 'g1',
        winnerCompetitorId: 'c1-g1',
        endTime: DateTime(2026, 5, 15),
      );

      final dartRepo = await base.createDartThrowRepository();
      await expectLater(
        () => dartRepo.insertDart(makeDart(
          dartId: 'd1',
          gameId: 'g1',
          competitorId: 'c1-g1',
          playerId: 'p1',
        )),
        throwsA(isA<GameAlreadyCompleteException>()),
      );
    });

    GameEvent makeEvent({
      required String eventId,
      required String gameId,
      required int seq,
      String type = 'DartThrown',
      Map<String, dynamic>? payload,
    }) =>
        GameEvent(
          eventId: eventId,
          gameId: gameId,
          eventType: type,
          localSequence: seq,
          occurredAt: DateTime(2026, 5, 15, 10, seq),
          payload: payload ?? const {'competitor_id': 'c1'},
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        );

    test(
      'appendEventsAndCompleteGame: happy path writes events AND completes '
      'the game atomically',
      () async {
        await seedPlayer('p1');
        await seedGame(gameId: 'g1', playerId: 'p1');

        final gameRepo = await base.createGameRepository();
        final eventRepo = await base.createGameEventRepository();

        final completedAt = DateTime(2026, 5, 15, 12);
        await gameRepo.appendEventsAndCompleteGame(
          events: [
            makeEvent(eventId: 'e1', gameId: 'g1', seq: 1),
            makeEvent(
              eventId: 'e2',
              gameId: 'g1',
              seq: 2,
              type: 'GameCompleted',
              payload: const {'winner_id': 'c1-g1'},
            ),
          ],
          gameId: 'g1',
          winnerCompetitorId: 'c1-g1',
          endTime: completedAt,
        );

        final events = await eventRepo.getEventsForGame('g1');
        expect(events.map((e) => e.eventId), ['e1', 'e2']);

        final game = await gameRepo.getGame('g1');
        expect(game?.isComplete, true);
        expect(game?.winnerCompetitorId, 'c1-g1');
        expect(game?.endTime, completedAt);
      },
    );

    test(
      'appendEventsAndCompleteGame: sequence conflict mid-batch rolls back '
      'both the events AND the game completion',
      () async {
        await seedPlayer('p1');
        await seedGame(gameId: 'g1', playerId: 'p1');

        final gameRepo = await base.createGameRepository();
        final eventRepo = await base.createGameEventRepository();

        // Seed a real event at sequence 1 so the second event in the batch
        // below (also at seq=1, different eventId) trips
        // SequenceConflictException mid-transaction.
        await eventRepo.appendEvent(
          makeEvent(eventId: 'pre-existing', gameId: 'g1', seq: 1),
        );

        await expectLater(
          () => gameRepo.appendEventsAndCompleteGame(
            events: [
              makeEvent(eventId: 'e-new-1', gameId: 'g1', seq: 2),
              // This second event collides with seq=1, which is already
              // taken by 'pre-existing' — must roll back the entire batch
              // AND the games row update.
              makeEvent(eventId: 'e-new-2', gameId: 'g1', seq: 1),
            ],
            gameId: 'g1',
            winnerCompetitorId: 'c1-g1',
            endTime: DateTime(2026, 5, 15, 13),
          ),
          throwsA(isA<SequenceConflictException>()),
        );

        // Neither the new events NOR the completion can have landed.
        final events = await eventRepo.getEventsForGame('g1');
        expect(events.map((e) => e.eventId), ['pre-existing'],
            reason: 'partial event inserts must be rolled back');

        final game = await gameRepo.getGame('g1');
        expect(game?.isComplete, false,
            reason:
                'games.is_complete must NOT be set when the event batch rolls back');
        expect(game?.winnerCompetitorId, isNull);
        expect(game?.endTime, isNull);
      },
    );

    test(
      'appendEventsAndCompleteGame on already-complete game throws '
      'GameAlreadyCompleteException and writes nothing',
      () async {
        await seedPlayer('p1');
        await seedGame(gameId: 'g1', playerId: 'p1');

        final gameRepo = await base.createGameRepository();
        final eventRepo = await base.createGameEventRepository();

        await gameRepo.completeGame(
          gameId: 'g1',
          winnerCompetitorId: 'c1-g1',
          endTime: DateTime(2026, 5, 15, 10),
        );

        await expectLater(
          () => gameRepo.appendEventsAndCompleteGame(
            events: [makeEvent(eventId: 'e1', gameId: 'g1', seq: 1)],
            gameId: 'g1',
            winnerCompetitorId: 'c1-g1',
            endTime: DateTime(2026, 5, 15, 11),
          ),
          throwsA(isA<GameAlreadyCompleteException>()),
        );

        // Gate fires before the event insert, so no event landed.
        final events = await eventRepo.getEventsForGame('g1');
        expect(events, isEmpty);
      },
    );

    test(
      'appendEventsAndCompleteGame rejects events whose gameId mismatches '
      'the target gameId',
      () async {
        await seedPlayer('p1');
        await seedGame(gameId: 'g1', playerId: 'p1');

        final gameRepo = await base.createGameRepository();

        await expectLater(
          () => gameRepo.appendEventsAndCompleteGame(
            events: [
              makeEvent(eventId: 'e1', gameId: 'other-game', seq: 1),
            ],
            gameId: 'g1',
            winnerCompetitorId: null,
            endTime: DateTime(2026, 5, 15, 11),
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test(
        'deleteDart on a just-completed game throws '
        'GameAlreadyCompleteException', () async {
      await seedPlayer('p1');
      await seedGame(gameId: 'g1', playerId: 'p1');

      final dartRepo = await base.createDartThrowRepository();
      await dartRepo.insertDart(makeDart(
        dartId: 'd1',
        gameId: 'g1',
        competitorId: 'c1-g1',
        playerId: 'p1',
      ));

      final gameRepo = await base.createGameRepository();
      await gameRepo.completeGame(
        gameId: 'g1',
        winnerCompetitorId: 'c1-g1',
        endTime: DateTime(2026, 5, 15),
      );

      await expectLater(
        () => dartRepo.deleteDart('d1'),
        throwsA(isA<GameAlreadyCompleteException>()),
      );
    });
  });
}
