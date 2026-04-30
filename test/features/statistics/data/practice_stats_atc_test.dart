// Around the Clock practice statistics scanner tests
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

  group('ATC practice stats — getPlayerStats', () {
    late SqfliteTestBase base;
    late StatisticsRepositoryImpl statsRepo;
    late Database db;

    const playerId = 'player-atc-1';
    const gameId = 'game-atc-1';
    const competitorId = 'comp-atc-1';

    setUp(() async {
      base = SqfliteTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryImpl(db);
      // Insert player
      await db.insert('players', {
        'player_id': playerId,
        'name': 'ATC Tester',
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    Future<void> _setupGame({
      String variant = 'standard',
      List<Map<String, dynamic>> events = const [],
    }) async {
      await db.insert('games', {
        'game_id': gameId,
        'game_type': GameType.aroundTheClock.name,
        'config_json': jsonEncode({'variant': variant}),
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
      await db.insert('competitors', {
        'competitor_id': competitorId,
        'game_id': gameId,
        'type': 'solo',
        'name': 'ATC Tester',
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
      await _setupGame(events: [
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

      await _setupGame(events: evts);

      final stats = await statsRepo.getPlayerStats(
        playerId,
        gameType: GameType.aroundTheClock,
      );

      expect(stats.atcCompletions, 1);
      expect(stats.atcAvgTurns, closeTo(2.0, 0.01));
      expect(stats.atcBestTurns, 2);
    });

    test('doublesOnly variant: only D-hits advance the target', () async {
      await _setupGame(variant: 'doublesOnly', events: [
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
      await _setupGame(events: [
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
  });
}
