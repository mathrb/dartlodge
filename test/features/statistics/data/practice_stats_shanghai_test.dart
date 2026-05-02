// Shanghai practice statistics scanner tests
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../sqflite_test_base.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Shanghai practice stats — getPlayerStats', () {
    late SqfliteTestBase base;
    late StatisticsRepositoryImpl statsRepo;
    late Database db;

    const playerId = 'player-sha-1';
    const gameId = 'game-sha-1';
    const competitorId = 'comp-sha-1';

    setUp(() async {
      base = SqfliteTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryImpl(db);
      await db.insert('players', {
        'player_id': playerId,
        'name': 'Shanghai Tester',
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    Future<void> _setupGame(List<Map<String, dynamic>> events) async {
      await db.insert('games', {
        'game_id': gameId,
        'game_type': GameType.shanghai.name,
        'config_json': jsonEncode({}),
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
      await db.insert('competitors', {
        'competitor_id': competitorId,
        'game_id': gameId,
        'type': 'solo',
        'name': 'Shanghai Tester',
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

    test('returns null avg/best for player with no Shanghai games', () async {
      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.shanghai,
      );
      expect(stats.totalGames, 0);
      expect(stats.shanghaiAvgScore, isNull);
      expect(stats.shanghaiBestScore, isNull);
      expect(stats.shanghaiCount, 0);
    });

    test('accumulates score from DartThrown score field', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        // Round 1: S1=1, D1=2, T1=3 → total score = 6
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 1, 'score': 1},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 3, 'score': 3},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.shanghai,
      );

      expect(stats.shanghaiBestScore, 6);
      expect(stats.shanghaiAvgScore, closeTo(6.0, 0.01));
    });

    test('detects Shanghai: S, D, T on same target in one turn', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        // Hit all 3 multipliers of target 1 in one turn = Shanghai!
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 1, 'score': 1},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 3, 'score': 3},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.shanghai,
      );

      expect(stats.shanghaiCount, 1);
    });

    test('no Shanghai when not all multipliers hit in one turn', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        // Only S and D, no T → no Shanghai
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 1, 'score': 1},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 5, 'multiplier': 1, 'score': 5},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.shanghai,
      );

      expect(stats.shanghaiCount, 0);
    });

    test('avg score across multiple drills', () async {
      // Drill 1: score = 10, Drill 2: score = 30 → avg = 20
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 1, 'score': 10},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 2, 'multiplier': 1, 'score': 30},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.shanghai,
      );

      expect(stats.shanghaiAvgScore, closeTo(20.0, 0.01));
      expect(stats.shanghaiBestScore, 30);
    });
  });
}
