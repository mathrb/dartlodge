// Game Repository Contract Tests
// Shared test suite for all GameRepository implementations

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/utils/constants.dart';

void runGameRepositoryContractTests(Future<GameRepository> Function() factory) {
  late GameRepository repo;

  setUp(() async {
    repo = await factory();
  });

  group('createGame and getGame', () {
    test('should create and retrieve a game with competitors', () async {
      final gameId = 'g1';
      final game = Game(
        gameId: gameId,
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
        ),
        startTime: DateTime.now(),
        isComplete: false,
      );

      final competitors = [
        Competitor(
          competitorId: 'c1',
          gameId: gameId,
          type: CompetitorType.solo,
          name: 'Player 1',
          players: [const CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
        Competitor(
          competitorId: 'c2',
          gameId: gameId,
          type: CompetitorType.solo,
          name: 'Player 2',
          players: [const CompetitorPlayer(playerId: 'p2', rotationPosition: 0)],
        ),
      ];

      await repo.createGame(game, competitors);
      
      final retrieved = await repo.getGame(gameId);
      expect(retrieved, isNotNull);
      expect(retrieved?.gameId, gameId);
      expect(retrieved?.gameType, GameType.x01);

      final retrievedCompetitors = await repo.getCompetitors(gameId);
      expect(retrievedCompetitors.length, 2);
      expect(retrievedCompetitors[0].competitorId, 'c1');
      expect(retrievedCompetitors[1].competitorId, 'c2');
    });

    test('should throw DuplicateGameException on duplicate ID', () async {
      final game = Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
        startTime: DateTime.now(),
      );
      final competitors = [
        Competitor(
          competitorId: 'c1',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'P1',
          players: [const CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
      ];

      await repo.createGame(game, competitors);
      expect(
        () => repo.createGame(game, competitors),
        throwsA(isA<DuplicateGameException>()),
      );
    });

    test('should throw InvalidCompetitorException if player in multiple competitors', () async {
      final game = Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
        startTime: DateTime.now(),
      );
      final competitors = [
        Competitor(
          competitorId: 'c1',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'P1',
          players: [const CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
        Competitor(
          competitorId: 'c2',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'P2',
          players: [const CompetitorPlayer(playerId: 'p1', rotationPosition: 0)], // Duplicate player
        ),
      ];

      expect(
        () => repo.createGame(game, competitors),
        throwsA(isA<InvalidCompetitorException>()),
      );
    });
  });

  group('completeGame', () {
    test('should mark game as complete', () async {
      final gameId = 'g1';
      final game = Game(
        gameId: gameId,
        gameType: GameType.x01,
        config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
        startTime: DateTime.now(),
        isComplete: false,
      );
      final competitors = [
        Competitor(
          competitorId: 'c1',
          gameId: gameId,
          type: CompetitorType.solo,
          name: 'P1',
          players: [const CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
      ];

      await repo.createGame(game, competitors);
      
      final endTime = DateTime.now();
      await repo.completeGame(
        gameId: gameId,
        winnerCompetitorId: 'c1',
        endTime: endTime,
      );

      final retrieved = await repo.getGame(gameId);
      expect(retrieved?.isComplete, isTrue);
      expect(retrieved?.winnerCompetitorId, 'c1');
      // end_time might lose precision in DB, check roughly
      expect(retrieved?.endTime?.isBefore(endTime.add(const Duration(seconds: 1))), isTrue);
    });

    test('should throw GameNotFoundException for unknown game', () async {
      expect(
        () => repo.completeGame(gameId: 'unknown', winnerCompetitorId: null, endTime: DateTime.now()),
        throwsA(isA<GameNotFoundException>()),
      );
    });
  });
}
