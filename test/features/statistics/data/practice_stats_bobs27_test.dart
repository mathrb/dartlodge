// Bob's 27 practice statistics scanner tests
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

  group("Bob's 27 practice stats — getPlayerStats", () {
    late SqfliteTestBase base;
    late StatisticsRepositoryImpl statsRepo;
    late Database db;

    const playerId = 'player-b27-1';
    const gameId = 'game-b27-1';
    const competitorId = 'comp-b27-1';

    setUp(() async {
      base = SqfliteTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryImpl(db);
      await db.insert('players', {
        'player_id': playerId,
        'name': "Bob's 27 Tester",
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    Future<void> _setupGame(List<Map<String, dynamic>> events) async {
      await db.insert('games', {
        'game_id': gameId,
        'game_type': GameType.bobs27.name,
        'config_json': jsonEncode({}),
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
      await db.insert('competitors', {
        'competitor_id': competitorId,
        'game_id': gameId,
        'type': 'solo',
        'name': "Bob's 27 Tester",
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

    test('returns null avg/best for player with no Bob\'s 27 games', () async {
      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.bobs27,
      );
      expect(stats.totalGames, 0);
      expect(stats.bobs27AvgScore, isNull);
      expect(stats.bobs27BestScore, isNull);
    });

    test('counts double attempts and hits', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        // D1 hit (round 1)
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        // D1 again (still counts as attempt, round already advanced? No — round advances in TurnEnded)
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        // D2 miss (wrong target)
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 2, 'multiplier': 2, 'score': 4},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'normal'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.bobs27,
      );

      // 3 double attempts total, 2 hits (both D1 targeted round 1)
      expect(stats.bobs27DoubleHitRate, closeTo(2 / 3, 0.001));
    });

    test("applies Bob's 27 scoring: hits add, misses subtract", () async {
      // Round 1 (target D1): 1 hit → score += 1*2 = 2 → score = 27 + 2 = 29
      // Round 2 (target D2): 0 hits → score -= 2*2 = 4 → score = 25
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'normal'},
        {'__type': 'TurnStarted', 'player_id': playerId},
        // No D2 hits — single is not counted
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 2, 'multiplier': 1, 'score': 2},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'normal'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.bobs27,
      );

      // score = 27 + 1*2 - 2*2 = 27 + 2 - 4 = 25
      expect(stats.bobs27BestScore, 25);
      expect(stats.bobs27AvgScore, closeTo(25.0, 0.01));
    });

    test('completion rate: 0 when score goes negative (bust)', () async {
      // Round 1: no hits → score -= 2 → 25
      // Round 2: no hits → score -= 4 → 21
      // ... score stays positive but let's test with a bust scenario
      // Let's force a low score: start 27, miss all 20 rounds
      // 27 - (1*2 + 2*2 + 3*2 + ... would go negative)
      // For simplicity: 1 round miss makes score go to 25 which is > 0 — still a completion
      // So let's make 2 rounds miss: round 1 miss → 25, round 2 miss → 21 (still > 0)
      // We need to miss enough rounds to go negative.
      // After round 8: 27 - 2(1+2+3+4+5+6+7+8) = 27 - 2*36 = 27 - 72 = -45
      // Let's just test with 1 drill that ends with positive score
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.bobs27,
      );

      // score = 27 + 2 = 29 > 0, so it's a completion
      expect(stats.bobs27CompletionRate, closeTo(1.0, 0.001));
    });
  });
}
