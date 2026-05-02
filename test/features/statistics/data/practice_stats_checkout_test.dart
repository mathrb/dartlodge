// Checkout Practice statistics scanner tests
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../sqflite_test_base.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Checkout Practice stats — getPlayerStats', () {
    late SqfliteTestBase base;
    late StatisticsRepositoryImpl statsRepo;
    late Database db;

    const playerId = 'player-co-1';
    const gameId = 'game-co-1';
    const competitorId = 'comp-co-1';

    setUp(() async {
      base = SqfliteTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryImpl(db);
      await db.insert('players', {
        'player_id': playerId,
        'name': 'Checkout Tester',
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    Future<void> _setupGame(List<Map<String, dynamic>> events) async {
      await db.insert('games', {
        'game_id': gameId,
        'game_type': GameType.checkoutPractice.name,
        'config_json': jsonEncode({}),
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
      await db.insert('competitors', {
        'competitor_id': competitorId,
        'game_id': gameId,
        'type': 'solo',
        'name': 'Checkout Tester',
      });
      await db.insert('competitor_players', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'rotation_position': 0,
      });
      int seq = 1;
      for (final payload in events) {
        final eventType = payload['__type'] as String;
        final cleaned = Map<String, dynamic>.from(payload)..remove('__type');
        await db.insert('game_events', {
          'event_id': 'evt-$seq',
          'game_id': gameId,
          'event_type': eventType,
          'local_sequence': seq++,
          'occurred_at': DateTime.now().toIso8601String(),
          'payload_json': jsonEncode(cleaned),
          'synced': 0,
          'actor_id': playerId,
          'source': EventSource.client.index,
        });
      }
    }

    test('returns zero stats when player has no checkout practice games', () async {
      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.checkoutPractice,
      );
      expect(stats.totalGames, 0);
      expect(stats.checkoutAttempts, 0);
      expect(stats.checkoutSuccesses, 0);
      expect(stats.checkoutSuccessRate, isNull);
    });

    test('counts attempts per TurnEnded event for this player', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout'},
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 5, 'multiplier': 1, 'score': 5},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'miss'},
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 16, 'multiplier': 2, 'score': 32},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.checkoutPractice,
      );

      expect(stats.checkoutAttempts, 3);
      expect(stats.checkoutSuccesses, 2);
      expect(stats.checkoutSuccessRate, closeTo(2 / 3, 0.001));
    });

    test('does not count other players TurnEnded events', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': 'other-player'},
        {'__type': 'TurnEnded', 'player_id': 'other-player', 'reason': 'checkout'},
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.checkoutPractice,
      );

      // Only the player's own TurnEnded counts
      expect(stats.checkoutAttempts, 1);
      expect(stats.checkoutSuccesses, 1);
    });

    test('success rate is null when no attempts', () async {
      await _setupGame([
        {'__type': 'LegCompleted', 'winner_player_id': null},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.checkoutPractice,
      );

      expect(stats.checkoutAttempts, 0);
      expect(stats.checkoutSuccessRate, isNull);
    });

    test('100% success rate when all attempts succeed', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout'},
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.checkoutPractice,
      );

      expect(stats.checkoutAttempts, 2);
      expect(stats.checkoutSuccesses, 2);
      expect(stats.checkoutSuccessRate, closeTo(1.0, 0.001));
    });
  });
}
