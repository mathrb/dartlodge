// Catch-40 practice statistics scanner tests
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/persistence/drift/database.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/statistics_repository_drift.dart';

import '../../../drift_test_base.dart';

void main() {

  group('Catch-40 practice stats — getPlayerStats', () {
    late DriftTestBase base;
    late StatisticsRepositoryDrift statsRepo;
    late AppDatabase db;

    const playerId = 'player-c40-1';
    const gameId = 'game-c40-1';
    const competitorId = 'comp-c40-1';

    setUp(() async {
      base = DriftTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryDrift(db);
      await db.rawInsert('players', {
        'player_id': playerId,
        'name': 'Catch-40 Tester',
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    Future<void> _setupGame(List<Map<String, dynamic>> events) async {
      await db.rawInsert('games', {
        'game_id': gameId,
        'game_type': GameType.catch40.name,
        'config_json': jsonEncode({}),
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
      await db.rawInsert('competitors', {
        'competitor_id': competitorId,
        'game_id': gameId,
        'type': 'solo',
        'name': 'Catch-40 Tester',
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

    // Regression for #253: production catch40 emits GameCompleted on natural
    // completion (and on End Drill via EndPracticeUseCase) but never
    // LegCompleted — it's a 1-leg solo drill. The original projection only
    // closed games on LegCompleted, so real drills silently reported
    // `Drills Played: 0` and never accumulated avg/best score.
    test('accumulates totals on GameCompleted (no LegCompleted)', () async {
      await _setupGame([
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout', 'darts_on_target': 2},
        {'__type': 'GameCompleted', 'winner_competitor_id': null},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.totalGames, 1);
      expect(stats.catch40BestScore, 80);
      expect(stats.catch40AvgScore, closeTo(80.0, 0.01));
      expect(stats.catch40TwoDartCheckouts, 1);
    });

    // The 4-dart checkout (3 darts in turn 1, 1 dart in turn 2) was the
    // hidden killer: `turnDarts` reset on TurnStarted between visits, so the
    // projection only saw 1 dart on the closing TurnEnded and never
    // classified the checkout. `darts_on_target` (emitted by the producer
    // from the engine's `catch40DartsOnTarget` counter) fixes this.
    test('classifies 4-dart checkout via darts_on_target (turn-straddling)',
        () async {
      await _setupGame([
        // Visit 1: 3 misses (no checkout, auto-advance)
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 0, 'multiplier': 1, 'score': 0},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 0, 'multiplier': 1, 'score': 0},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 0, 'multiplier': 1, 'score': 0},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'normal', 'darts_on_target': 3},
        // Visit 2: 1 dart checkout (turn-local dart count = 1, but darts on target = 4)
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 20, 'multiplier': 2, 'score': 40},
        {'__type': 'TurnEnded', 'player_id': playerId, 'reason': 'checkout', 'darts_on_target': 4},
        {'__type': 'GameCompleted', 'winner_competitor_id': null},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.catch40FourSixDartCheckouts, 1,
          reason: '4 darts on target falls in the 4–6 bucket.');
      expect(stats.catch40TwoDartCheckouts, 0);
      expect(stats.catch40ThreeDartCheckouts, 0);
    });
  });
}
