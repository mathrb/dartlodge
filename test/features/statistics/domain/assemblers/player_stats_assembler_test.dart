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

  // ── DartCorrected handling (regression tests for issue #129) ───────────────

  group('DartCorrected replay', () {
    // Helper: build an event for an arbitrary game and sequence (the global
    // `event()` helper above hardcodes gameId='g1' and uses a monotonic
    // counter, which breaks multi-game fixtures where local_sequence must
    // restart at 1 per game).
    GameEvent rawEvent({
      required String gameId,
      required int seq,
      required String type,
      required Map<String, dynamic> payload,
      String eventId = '',
    }) {
      return GameEvent(
        eventId: eventId.isEmpty ? '$gameId-$seq-$type' : eventId,
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

    test(
        'replayFrom does not drop uncorrected co-loaded game events '
        '(regression #129 sub-task 3)', () {
      // Two games co-loaded for the same player:
      //   - game-A: a turn followed by a DartCorrected at seq=5. game-A
      //     itself has no 180.
      //   - game-B: a clean 180 turn (3×T20), NO corrections. game-B's
      //     events occupy local_sequence 1..5 — exactly the range the
      //     pre-fix global cutoff would drop (`seq >= 5`).
      //
      // Pre-fix (global cutoff): the replay re-init dropped game-B's
      // seq 1-4, so game-B's 180 was silently lost from the snapshot.
      // Post-fix (per-game cutoff): game-B has no entry in the cutoff map
      // and therefore replays in full → its 180 is preserved.
      GameEvent dartFor(String gameId, int seq, int segment, int multiplier,
          {String eventId = ''}) =>
          rawEvent(
            gameId: gameId,
            seq: seq,
            type: 'DartThrown',
            payload: {
              'player_id': playerId,
              'segment': segment,
              'multiplier': multiplier,
              'score': segment * multiplier,
            },
            eventId: eventId,
          );

      final events = <GameEvent>[
        // game-A: TurnStarted, 3×S20 (60 total, NOT a 180), TurnEnded,
        // followed by a DartCorrected at seq=5 referring to a phantom dart.
        rawEvent(
          gameId: 'game-A',
          seq: 1,
          type: 'TurnStarted',
          payload: {'player_id': playerId, 'starting_score': 501},
        ),
        dartFor('game-A', 2, 20, 1),
        dartFor('game-A', 3, 20, 1),
        dartFor('game-A', 4, 20, 1),
        rawEvent(
          gameId: 'game-A',
          seq: 5,
          type: 'DartCorrected',
          payload: {
            // The presence of any DartCorrected is what triggered the buggy
            // global filter — the referent doesn't have to exist for this
            // test to exercise the path.
            'original_event_id': 'phantom',
          },
        ),
        rawEvent(
          gameId: 'game-A',
          seq: 6,
          type: 'TurnEnded',
          payload: {'player_id': playerId},
        ),
        // game-B: TurnStarted, 3×T20 = 180, TurnEnded (no corrections).
        rawEvent(
          gameId: 'game-B',
          seq: 1,
          type: 'TurnStarted',
          payload: {'player_id': playerId, 'starting_score': 501},
        ),
        dartFor('game-B', 2, 20, 3),
        dartFor('game-B', 3, 20, 3),
        dartFor('game-B', 4, 20, 3),
        rawEvent(
          gameId: 'game-B',
          seq: 5,
          type: 'TurnEnded',
          payload: {'player_id': playerId},
        ),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: events,
        totalGames: 2,
        totalDartsThrown: 6,
      );

      // game-B's 180 must survive: under the pre-fix global cutoff its
      // seq=1..4 events were filtered (< 5), dropping the bucket entirely.
      expect(stats.oneEightyTurns, 1,
          reason:
              'game-B\'s 180 must count; per-game cutoff must not drop its '
              'seq=1..4 events just because game-A has a DartCorrected at '
              'seq=5.');
    });

    test(
        'assembler excludes corrected DartThrown event IDs from replay '
        '(regression #129 sub-task 4)', () {
      // The min-DartCorrected-seq cutoff alone does NOT exclude every
      // corrected dart: a LATER correction may reference a dart whose seq
      // is itself >= cutoff, and that dart slips through the cutoff filter.
      //
      // Layout (single game):
      //   seq=1  TurnStarted
      //   seq=2  DartThrown 'bad-1' (T20=60)
      //   seq=3  DartCorrected → original_event_id='bad-1'   (sets cutoff=3)
      //   seq=4  DartThrown 'fix-1' (T20=60)
      //   seq=5  TurnEnded
      //   seq=6  TurnStarted
      //   seq=7  DartThrown 'bad-2' (T20=60)
      //   seq=8  DartCorrected → original_event_id='bad-2'
      //   seq=9  DartThrown 'fix-2' (T20=60)
      //   seq=10 TurnEnded
      //
      // Pre-fix: cutoff=3 retains 'bad-2' at seq=7 → AVG = (60+60+60)/3*3 = 180.
      // Post-fix: 'bad-1' AND 'bad-2' are both in the skip set → only 'fix-1'
      // and 'fix-2' contribute → AVG = (60+60)/2*3 = 180. The discriminator
      // is the dart count, not the average.
      final events = <GameEvent>[
        rawEvent(
          gameId: 'g-corr',
          seq: 1,
          type: 'TurnStarted',
          payload: {'player_id': playerId, 'starting_score': 501},
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 2,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 20,
            'multiplier': 3,
            'score': 60,
          },
          eventId: 'bad-1',
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 3,
          type: 'DartCorrected',
          payload: {'original_event_id': 'bad-1'},
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 4,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 20,
            'multiplier': 3,
            'score': 60,
          },
          eventId: 'fix-1',
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 5,
          type: 'TurnEnded',
          payload: {'player_id': playerId},
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 6,
          type: 'TurnStarted',
          payload: {'player_id': playerId, 'starting_score': 441},
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 7,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 20,
            'multiplier': 3,
            'score': 60,
          },
          eventId: 'bad-2',
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 8,
          type: 'DartCorrected',
          payload: {'original_event_id': 'bad-2'},
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 9,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 20,
            'multiplier': 3,
            'score': 60,
          },
          eventId: 'fix-2',
        ),
        rawEvent(
          gameId: 'g-corr',
          seq: 10,
          type: 'TurnEnded',
          payload: {'player_id': playerId},
        ),
      ];

      // Control fixture: same TWO turns but with no corrections — only
      // 'fix-1' and 'fix-2' present. This is the canonical "post-correction"
      // state the assembler should converge to.
      final control = <GameEvent>[
        rawEvent(
          gameId: 'g-ctrl',
          seq: 1,
          type: 'TurnStarted',
          payload: {'player_id': playerId, 'starting_score': 501},
        ),
        rawEvent(
          gameId: 'g-ctrl',
          seq: 2,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 20,
            'multiplier': 3,
            'score': 60,
          },
          eventId: 'ctrl-1',
        ),
        rawEvent(
          gameId: 'g-ctrl',
          seq: 3,
          type: 'TurnEnded',
          payload: {'player_id': playerId},
        ),
        rawEvent(
          gameId: 'g-ctrl',
          seq: 4,
          type: 'TurnStarted',
          payload: {'player_id': playerId, 'starting_score': 441},
        ),
        rawEvent(
          gameId: 'g-ctrl',
          seq: 5,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 20,
            'multiplier': 3,
            'score': 60,
          },
          eventId: 'ctrl-2',
        ),
        rawEvent(
          gameId: 'g-ctrl',
          seq: 6,
          type: 'TurnEnded',
          payload: {'player_id': playerId},
        ),
      ];

      // Probe via the high-score bucket. Each kept dart is a single T20=60.
      // Control: two 60-point turns → 2 in the 60+ bucket, 0 in the 100+.
      // Pre-fix: in turn 2 (starting at the seq=6 TurnStarted), the cutoff
      // is min(DartCorrected.seq)=3. Events seq>=3 all replay → turn 2 sees
      // both 'bad-2' (seq=7) and 'fix-2' (seq=9) → turn score = 120 → ONE
      // 100+ bucket and zero 60+ buckets for that turn.
      final correctedStats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: events,
        totalGames: 1,
        totalDartsThrown: 2,
      );

      final controlStats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: control,
        totalGames: 1,
        totalDartsThrown: 2,
      );

      // Control: two clean 60+ turns, zero 100+ turns.
      expect(controlStats.sixtyPlusTurns, 2);
      expect(controlStats.oneHundredPlusTurns, 0);

      // Corrected fixture must converge to the same shape after the fix:
      // bad-2 must be excluded so turn 2's score stays 60.
      expect(correctedStats.oneHundredPlusTurns, 0,
          reason:
              'Corrected DartThrown (bad-2) must be excluded from replay. '
              'Otherwise turn 2 sees bad-2 (60) + fix-2 (60) = 120 and lands '
              'in the 100+ bucket instead of the 60+ bucket.');
      expect(correctedStats.sixtyPlusTurns, controlStats.sixtyPlusTurns,
          reason:
              '60+ bucket count must match the control after honouring '
              'corrections.');
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
