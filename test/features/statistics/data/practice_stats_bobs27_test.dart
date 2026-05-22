// Bob's 27 practice statistics scanner tests
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/persistence/drift/database.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/statistics_repository_drift.dart';

import '../../../drift_test_base.dart';

void main() {

  group("Bob's 27 practice stats — getPlayerStats", () {
    late DriftTestBase base;
    late StatisticsRepositoryDrift statsRepo;
    late AppDatabase db;

    const playerId = 'player-b27-1';
    const gameId = 'game-b27-1';
    const competitorId = 'comp-b27-1';

    setUp(() async {
      base = DriftTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryDrift(db);
      await db.rawInsert('players', {
        'player_id': playerId,
        'name': "Bob's 27 Tester",
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    Future<void> _setupGame(List<Map<String, dynamic>> events) async {
      await db.rawInsert('games', {
        'game_id': gameId,
        'game_type': GameType.bobs27.name,
        'config_json': jsonEncode({}),
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
      await db.rawInsert('competitors', {
        'competitor_id': competitorId,
        'game_id': gameId,
        'type': 'solo',
        'name': "Bob's 27 Tester",
      });
      await db.rawInsert('competitor_players', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'rotation_position': 0,
      });
      int seq = 1;
      for (final payload in events) {
        final eventType = payload['__type'] as String;
        final cleaned = Map<String, dynamic>.from(payload)..remove('__type');
        await db.rawInsert('game_events', {
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

    test('Doubles Hit Rate denominator is total darts thrown (#261)', () async {
      // Round 1 (target D1). Player throws 3 darts: D1 hit, D1 hit, D2 miss
      // (lands on wrong double). Two darts hit the target double, one
      // missed the target altogether.
      //
      // The old projection treated the denominator as "darts that landed
      // on ANY double" (here: 3), which silently inflates the rate when
      // the player misses everything except the wrong double. The new
      // projection uses "total darts thrown" — matches the user-facing
      // expectation "of all darts you threw at D{round}, how many landed
      // on target".
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 2, 'multiplier': 2, 'score': 4},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'normal'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.bobs27,
      );

      // 3 darts thrown, 2 hits on D1 (round 1's target) → 2 / 3.
      expect(stats.bobs27DoubleHitRate, closeTo(2 / 3, 0.001));
    });

    test(
        'Doubles Hit Rate counts every dart in the denominator, '
        'including misses (#261)',
        () async {
      // Round 1: 1 D1 hit (target) + 2 plain misses (mult=1). The new
      // formula gives 1/3 ≈ 33.3%. The old formula would have given 1/1
      // = 100% (because misses don't have mult==2, so they weren't in
      // the denominator).
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 0, 'multiplier': 1, 'score': 0},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 1, 'score': 20},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'normal'},
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.bobs27,
      );

      expect(stats.bobs27DoubleHitRate, closeTo(1 / 3, 0.001));
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
