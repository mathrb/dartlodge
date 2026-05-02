// Player Repository Contract Tests
// Shared test suite for all PlayerRepository implementations

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';

/// [insertHistory] is an optional callback that inserts a competitor_players row
/// for [playerId], enabling the history-check test. If null, that test is skipped.
void runPlayerRepositoryContractTests(
  Future<PlayerRepository> Function() factory, {
  Future<void> Function(String playerId)? insertHistory,
}) {
  late PlayerRepository repo;

  setUp(() async {
    repo = await factory();
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

    if (insertHistory != null)
      test('should throw PlayerHasGameHistoryException when history exists',
          () async {
        final player = Player(
          playerId: 'p1',
          name: 'Alice',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );

        await repo.createPlayer(player);
        await insertHistory('p1');

        expect(
          () => repo.deletePlayer('p1'),
          throwsA(isA<PlayerHasGameHistoryException>()),
        );
      });
  });
}
