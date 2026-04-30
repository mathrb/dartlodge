// Catch-40 practice statistics scanner tests
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../sqflite_test_base.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Catch-40 practice stats — getPlayerStats', () {
    late SqfliteTestBase base;
    late StatisticsRepositoryImpl statsRepo;
    late Database db;

    const playerId = 'player-c40-1';
    const gameId = 'game-c40-1';
    const competitorId = 'comp-c40-1';

    setUp(() async {
      base = SqfliteTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryImpl(db);
      await db.insert('players', {
        'player_id': playerId,
        'name': 'Catch-40 Tester',
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    Future<void> _setupGame(List<Map<String, dynamic>> events) async {
      await db.insert('games', {
        'game_id': gameId,
        'game_type': GameType.catch40.name,
        'config_json': jsonEncode({}),
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
      await db.insert('competitors', {
        'competitor_id': competitorId,
        'game_id': gameId,
        'type': 'solo',
        'name': 'Catch-40 Tester',
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

    test('returns null avg/best for player with no Catch-40 games', () async {
      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );
      expect(stats.totalGames, 0);
      expect(stats.catch40AvgScore, isNull);
      expect(stats.catch40BestScore, isNull);
    });

    test('accumulates score per drill', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.catch40BestScore, 80);
      expect(stats.catch40AvgScore, closeTo(80.0, 0.01));
    });

    test('classifies 2-dart checkout correctly', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.catch40TwoDartCheckouts, 1);
      expect(stats.catch40ThreeDartCheckouts, 0);
      expect(stats.catch40FailedCheckouts, 0);
    });

    test('classifies 3-dart checkout correctly', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 1, 'score': 20},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 1, 'score': 20},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.catch40ThreeDartCheckouts, 1);
      expect(stats.catch40TwoDartCheckouts, 0);
    });

    test('counts failed checkouts', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 5, 'multiplier': 1, 'score': 5},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'failed'},
        {'__type': 'LegCompleted', 'winner_player_id': null},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.catch40FailedCheckouts, 1);
      expect(stats.catch40TwoDartCheckouts, 0);
    });
  });
}
