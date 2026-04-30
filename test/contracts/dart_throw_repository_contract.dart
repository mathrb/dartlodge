// Dart Throw Repository Contract Tests
// Shared test suite for all DartThrowRepository implementations

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';

void runDartThrowRepositoryContractTests({
  required Future<DartThrowRepository> Function() factory,
  required Future<GameRepository> Function() gameRepoFactory,
  required Future<PlayerRepository> Function() playerRepoFactory,
}) {
  late DartThrowRepository repo;
  late GameRepository gameRepo;
  late PlayerRepository playerRepo;

  setUp(() async {
    repo = await factory();
    gameRepo = await gameRepoFactory();
    playerRepo = await playerRepoFactory();
  });

  group('insertDart', () {
    test('should insert and retrieve darts for a game', () async {
      final gameId = 'g1';
      final competitorId = 'c1';
      final playerId = 'p1';

      // Setup prerequisites
      await playerRepo.createPlayer(Player(
        playerId: playerId,
        name: 'P1',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ));

      await gameRepo.createGame(
        Game(
          gameId: gameId,
          gameType: GameType.x01,
          config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'),
          startTime: DateTime.now(),
        ),
        [
          Competitor(
            competitorId: competitorId,
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'P1',
            players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
          )
        ],
      );

      final dart = DartThrow(
        dartId: 'd1',
        gameId: gameId,
        competitorId: competitorId,
        playerId: playerId,
        turnNumber: 0,
        dartNumber: 1,
        segment: '20',
        score: 20,
      );

      await repo.insertDart(dart);
      
      final darts = await repo.getDartsForGame(gameId);
      expect(darts.length, 1);
      expect(darts[0].dartId, 'd1');
    });

    test('should throw DuplicateDartException on duplicate ID', () async {
      // Setup similar to above
      final gameId = 'g1';
      final competitorId = 'c1';
      final playerId = 'p1';
      await playerRepo.createPlayer(Player(playerId: playerId, name: 'P1', createdAt: DateTime.now(), lastActive: DateTime.now()));
      await gameRepo.createGame(Game(gameId: gameId, gameType: GameType.x01, config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'), startTime: DateTime.now()), [Competitor(competitorId: competitorId, gameId: gameId, type: CompetitorType.solo, name: 'P1', players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)])]);

      final dart = DartThrow(
        dartId: 'd1',
        gameId: gameId,
        competitorId: competitorId,
        playerId: playerId,
        turnNumber: 0,
        dartNumber: 1,
        segment: '20',
        score: 20,
      );

      await repo.insertDart(dart);
      expect(
        () => repo.insertDart(dart),
        throwsA(isA<DuplicateDartException>()),
      );
    });

    test('should throw GameAlreadyCompleteException if game is complete', () async {
      final gameId = 'g1';
      final competitorId = 'c1';
      final playerId = 'p1';
      await playerRepo.createPlayer(Player(playerId: playerId, name: 'P1', createdAt: DateTime.now(), lastActive: DateTime.now()));
      await gameRepo.createGame(Game(gameId: gameId, gameType: GameType.x01, config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'), startTime: DateTime.now()), [Competitor(competitorId: competitorId, gameId: gameId, type: CompetitorType.solo, name: 'P1', players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)])]);
      await gameRepo.completeGame(gameId: gameId, winnerCompetitorId: competitorId, endTime: DateTime.now());

      final dart = DartThrow(
        dartId: 'd1',
        gameId: gameId,
        competitorId: competitorId,
        playerId: playerId,
        turnNumber: 0,
        dartNumber: 1,
        segment: '20',
        score: 20,
      );

      expect(
        () => repo.insertDart(dart),
        throwsA(isA<GameAlreadyCompleteException>()),
      );
    });
  });

  group('deleteDart', () {
    test('should delete dart from active game', () async {
      // Setup...
      final gameId = 'g1';
      final competitorId = 'c1';
      final playerId = 'p1';
      await playerRepo.createPlayer(Player(playerId: playerId, name: 'P1', createdAt: DateTime.now(), lastActive: DateTime.now()));
      await gameRepo.createGame(Game(gameId: gameId, gameType: GameType.x01, config: const GameConfig.x01(startingScore: 501, inStrategy: 'straight', outStrategy: 'double'), startTime: DateTime.now()), [Competitor(competitorId: competitorId, gameId: gameId, type: CompetitorType.solo, name: 'P1', players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)])]);

      await repo.insertDart(DartThrow(
        dartId: 'd1',
        gameId: gameId,
        competitorId: competitorId,
        playerId: playerId,
        turnNumber: 0,
        dartNumber: 1,
        segment: '20',
        score: 20,
      ));

      await repo.deleteDart('d1');
      final darts = await repo.getDartsForGame(gameId);
      expect(darts, isEmpty);
    });
  });
}
