// Achievement Repository Contract Tests — drift backend (#521/#522).

import 'package:drift/drift.dart' as drift;
import 'package:dart_lodge/core/persistence/drift/database.dart' as drift_db;
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../hybrid_test_runner.dart';
import 'achievement_repository_contract.dart';

void main() {
  runHybridTests('Achievement Repository Contract Tests', (base) {
    runAchievementRepositoryContractTests(
      () async => base.createAchievementRepository(),
      seedPlayer: (playerId) async {
        final players = await base.createPlayerRepository();
        await players.createPlayer(Player(
          playerId: playerId,
          name: 'Player $playerId',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        ));
      },
      seedGame: (gameId) async {
        await base.db.into(base.db.games).insert(
              drift_db.GamesCompanion.insert(
                gameId: gameId,
                gameType: 'x01',
                configJson: '{}',
                startTime: DateTime.now().toIso8601String(),
                isComplete: const drift.Value(1),
              ),
            );
      },
    );
  });
}
