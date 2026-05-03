// Unit tests for PlayerStatsAssembler.
//
// These run against synthetic event lists with no DB. They lock in the
// projection-replay contract (notably: 3-dart average INCLUDES busted-turn
// points; high-score buckets and highest-turn-score still EXCLUDE busts).

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const assembler = PlayerStatsAssembler();
  const playerId = 'p1';
  const gameId = 'g1';
  final fixedTime = DateTime.utc(2026, 1, 1);

  int seq = 0;
  GameEvent event(String type, Map<String, dynamic> payload) {
    seq++;
    return GameEvent(
      eventId: 'e$seq',
      gameId: gameId,
      eventType: type,
      localSequence: seq,
      occurredAt: fixedTime,
      payload: payload,
      synced: false,
      actorId: playerId,
      source: EventSource.client,
    );
  }

  setUp(() {
    seq = 0;
  });

  GameEvent dart(int segment, int multiplier) => event('DartThrown', {
        'player_id': playerId,
        'segment': segment,
        'multiplier': multiplier,
        'score': segment * multiplier,
      });

  GameEvent turnStarted({int turnNumber = 1, int? startingScore}) {
    final payload = <String, dynamic>{
      'player_id': playerId,
      'turn_number': turnNumber,
    };
    if (startingScore != null) payload['starting_score'] = startingScore;
    return event('TurnStarted', payload);
  }

  GameEvent turnEnded({String? reason}) {
    final payload = <String, dynamic>{'player_id': playerId};
    if (reason != null) payload['reason'] = reason;
    return event('TurnEnded', payload);
  }

  GameEvent legCompleted({String? winnerPlayerId}) {
    final payload = <String, dynamic>{};
    if (winnerPlayerId != null) payload['winner_player_id'] = winnerPlayerId;
    return event('LegCompleted', payload);
  }

  GameEvent gameCompleted({String? winnerPlayerId}) {
    final payload = <String, dynamic>{};
    if (winnerPlayerId != null) payload['winner_player_id'] = winnerPlayerId;
    return event('GameCompleted', payload);
  }

  group('X01', () {
    test('empty events → zero-valued PlayerStats', () {
      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: const [],
        totalGames: 0,
        totalDartsThrown: 0,
      );

      expect(stats.playerId, playerId);
      expect(stats.gameType, GameType.x01);
      expect(stats.threeDartAverage, 0.0);
      expect(stats.totalDartsThrown, 0);
      expect(stats.gamesWon, 0);
      expect(stats.legsWon, 0);
    });

    test('clean leg → AVG = (sum / darts) * 3', () {
      // T20 + T20 + T20 = 180 on 3 darts → AVG 180.
      final events = [
        turnStarted(startingScore: 501),
        dart(20, 3),
        dart(20, 3),
        dart(20, 3),
        turnEnded(),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: events,
        totalGames: 1,
        totalDartsThrown: 3,
      );

      expect(stats.threeDartAverage, 180.0);
      expect(stats.oneEightyTurns, 1);
      expect(stats.oneFortyPlusTurns, 0); // exclusive bucket per fix #83
    });

    test('busted turn → points still count in AVG; bucket excludes the bust',
        () {
      // Turn 1: T20 + T20 + T20 (180) → bust. AVG numerator gets 180,
      //         but high-score buckets still skip busted turns.
      // Turn 2: T20 + T20 + T20 (180) → not bust. Bucket counts this.
      // AVG = (180 + 180) / 6 * 3 = 180.
      final events = [
        turnStarted(turnNumber: 1, startingScore: 100),
        dart(20, 3),
        dart(20, 3),
        dart(20, 3),
        turnEnded(reason: 'bust'),
        turnStarted(turnNumber: 2, startingScore: 100),
        dart(20, 3),
        dart(20, 3),
        dart(20, 3),
        turnEnded(),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: events,
        totalGames: 1,
        totalDartsThrown: 6,
      );

      expect(stats.threeDartAverage, 180.0);
      expect(stats.bustRate, 0.5);
      // Bucket excludes the busted 180.
      expect(stats.oneEightyTurns, 1);
    });

    test('high-score bucket lands in 60+ exclusive bucket only', () {
      // T20 + 5 + 5 = 70, no other scoring turns.
      final events = [
        turnStarted(startingScore: 501),
        dart(20, 3),
        dart(5, 1),
        dart(5, 1),
        turnEnded(),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: events,
        totalGames: 1,
        totalDartsThrown: 3,
      );

      expect(stats.sixtyPlusTurns, 1);
      expect(stats.oneHundredPlusTurns, 0);
      expect(stats.oneFortyPlusTurns, 0);
      expect(stats.oneEightyTurns, 0);
    });
  });

  group('cricket', () {
    test('happy path produces marksPerTurn and hitRate', () {
      // One turn: T20 (3 marks), T19 (3 marks), T18 (3 marks) = 9 marks / 3 darts.
      final events = [
        turnStarted(),
        dart(20, 3),
        dart(19, 3),
        dart(18, 3),
        turnEnded(),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.cricket,
        events: events,
        totalGames: 1,
        totalDartsThrown: 3,
      );

      expect(stats.gameType, GameType.cricket);
      expect(stats.marksPerTurn, 9.0);
      expect(stats.hitRate, 1.0);
      expect(stats.nineMarkTurns, 1);
    });
  });

  group('practice — Around the Clock', () {
    test('completions tracked when targets 1..20 are all hit', () {
      // Hit targets 1 through 20 in sequence (one dart each, all single).
      final events = <GameEvent>[];
      for (int target = 1; target <= 20; target++) {
        events.addAll([
          turnStarted(),
          dart(target, 1),
          turnEnded(),
        ]);
      }
      events.add(gameCompleted(winnerPlayerId: playerId));

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.aroundTheClock,
        events: events,
        totalGames: 1,
        totalDartsThrown: 20,
      );

      expect(stats.atcCompletions, 1);
      expect(stats.atcHitRate, 1.0);
      expect(stats.atcBestTurns, 20);
    });

    test('doublesOnly variant requires multiplier 2 for a hit', () {
      // Hit target 1 with single → not a hit under doublesOnly variant.
      final events = [
        turnStarted(),
        dart(1, 1),
        turnEnded(),
        gameCompleted(),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.aroundTheClock,
        events: events,
        totalGames: 1,
        totalDartsThrown: 1,
        atcVariant: 'doublesOnly',
      );

      expect(stats.atcHitRate, 0.0);
      expect(stats.atcCompletions, 0);
    });
  });

  group("practice — Bob's 27", () {
    test('one drill with one D1 hit then LegCompleted updates score and rates',
        () {
      // Round 1: hit D1 once (mult=2 on segment 1), miss twice with singles.
      //   doubleAttempts = 1 (only the D1 throw is a double)
      //   doubleHits     = 1 (D1 = double of round 1)
      //   currentScore   = 27 + 1 * 1 * 2 = 29
      // LegCompleted: drill counted as a completed, successful drill.
      final events = [
        turnStarted(turnNumber: 1),
        dart(1, 2),
        dart(20, 1),
        dart(20, 1),
        turnEnded(),
        legCompleted(winnerPlayerId: playerId),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.bobs27,
        events: events,
        totalGames: 1,
        totalDartsThrown: 3,
      );

      expect(stats.bobs27AvgScore, 29.0);
      expect(stats.bobs27BestScore, 29);
      expect(stats.bobs27CompletionRate, 1.0);
      expect(stats.bobs27DoubleHitRate, 1.0);
    });
  });

  group('practice — Shanghai', () {
    test('S1 + D1 + T1 in round 1 counts as a Shanghai', () {
      // All three multipliers (1, 2, 3) hit the round-1 target → Shanghai.
      // Score = 1 + 2 + 3 = 6.
      final events = [
        turnStarted(turnNumber: 1),
        dart(1, 1),
        dart(1, 2),
        dart(1, 3),
        turnEnded(),
        legCompleted(winnerPlayerId: playerId),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.shanghai,
        events: events,
        totalGames: 1,
        totalDartsThrown: 3,
      );

      expect(stats.shanghaiCount, 1);
      expect(stats.shanghaiAvgScore, 6.0);
      expect(stats.shanghaiBestScore, 6);
    });
  });

  group('practice — Catch-40', () {
    test('classifies checkouts by turn dart count', () {
      // Two checkouts: one in 2 darts, one in 3 darts.
      final events = [
        turnStarted(),
        dart(20, 1),
        dart(20, 1),
        turnEnded(reason: 'checkout'),
        turnStarted(),
        dart(10, 1),
        dart(10, 1),
        dart(10, 1),
        turnEnded(reason: 'checkout'),
        legCompleted(winnerPlayerId: playerId),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.catch40,
        events: events,
        totalGames: 1,
        totalDartsThrown: 5,
      );

      expect(stats.catch40TwoDartCheckouts, 1);
      expect(stats.catch40ThreeDartCheckouts, 1);
      expect(stats.catch40FailedCheckouts, 0);
    });
  });

  group('practice — Checkout', () {
    test('counts attempts and successes from TurnEnded reason', () {
      final events = [
        turnStarted(),
        dart(20, 3),
        turnEnded(reason: 'checkout'),
        turnStarted(),
        dart(20, 3),
        turnEnded(reason: 'failed'),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.checkoutPractice,
        events: events,
        totalGames: 1,
        totalDartsThrown: 2,
      );

      expect(stats.checkoutAttempts, 2);
      expect(stats.checkoutSuccesses, 1);
      expect(stats.checkoutSuccessRate, 0.5);
    });
  });

  group('totalGames / totalDartsThrown passthrough', () {
    test('values from caller are preserved on the result', () {
      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: const [],
        totalGames: 42,
        totalDartsThrown: 1234,
      );

      expect(stats.totalGames, 42);
      expect(stats.totalDartsThrown, 1234);
    });
  });

  // ── gameStatsFromEvents ─────────────────────────────────────────────────────

  group('gameStatsFromEvents', () {
    test('empty throws → empty byCompetitor list, gameType set', () {
      final stats = assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: GameType.x01,
        throws: const [],
        competitorNames: const {},
        events: const [],
      );

      expect(stats.gameId, gameId);
      expect(stats.byCompetitor, isEmpty);
      expect(stats.gameType, 'x01');
    });

    test(
        'X01 — per-player and per-competitor AVG include all darts (busts not subtracted)',
        () {
      // Solo competitor; one player; one bust + one normal turn, both 180.
      // Per X01 convention now: AVG = (180 + 180) / 6 * 3 = 180.
      final events = [
        turnStarted(turnNumber: 1, startingScore: 100),
        dart(20, 3),
        dart(20, 3),
        dart(20, 3),
        turnEnded(reason: 'bust'),
        turnStarted(turnNumber: 2, startingScore: 100),
        dart(20, 3),
        dart(20, 3),
        dart(20, 3),
        turnEnded(),
      ];

      final throws = [
        for (var i = 0; i < 6; i++)
          (competitorId: 'c1', playerId: playerId, score: 60),
      ];

      final stats = assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: GameType.x01,
        throws: throws,
        competitorNames: const {'c1': 'Alice'},
        events: events,
      );

      expect(stats.byCompetitor.length, 1);
      final c = stats.byCompetitor.single;
      expect(c.competitorName, 'Alice');
      expect(c.totalDartsThrown, 6);
      expect(c.threeDartAverage, 180.0);
      expect(c.byPlayer.single.threeDartAverage, 180.0);
      // Bucket excludes the busted 180.
      expect(c.oneEightyTurns, 1);
    });

    test('legsWon counted from LegCompleted events with matching competitor',
        () {
      final events = [
        // Leg 1 — c1 wins
        legCompleted(),
        // Manually inject a competitor-targeted LegCompleted via event helper.
      ];
      // Replace the simple legCompleted with one that targets c1.
      final betterEvents = [
        event('LegCompleted', {'winner_competitor_id': 'c1'}),
        event('LegCompleted', {'winner_competitor_id': 'c2'}),
        event('LegCompleted', {'winner_competitor_id': 'c1'}),
      ];

      final stats = assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: GameType.x01,
        throws: [
          (competitorId: 'c1', playerId: 'p1', score: 60),
          (competitorId: 'c2', playerId: 'p2', score: 60),
        ],
        competitorNames: const {'c1': 'Alice', 'c2': 'Bob'},
        events: [...events, ...betterEvents],
      );

      final c1 = stats.byCompetitor.firstWhere((c) => c.competitorId == 'c1');
      final c2 = stats.byCompetitor.firstWhere((c) => c.competitorId == 'c2');
      expect(c1.legsWon, 2);
      expect(c2.legsWon, 1);
    });

    test('competitor missing from competitorNames is skipped', () {
      final stats = assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: GameType.x01,
        throws: [
          (competitorId: 'c1', playerId: 'p1', score: 60),
          (competitorId: 'c-orphan', playerId: 'p2', score: 60),
        ],
        competitorNames: const {'c1': 'Alice'},
        events: const [],
      );

      expect(stats.byCompetitor.length, 1);
      expect(stats.byCompetitor.single.competitorId, 'c1');
    });

    test('cricket — per-competitor mark stats from projections', () {
      // Solo cricket competitor; one turn of T20+T19+T18 = 9 marks / 3 darts.
      final events = [
        turnStarted(),
        dart(20, 3),
        dart(19, 3),
        dart(18, 3),
        turnEnded(),
      ];

      final stats = assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: GameType.cricket,
        throws: [
          for (var i = 0; i < 3; i++)
            (competitorId: 'c1', playerId: playerId, score: 0),
        ],
        competitorNames: const {'c1': 'Alice'},
        events: events,
      );

      final c = stats.byCompetitor.single;
      expect(c.marksPerRound, 9.0);
      expect(c.nineMarkTurns, 1);
    });
  });
}
