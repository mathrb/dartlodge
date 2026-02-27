// Game Event Repository Hybrid Contract Test
// Runs the shared contract tests against both SQLite and Drift implementations

import 'package:my_darts/features/game/domain/repositories/game_event_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import '../hybrid_test_runner.dart';
import 'game_event_repository_contract.dart';

void main() {
  runHybridTests('Game Event Repository Contract Tests', (base) {
    Future<GameEventRepository> gameEventRepoFactory() async {
      return await base.createGameEventRepository();
    }

    Future<GameRepository> gameRepoFactory() async {
      return await base.createGameRepository();
    }

    runGameEventRepositoryContractTests(
      factory: gameEventRepoFactory,
      gameRepoFactory: gameRepoFactory,
    );
  });
}
