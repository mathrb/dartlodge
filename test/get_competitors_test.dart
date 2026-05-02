// Test to verify getCompetitors implementation
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'test_data.dart';
import 'hybrid_test_runner.dart';

Future<void> _seedPlayers(PlayerRepository repo, List<String> ids) async {
  final now = DateTime.now();
  for (final id in ids) {
    await repo.createPlayer(Player(
      playerId: id,
      name: 'Test $id',
      createdAt: now,
      lastActive: now,
    ));
  }
}

void main() {
  group('getCompetitors Tests', () {

    runHybridTests('getCompetitors functionality', (base) {
      late GameRepository gameRepo;
      late PlayerRepository playerRepo;

      setUp(() async {
        gameRepo = await base.createGameRepository();
        playerRepo = await base.createPlayerRepository();
      });
      
      test('should return competitors with player rosters', () async {
        await _seedPlayers(playerRepo, ['player-1', 'player-2']);
        final game = TestData.createTestGame();

        // Create competitors with players
        final competitors = [
          Competitor(
            competitorId: 'competitor-1',
            gameId: game.gameId,
            type: CompetitorType.solo,
            name: 'Player 1',
            players: [
              const CompetitorPlayer(
                playerId: 'player-1',
                rotationPosition: 0,
              )
            ],
          ),
          Competitor(
            competitorId: 'competitor-2',
            gameId: game.gameId,
            type: CompetitorType.solo,
            name: 'Player 2',
            players: [
              const CompetitorPlayer(
                playerId: 'player-2',
                rotationPosition: 0,
              )
            ],
          ),
        ];
        
        await gameRepo.createGame(game, competitors);
        
        // Retrieve competitors
        final retrievedCompetitors = await gameRepo.getCompetitors(game.gameId);
        
        // Verify we got the correct number of competitors
        expect(retrievedCompetitors.length, 2);
        
        // Verify first competitor
        expect(retrievedCompetitors[0].competitorId, 'competitor-1');
        expect(retrievedCompetitors[0].name, 'Player 1');
        expect(retrievedCompetitors[0].players.length, 1);
        expect(retrievedCompetitors[0].players[0].playerId, 'player-1');
        expect(retrievedCompetitors[0].players[0].rotationPosition, 0);
        
        // Verify second competitor
        expect(retrievedCompetitors[1].competitorId, 'competitor-2');
        expect(retrievedCompetitors[1].name, 'Player 2');
        expect(retrievedCompetitors[1].players.length, 1);
        expect(retrievedCompetitors[1].players[0].playerId, 'player-2');
        expect(retrievedCompetitors[1].players[0].rotationPosition, 0);
      });
      
      test('should return empty list for game with no competitors', () async {
        final game = TestData.createTestGame();
        
        // Create game with no competitors (edge case)
        await gameRepo.createGame(game, []);
        
        // Retrieve competitors
        final retrievedCompetitors = await gameRepo.getCompetitors(game.gameId);
        
        // Should return empty list
        expect(retrievedCompetitors, isEmpty);
      });
      
      test('should handle team competitors with multiple players', () async {
        await _seedPlayers(playerRepo, ['player-1', 'player-2', 'player-3']);
        final game = TestData.createTestGame();

        // Create team competitor with multiple players
        final competitors = [
          Competitor(
            competitorId: 'team-1',
            gameId: game.gameId,
            type: CompetitorType.team,
            name: 'Team Awesome',
            players: [
              const CompetitorPlayer(
                playerId: 'player-1',
                rotationPosition: 0,
              ),
              const CompetitorPlayer(
                playerId: 'player-2',
                rotationPosition: 1,
              ),
              const CompetitorPlayer(
                playerId: 'player-3',
                rotationPosition: 2,
              ),
            ],
          ),
        ];
        
        await gameRepo.createGame(game, competitors);
        
        // Retrieve competitors
        final retrievedCompetitors = await gameRepo.getCompetitors(game.gameId);
        
        // Verify team structure
        expect(retrievedCompetitors.length, 1);
        expect(retrievedCompetitors[0].competitorId, 'team-1');
        expect(retrievedCompetitors[0].type, CompetitorType.team);
        expect(retrievedCompetitors[0].name, 'Team Awesome');
        expect(retrievedCompetitors[0].players.length, 3);
        
        // Verify player order
        expect(retrievedCompetitors[0].players[0].playerId, 'player-1');
        expect(retrievedCompetitors[0].players[0].rotationPosition, 0);
        expect(retrievedCompetitors[0].players[1].playerId, 'player-2');
        expect(retrievedCompetitors[0].players[1].rotationPosition, 1);
        expect(retrievedCompetitors[0].players[2].playerId, 'player-3');
        expect(retrievedCompetitors[0].players[2].rotationPosition, 2);
      });
    });
  });
}
