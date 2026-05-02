// Player Repository Hybrid Contract Test
// Runs the shared contract tests against both SQLite and Drift implementations

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/persistence/drift/database.dart' as drift_db;
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import '../hybrid_test_runner.dart';

void main() {
  // Run tests for both SQLite and Drift engines
  runHybridTests('Player Repository Contract Tests', (base) {
    late PlayerRepository repo;

    setUp(() async {
      repo = await base.createPlayerRepository();
    });

    group('getAllPlayers', () {
      test('should return empty list when no players exist', () async {
        expect(await repo.getAllPlayers(), isEmpty);
      });

      test('should return players ordered by lastActive DESC', () async {
        final p1 = Player(
          playerId: 'p1',
          name: 'Alice',
          createdAt: DateTime.now(),
          lastActive: DateTime.now().subtract(const Duration(hours: 1)),
        );
        final p2 = Player(
          playerId: 'p2',
          name: 'Bob',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await repo.createPlayer(p1);
        await repo.createPlayer(p2);

        final players = await repo.getAllPlayers();
        expect(players.length, 2);
        expect(players[0].playerId, 'p2'); // Most active first
        expect(players[1].playerId, 'p1');
      });
    });

    group('createPlayer and getPlayer', () {
      test('should create and retrieve a player', () async {
        final player = Player(
          playerId: 'p1',
          name: 'Alice',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await repo.createPlayer(player);
        final retrieved = await repo.getPlayer('p1');

        expect(retrieved, isNotNull);
        expect(retrieved?.name, 'Alice');
      });

      test('should throw DuplicatePlayerException on duplicate ID', () async {
        final player = Player(
          playerId: 'p1',
          name: 'Alice',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await repo.createPlayer(player);

        expect(
          () => repo.createPlayer(player.copyWith(name: 'Bob')),
          throwsA(isA<DuplicatePlayerException>()),
        );
      });

      test('should return null for non-existent player', () async {
        expect(await repo.getPlayer('unknown'), isNull);
      });
    });

    group('updatePlayerName', () {
      test('should update name and lastActive', () async {
        final player = Player(
          playerId: 'p1',
          name: 'Alice',
          createdAt: DateTime.now(),
          lastActive: DateTime.now().subtract(const Duration(days: 1)),
        );

        await repo.createPlayer(player);
        await repo.updatePlayerName('p1', 'Alice Updated');

        final updated = await repo.getPlayer('p1');
        expect(updated?.name, 'Alice Updated');
        expect(updated!.lastActive.isAfter(player.lastActive), isTrue);
      });

      test('should throw PlayerNotFoundException for unknown player', () async {
        expect(
          () => repo.updatePlayerName('unknown', 'New Name'),
          throwsA(isA<PlayerNotFoundException>()),
        );
      });
    });

    group('touchPlayer', () {
      test('should update lastActive to now', () async {
        final player = Player(
          playerId: 'p1',
          name: 'Alice',
          createdAt: DateTime.now(),
          lastActive: DateTime.now().subtract(const Duration(days: 1)),
        );

        await repo.createPlayer(player);
        await repo.touchPlayer('p1');

        final updated = await repo.getPlayer('p1');
        expect(updated!.lastActive.isAfter(player.lastActive), isTrue);
      });
    });

    group('deletePlayer', () {
      test('should delete a player with no history', () async {
        final player = Player(
          playerId: 'p1',
          name: 'Alice',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await repo.createPlayer(player);
        await repo.deletePlayer('p1');

        expect(await repo.getPlayer('p1'), isNull);
      });

      test('should throw PlayerNotFoundException for unknown player', () async {
        expect(
          () => repo.deletePlayer('unknown'),
          throwsA(isA<PlayerNotFoundException>()),
        );
      });

      test('should throw PlayerHasGameHistoryException when history exists',
          () async {
        final player = Player(
          playerId: 'p1',
          name: 'Alice',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await repo.createPlayer(player);
        await _insertHistory(base, 'p1');

        expect(
          () => repo.deletePlayer('p1'),
          throwsA(isA<PlayerHasGameHistoryException>()),
        );
      });
    });
  });
}

Future<void> _insertHistory(DatabaseTestBase base, String playerId) async {
  // Insert in FK order: games → competitors → competitor_players. The drift
  // schema enforces FKs; the sqflite test schema currently does not, but we
  // still write them in dependency order for parity.
  if (base is DriftTestBase) {
    await base.db.into(base.db.games).insert(
      drift_db.GamesCompanion.insert(
        gameId: 'g1',
        gameType: 'x01',
        configJson: '{}',
        startTime: DateTime.now().toIso8601String(),
        isComplete: const drift.Value(1),
      ),
    );
    await base.db.into(base.db.competitors).insert(
      drift_db.CompetitorsCompanion.insert(
        competitorId: 'c1',
        gameId: 'g1',
        type: 'human',
        name: 'Alice',
      ),
    );
    await base.db.into(base.db.competitorPlayers).insert(
      drift_db.CompetitorPlayersCompanion.insert(
        competitorId: 'c1',
        playerId: playerId,
        rotationPosition: 0,
      ),
    );
  } else if (base is SqfliteTestBase) {
    await base.db.insert('games', {
      'game_id': 'g1',
      'game_type': 'x01',
      'config_json': '{}',
      'start_time': DateTime.now().toIso8601String(),
      'is_complete': 1,
    });
    await base.db.insert('competitors', {
      'competitor_id': 'c1',
      'game_id': 'g1',
      'type': 'human',
      'name': 'Alice',
    });
    await base.db.insert('competitor_players', {
      'competitor_id': 'c1',
      'player_id': playerId,
      'rotation_position': 0,
    });
  }
}
