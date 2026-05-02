// Dart Throw Repository Hybrid Contract Test
// Runs the shared contract tests against both SQLite and Drift implementations

import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import '../hybrid_test_runner.dart';
import 'dart_throw_repository_contract.dart';

void main() {
  runHybridTests('Dart Throw Repository Contract Tests', (base) {
    // Create factories that use the current engine's repositories
    Future<PlayerRepository> playerRepoFactory() async {
      return await base.createPlayerRepository();
    }
    
    Future<GameRepository> gameRepoFactory() async {
      return await base.createGameRepository();
    }
    
    Future<DartThrowRepository> dartThrowRepoFactory() async {
      return await base.createDartThrowRepository();
    }
    
    // Run the contract tests
    runDartThrowRepositoryContractTests(
      factory: dartThrowRepoFactory,
      gameRepoFactory: gameRepoFactory,
      playerRepoFactory: playerRepoFactory,
    );
  });
}