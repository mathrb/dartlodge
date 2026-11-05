// Shanghai practice statistics scanner tests.
//
// Fixtures follow the real event order written by the app: a drill that runs
// to the last round ends with its final TurnEnded followed by GameCompleted
// (ActivePracticeNotifier._advanceTurn), and a Shanghai instant win ends with
// the third DartThrown followed directly by GameCompleted, with no TurnEnded
// (ProcessPracticeDartUseCase). Shanghai never writes LegCompleted.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/persistence/drift/database.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/statistics_repository_drift.dart';

import '../../../drift_test_base.dart';

void main() {
  group('Shanghai practice stats — getPlayerStats', () {
    late DriftTestBase base;
    late StatisticsRepositoryDrift statsRepo;
    late AppDatabase db;

    const playerId = 'player-sha-1';
    const opponentId = 'player-sha-2';

    setUp(() async {
      base = DriftTestBase();
      await base.setUp();
      db = base.db;
      statsRepo = StatisticsRepositoryDrift(db);
      for (final (id, name) in [
        (playerId, 'Shanghai Tester'),
        (opponentId, 'Opponent'),
      ]) {
        await db.rawInsert('players', {
          'player_id': id,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
          'last_active': DateTime.now().toIso8601String(),
        });
      }
    });

    tearDown(() async => base.tearDown());

    Future<void> setupGame(
      String gameId,
      List<Map<String, dynamic>> events, {
      List<String> players = const [playerId],
    }) async {
      await db.rawInsert('games', {
        'game_id': gameId,
        'game_type': GameType.shanghai.name,
        'config_json': jsonEncode({}),
        'start_time': DateTime.now().toIso8601String(),
        'is_complete': 1,
      });
      for (var i = 0; i < players.length; i++) {
        final competitorId = '$gameId-comp-$i';
        await db.rawInsert('competitors', {
          'competitor_id': competitorId,
          'game_id': gameId,
          'type': 'solo',
          'name': players[i],
        });
        await db.rawInsert('competitor_players', {
          'competitor_id': competitorId,
          'player_id': players[i],
          'rotation_position': 0,
        });
      }
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
          'actor_id': cleaned['player_id'] ?? playerId,
          'source': EventSource.client.index,
        });
      }
    }

    // `score` mirrors the real payload: the raw dart value
    // (Segment.scoreValue), not the Shanghai points.
    Map<String, dynamic> dart(String pid, int segment, int multiplier) => {
          '__type': 'DartThrown',
          'player_id': pid,
          'segment': segment,
          'multiplier': multiplier,
          'score': segment * multiplier,
        };

    /// One full visit: TurnStarted, the darts, TurnEnded.
    List<Map<String, dynamic>> turn(String pid, List<(int, int)> darts) => [
          {'__type': 'TurnStarted', 'player_id': pid},
          for (final (s, m) in darts) dart(pid, s, m),
          {'__type': 'TurnEnded', 'player_id': pid},
        ];

    Map<String, dynamic> gameCompleted() => {'__type': 'GameCompleted'};

    Future<dynamic> stats() =>
        statsRepo.getPlayerStats(playerId, gameType: GameType.shanghai);

    test('returns null avg/best for player with no Shanghai games', () async {
      final s = await stats();
      expect(s.totalGames, 0);
      expect(s.shanghaiAvgScore, isNull);
      expect(s.shanghaiBestScore, isNull);
      expect(s.shanghaiCount, 0);
    });

    test('a drill that ends on GameCompleted (no LegCompleted) is counted',
        () async {
      await setupGame('g1', [
        // Round 1: S1 + T5 (off target) + D1 → 1 + 0 + 2 = 3
        ...turn(playerId, [(1, 1), (5, 3), (1, 2)]),
        // Round 2: T2 + S2 + S20 (off target) → 6 + 2 + 0 = 8
        ...turn(playerId, [(2, 3), (2, 1), (20, 1)]),
        gameCompleted(),
      ]);

      final s = await stats();
      expect(s.shanghaiBestScore, 11);
      expect(s.shanghaiAvgScore, closeTo(11.0, 0.01));
      expect(s.shanghaiCount, 0);
    });

    test('only hits on the round number score, worth number × multiplier',
        () async {
      await setupGame('g1', [
        // Round 1: T20, Bull, Miss — raw dart values 60 + 25 + 0, Shanghai 0.
        ...turn(playerId, [(20, 3), (25, 1), (0, 1)]),
        // Round 2: D2 → 4.
        ...turn(playerId, [(2, 2), (0, 1), (0, 1)]),
        gameCompleted(),
      ]);

      final s = await stats();
      expect(s.shanghaiBestScore, 4);
    });

    test('Shanghai instant win (GameCompleted right after the 3rd dart)',
        () async {
      await setupGame('g1', [
        // Round 1: no Shanghai, 1 point.
        ...turn(playerId, [(1, 1), (0, 1), (0, 1)]),
        // Round 2: S2 + D2 + T2 = Shanghai → 2 + 4 + 6 = 12, game ends on
        // the dart: no TurnEnded.
        {'__type': 'TurnStarted', 'player_id': playerId},
        dart(playerId, 2, 1),
        dart(playerId, 2, 2),
        dart(playerId, 2, 3),
        gameCompleted(),
      ]);

      final s = await stats();
      expect(s.shanghaiCount, 1);
      expect(s.shanghaiBestScore, 13);
    });

    test('Shanghai counted once when the turn also has a TurnEnded', () async {
      await setupGame('g1', [
        ...turn(playerId, [(1, 1), (1, 2), (1, 3)]),
        gameCompleted(),
      ]);

      final s = await stats();
      expect(s.shanghaiCount, 1);
      expect(s.shanghaiBestScore, 6);
    });

    test('no Shanghai when not all multipliers hit in one turn', () async {
      await setupGame('g1', [
        // S1 + D1 + S5 → no triple of the round number.
        ...turn(playerId, [(1, 1), (1, 2), (5, 1)]),
        // S2 + S2 + S2 → three hits but one multiplier.
        ...turn(playerId, [(2, 1), (2, 1), (2, 1)]),
        gameCompleted(),
      ]);

      final s = await stats();
      expect(s.shanghaiCount, 0);
    });

    test('avg and best across separate drills', () async {
      // Drill 1: D1 → 2. Drill 2: T1 + T2 → 3 + 6 = 9. Avg 5.5.
      await setupGame('g1', [
        ...turn(playerId, [(1, 2), (0, 1), (0, 1)]),
        gameCompleted(),
      ]);
      await setupGame('g2', [
        ...turn(playerId, [(1, 3), (0, 1), (0, 1)]),
        ...turn(playerId, [(2, 3), (0, 1), (0, 1)]),
        gameCompleted(),
      ]);

      final s = await stats();
      expect(s.totalGames, 2);
      expect(s.shanghaiAvgScore, closeTo(5.5, 0.01));
      expect(s.shanghaiBestScore, 9);
    });

    test('opponent darts and rounds do not leak into the player score',
        () async {
      await setupGame(
        'g1',
        [
          // Round 1: player D1 (2), opponent T1 (3).
          ...turn(playerId, [(1, 2), (0, 1), (0, 1)]),
          ...turn(opponentId, [(1, 3), (1, 3), (1, 3)]),
          // Round 2: player S2 (2), opponent Shanghai on 2.
          ...turn(playerId, [(2, 1), (0, 1), (0, 1)]),
          {'__type': 'TurnStarted', 'player_id': opponentId},
          dart(opponentId, 2, 1),
          dart(opponentId, 2, 2),
          dart(opponentId, 2, 3),
          gameCompleted(),
        ],
        players: [playerId, opponentId],
      );

      final s = await stats();
      expect(s.shanghaiBestScore, 4);
      expect(s.shanghaiCount, 0);
    });

    test('a legacy stream with LegCompleted then GameCompleted counts once',
        () async {
      await setupGame('g1', [
        ...turn(playerId, [(1, 3), (0, 1), (0, 1)]),
        {'__type': 'LegCompleted', 'winner_player_id': playerId},
        gameCompleted(),
      ]);

      final s = await stats();
      expect(s.shanghaiAvgScore, closeTo(3.0, 0.01));
      expect(s.shanghaiBestScore, 3);
    });
  });
}
