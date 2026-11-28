// Around the Clock practice statistics scanner tests
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/persistence/drift/database.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/statistics_repository_drift.dart';

import '../../../drift_test_base.dart';

void main() {
  group('ATC practice stats — getPlayerStats', () {
    late DriftTestBase base;
    late StatisticsRepositoryDrift statsRepo;
    late AppDatabase db;

    const playerId = 'player-atc-1';
    const gameId = 'game-atc-1';

    setUp(() async {
      base = DriftTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryDrift(db);
      await db.rawInsert('players', {
        'player_id': playerId,
        'name': 'ATC Tester',
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    Future<void> setupGame({
      String variant = 'standard',
      List<Map<String, dynamic>> events = const [],
      String gameId = gameId,
      DateTime? startTime,
    }) async {
      final competitorId = '$gameId-comp';
      await db.rawInsert('games', {
        'game_id': gameId,
        'game_type': GameType.aroundTheClock.name,
        'config_json': jsonEncode({'variant': variant}),
        'start_time': (startTime ?? DateTime.now()).toIso8601String(),
        'is_complete': 1,
      });
      await db.rawInsert('competitors', {
        'competitor_id': competitorId,
        'game_id': gameId,
        'type': 'solo',
        'name': 'ATC Tester',
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

    test('returns zero stats when player has no ATC games', () async {
      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.aroundTheClock,
      );
      expect(stats.totalGames, 0);
      expect(stats.atcCompletions, 0);
      expect(stats.atcHitRate, isNull);
    });

    test('counts darts at target and hits correctly', () async {
      await setupGame(events: [
        {'__type': 'TurnStarted', 'player_id': playerId},
        // Hit target 1
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 1, 'score': 1},
        // Miss target 2 (different segment)
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 5, 'multiplier': 1, 'score': 5},
        // Miss target 2 again
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 7, 'multiplier': 1, 'score': 7},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': null},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.aroundTheClock,
      );

      expect(stats.totalGames, 1);
      // 1 dart at target 1 (hit), 2 darts at target 2 (miss) = 3 darts at targets, 1 hit
      expect(stats.atcHitRate, closeTo(1 / 3, 0.001));
    });

    test('counts completions and computes avg/best turns', () async {
      // 2 turns to complete (hit all 20 targets in 2 turns: 10 per turn)
      final evts = <Map<String, dynamic>>[
        {'__type': 'TurnStarted', 'player_id': playerId},
      ];
      for (int t = 1; t <= 10; t++) {
        evts.add({'__type': 'DartThrown', 'player_id': playerId, 'segment': t, 'multiplier': 1, 'score': t});
      }
      evts.add({'__type': 'TurnEnded', 'player_id': playerId});
      evts.add({'__type': 'TurnStarted', 'player_id': playerId});
      for (int t = 11; t <= 20; t++) {
        evts.add({'__type': 'DartThrown', 'player_id': playerId, 'segment': t, 'multiplier': 1, 'score': t});
      }
      evts.add({'__type': 'TurnEnded', 'player_id': playerId});
      evts.add({'__type': 'LegCompleted', 'winner_player_id': playerId});

      await setupGame(events: evts);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.aroundTheClock,
      );

      expect(stats.atcCompletions, 1);
      expect(stats.atcAvgTurns, closeTo(2.0, 0.01));
      expect(stats.atcBestTurns, 2);
    });

    test('doublesOnly variant: only D-hits advance the target', () async {
      await setupGame(variant: 'doublesOnly', events: [
        {'__type': 'TurnStarted', 'player_id': playerId},
        // Single 1 — not a hit in doublesOnly
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 1, 'score': 1},
        // Double 1 — hit in doublesOnly
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 2, 'score': 2},
        // Single 2 — not a hit (wrong multiplier for doublesOnly)
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 2, 'multiplier': 1, 'score': 2},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': null},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.aroundTheClock,
      );

      // 3 darts at targets (S1, D1, S2), 1 hit (D1)
      expect(stats.atcHitRate, closeTo(1 / 3, 0.001));
    });

    test('non-completing drill: atcCompletions stays 0', () async {
      await setupGame(events: [
        {'__type': 'TurnStarted', 'player_id': playerId},
        {'__type': 'DartThrown', 'player_id': playerId, 'segment': 1, 'multiplier': 1, 'score': 1},
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'LegCompleted', 'winner_player_id': null},
      ]);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.aroundTheClock,
      );

      expect(stats.atcCompletions, 0);
      expect(stats.atcBestTurns, isNull);
    });

    group('mixed variants: each drill replays with its own variant', () {
      Map<String, dynamic> dartAt(int segment, [int multiplier = 1]) => {
        '__type': 'DartThrown',
        'player_id': playerId,
        'segment': segment,
        'multiplier': multiplier,
        'score': segment * multiplier,
      };
      List<Map<String, dynamic>> oneTurn(List<Map<String, dynamic>> darts) => [
        {'__type': 'TurnStarted', 'player_id': playerId},
        ...darts,
        {'__type': 'TurnEnded', 'player_id': playerId},
        {'__type': 'GameCompleted', 'winner_player_id': null},
      ];

      Future<void> reverseThenStandard({required bool reverseIsOlder}) async {
        // Reverse: 20, 19, 18 -> 3 hits / 3 darts.
        await setupGame(
          gameId: 'g-rev',
          variant: 'reverse',
          startTime: reverseIsOlder
              ? DateTime(2026, 11, 1)
              : DateTime(2026, 11, 2),
          events: oneTurn([dartAt(20), dartAt(19), dartAt(18)]),
        );
        // Standard: 1, 5, 7 -> 1 hit / 3 darts.
        await setupGame(
          gameId: 'g-std',
          variant: 'standard',
          startTime: reverseIsOlder
              ? DateTime(2026, 11, 2)
              : DateTime(2026, 11, 1),
          events: oneTurn([dartAt(1), dartAt(5), dartAt(7)]),
        );
      }

      test('Reverse drill followed by a newer Standard drill', () async {
        await reverseThenStandard(reverseIsOlder: true);

        final stats = await statsRepo.getPlayerStats(
          playerId,
          gameType: GameType.aroundTheClock,
        );

        expect(stats.totalGames, 2);
        expect(stats.atcHitRate, closeTo(4 / 6, 0.001));
        expect(stats.atcSegmentHits[20], 1);
        expect(stats.atcSegmentHits[19], 1);
        expect(stats.atcSegmentHits[18], 1);
        expect(stats.atcSegmentHits[1], 1);
      });

      test('Standard drill followed by a newer Reverse drill', () async {
        await reverseThenStandard(reverseIsOlder: false);

        final stats = await statsRepo.getPlayerStats(
          playerId,
          gameType: GameType.aroundTheClock,
        );

        expect(stats.atcHitRate, closeTo(4 / 6, 0.001));
        expect(stats.atcSegmentHits[1], 1);
        expect(stats.atcSegmentHits[20], 1);
      });

      test('Doubles Only drill next to a newer Standard drill', () async {
        // Doubles Only: S1 (no hit), D1 (hit) -> 1 / 2.
        await setupGame(
          gameId: 'g-dbl',
          variant: 'doublesOnly',
          startTime: DateTime(2026, 11, 1),
          events: oneTurn([dartAt(1), dartAt(1, 2)]),
        );
        // Standard: S1 (hit) -> 1 / 1.
        await setupGame(
          gameId: 'g-std',
          variant: 'standard',
          startTime: DateTime(2026, 11, 2),
          events: oneTurn([dartAt(1)]),
        );

        final stats = await statsRepo.getPlayerStats(
          playerId,
          gameType: GameType.aroundTheClock,
        );

        expect(stats.atcHitRate, closeTo(2 / 3, 0.001));
        expect(stats.atcSegmentHits[1], 2);
        expect(stats.atcSegmentAttempts[1], 3);
      });

      test(
        'a completed Reverse drill still counts after a newer Standard drill',
        () async {
          // Reverse drill completed in 2 turns: 20..11, then 10..1.
          await setupGame(
            gameId: 'g-rev',
            variant: 'reverse',
            startTime: DateTime(2026, 11, 1),
            events: [
              {'__type': 'TurnStarted', 'player_id': playerId},
              for (int t = 20; t >= 11; t--) dartAt(t),
              {'__type': 'TurnEnded', 'player_id': playerId},
              {'__type': 'TurnStarted', 'player_id': playerId},
              for (int t = 10; t >= 1; t--) dartAt(t),
              {'__type': 'TurnEnded', 'player_id': playerId},
              {'__type': 'GameCompleted', 'winner_player_id': playerId},
            ],
          );
          // Standard drill, not completed: 1 hit / 3.
          await setupGame(
            gameId: 'g-std',
            variant: 'standard',
            startTime: DateTime(2026, 11, 2),
            events: oneTurn([dartAt(1), dartAt(5), dartAt(7)]),
          );

          final stats = await statsRepo.getPlayerStats(
            playerId,
            gameType: GameType.aroundTheClock,
          );

          expect(stats.atcCompletions, 1);
          expect(stats.atcBestTurns, 2);
          expect(stats.atcAvgTurns, closeTo(2.0, 0.01));
          expect(stats.atcHitRate, closeTo(21 / 23, 0.001));
        },
      );
    });
  });
}
