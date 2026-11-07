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
    const defaultGameId = 'game-c40-1';

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

    Future<void> _setupGame(
      List<Map<String, dynamic>> events, {
      String gameId = defaultGameId,
    }) async {
      final competitorId = '$gameId-comp';
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
          'event_id': '$gameId-evt-$seq',
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

    test('scores a 2-dart checkout as 3 points, not the dart sum', () async {
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

      expect(stats.catch40BestScore, 3);
      expect(stats.catch40AvgScore, closeTo(3.0, 0.01));
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
      expect(stats.catch40BestScore, 3);
      expect(stats.catch40AvgScore, closeTo(3.0, 0.01));
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

    Map<String, dynamic> turnStarted() =>
        {'__type': 'TurnStarted', 'player_id': playerId};
    Map<String, dynamic> dart(int segment, int multiplier) => {
          '__type': 'DartThrown',
          'player_id': playerId,
          'segment': segment,
          'multiplier': multiplier,
          'score': segment * multiplier,
        };
    Map<String, dynamic> turnEnded(String reason, int dartsOnTarget) => {
          '__type': 'TurnEnded',
          'player_id': playerId,
          'reason': reason,
          'darts_on_target': dartsOnTarget,
        };
    Map<String, dynamic> gameCompleted() =>
        {'__type': 'GameCompleted', 'winner_competitor_id': null};

    // Real event order: a drill ended with End Drill writes no LegCompleted.
    test('a drill with no checkout scores 0, not the darts thrown', () async {
      await _setupGame([
        // Target 61: S20 S20 S1 | S5 S5 S5 → failed after 6 darts.
        turnStarted(),
        dart(20, 1),
        dart(20, 1),
        dart(1, 1),
        turnEnded('normal', 3),
        turnStarted(),
        dart(5, 1),
        dart(5, 1),
        dart(5, 1),
        turnEnded('failed', 6),
        gameCompleted(),
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.totalGames, 1);
      expect(stats.catch40BestScore, 0);
      expect(stats.catch40AvgScore, closeTo(0.0, 0.01));
      expect(stats.catch40FailedCheckouts, 1);
    });

    test('a mixed drill sums 3/2/1 points per checkout and 0 per failure',
        () async {
      await _setupGame([
        // Target 61: 2-dart checkout → 3.
        turnStarted(),
        dart(17, 3),
        dart(5, 2),
        turnEnded('checkout', 2),
        // Target 62: failed → 0.
        turnStarted(),
        dart(0, 1),
        dart(0, 1),
        dart(0, 1),
        turnEnded('normal', 3),
        turnStarted(),
        dart(0, 1),
        dart(0, 1),
        dart(0, 1),
        turnEnded('failed', 6),
        // Target 63: 3-dart checkout → 2.
        turnStarted(),
        dart(20, 1),
        dart(3, 1),
        dart(20, 2),
        turnEnded('checkout', 3),
        // Target 64: 5-dart checkout straddling two visits → 1.
        turnStarted(),
        dart(0, 1),
        dart(0, 1),
        dart(0, 1),
        turnEnded('normal', 3),
        turnStarted(),
        dart(14, 1),
        dart(25, 2),
        turnEnded('checkout', 5),
        gameCompleted(),
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.catch40BestScore, 6);
      expect(stats.catch40AvgScore, closeTo(6.0, 0.01));
    });

    test('out 99 in 3 darts scores 3 (the only 3-dart out worth 3)',
        () async {
      // Targets 61..98 failed (38 targets), then 99 and 100 in 3 darts each.
      final events = <Map<String, dynamic>>[];
      for (var i = 0; i < 38; i++) {
        events
          ..add(turnStarted())
          ..add(turnEnded('failed', 6));
      }
      events.addAll([
        turnStarted(),
        dart(19, 3),
        dart(2, 1),
        dart(20, 2),
        turnEnded('checkout', 3), // 99 → 3
        turnStarted(),
        dart(20, 3),
        dart(20, 1),
        dart(10, 2),
        turnEnded('checkout', 3), // 100 → 2
        gameCompleted(),
      ]);
      await _setupGame(events);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.catch40BestScore, 5);
      expect(stats.catch40ThreeDartCheckouts, 2);
    });

    test('Avg/Best are taken over drill point totals', () async {
      // Drill A: one failed target → 0.
      await _setupGame([
        turnStarted(),
        turnEnded('failed', 6),
        gameCompleted(),
      ], gameId: 'game-c40-a');
      // Drill B: 2-dart (3) + 3-dart (2) checkouts → 5.
      await _setupGame([
        turnStarted(),
        dart(17, 3),
        dart(5, 2),
        turnEnded('checkout', 2),
        turnStarted(),
        dart(20, 1),
        dart(2, 1),
        dart(20, 2),
        turnEnded('checkout', 3),
        gameCompleted(),
      ], gameId: 'game-c40-b');

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.catch40,
      );

      expect(stats.totalGames, 2);
      expect(stats.catch40BestScore, 5);
      expect(stats.catch40AvgScore, closeTo(2.5, 0.01));
    });
  });
}
