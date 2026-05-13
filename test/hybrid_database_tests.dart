// Comprehensive Database Contract Tests
//
// Runs the shared repository contract suites against the single drift backend
// used on every platform. The "hybrid" file/runner name is vestigial from the
// dual-backend (sqflite ↔ drift) era (see issue #112 and the corresponding note
// in CLAUDE.md); there is now only one backend.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'hybrid_test_runner.dart';
import 'test_data.dart';

void main() {
  group('Hybrid Database Tests', () {
    
    // Test basic player operations on both engines
    runHybridTests('Player Operations', (base) {
      late PlayerRepository playerRepo;
      
      setUp(() async {
        playerRepo = await base.createPlayerRepository();
      });
      
      test('should create and retrieve a player', () async {
        final player = TestData.createTestPlayer();
        
        // Create player
        await playerRepo.createPlayer(player);
        
        // Retrieve player
        final retrieved = await playerRepo.getPlayer(player.playerId);
        
        expect(retrieved, isNotNull);
        expect(retrieved?.playerId, player.playerId);
        expect(retrieved?.name, player.name);
      });
      
      test('should throw exception on duplicate player', () async {
        final player = TestData.createTestPlayer();
        
        // Create player
        await playerRepo.createPlayer(player);
        
        // Try to create duplicate
        expect(
          () => playerRepo.createPlayer(player),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should return empty list when no players exist', () async {
        final players = await playerRepo.getAllPlayers();
        expect(players, isEmpty);
      });
      
      test('should update player name', () async {
        final player = TestData.createTestPlayer();
        await playerRepo.createPlayer(player);
        
        await playerRepo.updatePlayerName(player.playerId, 'Updated Name');
        
        final updated = await playerRepo.getPlayer(player.playerId);
        expect(updated?.name, 'Updated Name');
      });
    });
    
    // Test game operations on both engines
    runHybridTests('Game Operations', (base) {
      late GameRepository gameRepo;
      
      setUp(() async {
        gameRepo = await base.createGameRepository();
      });
      
      test('should create and retrieve a game', () async {
        final game = TestData.createTestGame();
        
        // Create game with competitors
        final competitors = [
          Competitor(
            competitorId: 'competitor-1',
            gameId: game.gameId,
            type: CompetitorType.solo,
            name: 'Test Player',
            players: [
              CompetitorPlayer(
                playerId: 'test-player-1',
                rotationPosition: 1,
              )
            ],
          )
        ];
        
        await gameRepo.createGame(game, competitors);
        
        // Retrieve game
        final retrieved = await gameRepo.getGame(game.gameId);
        
        expect(retrieved, isNotNull);
        expect(retrieved?.gameId, game.gameId);
        expect(retrieved?.gameType, game.gameType);
      });
    });
    
    // Performance comparison tests
    runHybridTests('Performance Comparison', (base) {
      late PlayerRepository playerRepo;
      
      setUp(() async {
        playerRepo = await base.createPlayerRepository();
      });
      
      test('bulk insert performance', () async {
        final stopwatch = Stopwatch()..start();
        
        // Insert 100 players
        for (int i = 0; i < 100; i++) {
          await playerRepo.createPlayer(
            TestData.createTestPlayer(id: 'perf-player-$i')
          );
        }
        
        stopwatch.stop();
        print('${base.runtimeType}: '
              '${stopwatch.elapsedMilliseconds}ms for 100 inserts');
        
        // Verify all players were created
        final players = await playerRepo.getAllPlayers();
        expect(players.length, 100);
      }, timeout: Timeout(Duration(seconds: 10)));
    });
  });
}