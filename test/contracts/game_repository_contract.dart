// Game Repository Contract Tests
// Shared test suite for all GameRepository implementations

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';

void runGameRepositoryContractTests(
  Future<GameRepository> Function() factory, {
  required Future<PlayerRepository> Function() playerRepoFactory,
}) {
  late GameRepository repo;
  late PlayerRepository playerRepo;

  setUp(() async {
    repo = await factory();
    playerRepo = await playerRepoFactory();
    // Seed players referenced by competitors in the tests below. FK constraints
    // on competitor_players.player_id require these rows to exist first.
    final now = DateTime.now();
    for (final id in const ['p1', 'p2']) {
      await playerRepo.createPlayer(Player(
        playerId: id,
        name: 'Test $id',
        createdAt: now,
        lastActive: now,
      ));
    }
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

  group('getActiveGame', () {
    test('should return null when no active games exist', () async {
      final activeGame = await repo.getActiveGame();
      expect(activeGame, isNull);
    });

    test('should return the active game when one exists', () async {
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
      
      final activeGame = await repo.getActiveGame();
      expect(activeGame, isNotNull);
      expect(activeGame?.gameId, gameId);
      expect(activeGame?.isComplete, isFalse);
    });

    test('should throw exception when trying to create second active game (database constraint)', () async {
      // Create first active game
      final game1 = Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
        startTime: DateTime.now(),
        isComplete: false,
      );
      final competitors1 = [
        Competitor(
          competitorId: 'c1',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'P1',
          players: [const CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
      ];

      // Create second active game - this should fail due to database constraint
      final game2 = Game(
        gameId: 'g2',
        gameType: GameType.cricket,
        config: const GameConfig.cricket(scoring: 'standard', numbers: ['15', '16', '17', '18', '19', '20', 'bull'], legsToWin: 1),
        startTime: DateTime.now(),
        isComplete: false,
      );
      final competitors2 = [
        Competitor(
          competitorId: 'c2',
          gameId: 'g2',
          type: CompetitorType.solo,
          name: 'P2',
          players: [const CompetitorPlayer(playerId: 'p2', rotationPosition: 0)],
        ),
      ];

      await repo.createGame(game1, competitors1);
      
      // This should throw ActiveGameAlreadyExistsException due to database constraint
      expect(
        () => repo.createGame(game2, competitors2),
        throwsA(isA<ActiveGameAlreadyExistsException>()),
      );
    });

  });
}
