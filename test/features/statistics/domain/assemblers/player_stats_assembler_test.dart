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

    test(
        'firstNinePpr is null when the leg ended before 3 turns were thrown (#290)',
        () {
      // 6-dart win (2 full turns): 180 + 121 setup then 121 checkout. The
      // legacy projection incremented `_totalFirstNineLegs` for any leg
      // with ≥1 turn, so `points / 9` inflated PPR for sub-9-dart legs.
      // After the gate, the leg doesn't count → firstNinePpr is null.
      final events = [
        turnStarted(turnNumber: 1, startingScore: 301),
        dart(20, 3),
        dart(20, 3),
        dart(20, 3),
        turnEnded(),
        turnStarted(turnNumber: 2, startingScore: 121),
        dart(19, 3),
        dart(8, 2),
        dart(20, 2),
        turnEnded(),
        legCompleted(winnerPlayerId: playerId),
        gameCompleted(winnerPlayerId: playerId),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: events,
        totalGames: 1,
        totalDartsThrown: 6,
      );

      expect(stats.firstNinePpr, isNull,
          reason: 'leg ended at 6 darts (2 turns) — first-9 PPR undefined');
    });
  });

  group('cricket', () {
    test(
        'cross-turn undo strips superseded TurnEnded so MPR not undercounted (#321)',
        () {
      // Scenario from #321: Alice throws a clean 9-mark turn (T20+T19+T18),
      // Bob's TurnStarted fires, then a cross-turn undo cancels the boundary
      // events. The DartCorrected supersedes Alice's TurnEnded and Bob's
      // TurnStarted. After replay, Alice's events are a single 9-mark
      // turn ended only by the (uncorrected) game completion.
      //
      // Pre-fix: assembler kept the superseded TurnEnded → 2 turns counted
      // for Alice (9 marks across 2 turns → MPR 4.5).
      // Post-fix: assembler honours superseded_event_ids → 1 turn → MPR 9.
      final alice1 = turnStarted();
      final aliceDart1 = dart(20, 3);
      final aliceDart2 = dart(19, 3);
      final aliceDart3 = dart(18, 3);
      final aliceEnd = turnEnded();
      final bobStart = event('TurnStarted', {
        'player_id': 'p2', // different player
        'turn_number': 1,
      });
      final correction = event('DartCorrected', {
        'original_event_id': 'phantom-dart-id',
        'superseded_event_ids': [aliceEnd.eventId, bobStart.eventId],
      });
      // After undo Alice would re-throw — for the projection we just need
      // the (replayed) turn-end. Use a fresh TurnEnded here as the closing
      // event of the re-thrown turn (which post-fix is now the ONLY
      // TurnEnded the projection sees).
      final aliceEndAgain = turnEnded();
      final completed = legCompleted(winnerPlayerId: playerId);

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.cricket,
        events: [
          alice1,
          aliceDart1,
          aliceDart2,
          aliceDart3,
          aliceEnd,
          bobStart,
          correction,
          aliceEndAgain,
          completed,
        ],
        totalGames: 1,
        totalDartsThrown: 3,
      );

      expect(stats.marksPerTurn, 9.0,
          reason:
              'one full 9-mark turn — superseded TurnEnded must not inflate denominator');
    });

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

    test(
        'playerStatsForGameFromEvents branches on cricket — cricket fields '
        'populated, X01-shaped fields stay default (refs #129 sub-task 5)',
        () {
      // One full cricket leg/game for a single competitor.
      // Turn 1: T20 (3 marks), T19 (3 marks), T18 (3 marks) = 9-mark turn.
      // Turn 2: 25 single (1 mark on Bull), miss, miss = 1-mark turn.
      // Then the leg/game completes.
      final events = [
        turnStarted(turnNumber: 1),
        dart(20, 3),
        dart(19, 3),
        dart(18, 3),
        turnEnded(),
        turnStarted(turnNumber: 2),
        dart(25, 1),
        dart(1, 1),
        dart(1, 1),
        turnEnded(),
        legCompleted(winnerPlayerId: playerId),
        gameCompleted(winnerPlayerId: playerId),
      ];

      final stats = assembler.playerStatsForGameFromEvents(
        playerId: playerId,
        gameType: GameType.cricket,
        playerDartsInGame: 6,
        playerScoreInGame: 9 * 20 + 9 * 19 + 9 * 18 + 25 + 1 + 1,
        events: events,
      );

      // Cricket-shaped fields are populated.
      expect(stats.gameType, GameType.cricket);
      expect(stats.marksPerTurn, closeTo(5.0, 1e-9)); // (9 + 1) / 2
      // 4 of 6 darts landed on a cricket target (15–20 / 25).
      expect(stats.hitRate, closeTo(4 / 6, 1e-9));
      expect(stats.nineMarkTurns, 1); // turn 1 was exactly 9 marks
      expect(stats.sixMarkTurns, 0); // per-game uses exact-N counts
      expect(stats.legsPlayed, 1);
      expect(stats.legsWon, 1);

      // Best-of fields: on a single-leg game both equal the leg/game's own
      // values. Surfaced for parity with the career bundle so multi-leg
      // games can show "best leg MPT this game" without per-game callers
      // having to recompute.
      expect(stats.bestLegMpt, closeTo(5.0, 1e-9));
      expect(stats.bestGameHitRate, closeTo(4 / 6, 1e-9));

      // X01-shaped fields must NOT be populated for a cricket per-game slice.
      // (`checkoutPercentage` and `highestCheckout` are nullable; PPR-shaped
      // fields default to 0/null.)
      expect(stats.checkoutPercentage, isNull);
      expect(stats.highestCheckout, isNull);
      expect(stats.highestTurnScore, 0);
      expect(stats.bustRate, 0.0);
      expect(stats.firstNinePpr, isNull);
      expect(stats.doubleOutSuccessRate, isNull);
      expect(stats.firstDartInSuccessRate, isNull);
      expect(stats.oneEightyTurns, 0);
      expect(stats.oneFortyPlusTurns, 0);
      expect(stats.oneHundredPlusTurns, 0);
      expect(stats.sixtyPlusTurns, 0);
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

    test('reverse variant: descend 20→1 to complete (career path)', () {
      // Walk targets 20 → 1 ascending order in the EVENT stream but the
      // expected progression descends. Each dart hits its descending target.
      final events = <GameEvent>[];
      for (int target = 20; target >= 1; target--) {
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
        atcVariant: 'reverse',
      );

      expect(stats.atcCompletions, 1);
      expect(stats.atcHitRate, 1.0);
      expect(stats.atcBestTurns, 20);
    });

    test('reverse variant: ascending throw is NOT a hit (career path)', () {
      // First throw should be at target 20 but player hits 1 instead.
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
        atcVariant: 'reverse',
      );

      expect(stats.atcHitRate, 0.0);
      expect(stats.atcCompletions, 0);
    });

    test(
        'ignores events from other players (regression for #191)',
        () {
      // ATC is solo-only today, but the loop must still gate per-player so
      // a future multi-competitor variant or shared-event load path
      // doesn't count other competitors' turns. Mirrors _computeBobs27Stats.
      //
      // Setup: p1 (our player) throws one hit at target 1.
      // Interleaved: p2 (other player) throws three hits at targets 2-4
      // and runs three full turns. Pre-fix, p2's events flipped
      // `inPlayerTurn = true`, incremented `gameTurns`, advanced
      // `currentTarget` past 1, and counted p2's hits as our own.
      const otherPlayer = 'p2';
      final events = <GameEvent>[
        // p1's turn
        event('TurnStarted',
            {'player_id': playerId, 'turn_number': 1}),
        event('DartThrown', {
          'player_id': playerId,
          'segment': 1,
          'multiplier': 1,
          'score': 1,
        }),
        event('TurnEnded', {'player_id': playerId}),
        // p2's three turns hitting 2, 3, 4 (would advance currentTarget if
        // the filter is absent)
        event('TurnStarted',
            {'player_id': otherPlayer, 'turn_number': 1}),
        event('DartThrown', {
          'player_id': otherPlayer,
          'segment': 2,
          'multiplier': 1,
          'score': 2,
        }),
        event('TurnEnded', {'player_id': otherPlayer}),
        event('TurnStarted',
            {'player_id': otherPlayer, 'turn_number': 2}),
        event('DartThrown', {
          'player_id': otherPlayer,
          'segment': 3,
          'multiplier': 1,
          'score': 3,
        }),
        event('TurnEnded', {'player_id': otherPlayer}),
        event('TurnStarted',
            {'player_id': otherPlayer, 'turn_number': 3}),
        event('DartThrown', {
          'player_id': otherPlayer,
          'segment': 4,
          'multiplier': 1,
          'score': 4,
        }),
        event('TurnEnded', {'player_id': otherPlayer}),
        gameCompleted(),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.aroundTheClock,
        events: events,
        totalGames: 1,
        totalDartsThrown: 1, // only p1 darts count for the caller
      );

      // Only p1's single hit at target 1 should register.
      expect(stats.atcHitRate, 1.0,
          reason: '1 dart at target 1 (hit) — p2 events must be ignored');
      expect(stats.atcSegmentHits, {1: 1},
          reason: 'only target 1 should appear in p1\'s hit map');
      expect(stats.atcSegmentAttempts, {1: 1},
          reason: 'p2\'s attempts at targets 2-4 must not leak in');
    });

    test(
        'computes the non-winner side of a multi-player drill (#279)',
        () {
      // Multi-player ATC: p1 (queried) hits target 1 in turn 1 and finishes
      // (assume only 1 dart needed for this contrived test). p2 (Bob in #279)
      // hits targets 1, 2, 3 across three of his own turns. Each ATC
      // competitor progresses through 1→20 independently, so when the
      // assembler is asked for p2's stats it must drive p2's currentTarget
      // from p2's own events only — even though p1's events are interleaved
      // in the same game stream.
      const otherPlayer = 'p2';
      final events = <GameEvent>[
        event('TurnStarted',
            {'player_id': playerId, 'turn_number': 1}),
        event('DartThrown', {
          'player_id': playerId,
          'segment': 1,
          'multiplier': 1,
          'score': 1,
        }),
        event('TurnEnded', {'player_id': playerId}),
        event('TurnStarted',
            {'player_id': otherPlayer, 'turn_number': 1}),
        event('DartThrown', {
          'player_id': otherPlayer,
          'segment': 1,
          'multiplier': 1,
          'score': 1,
        }),
        event('TurnEnded', {'player_id': otherPlayer}),
        event('TurnStarted',
            {'player_id': otherPlayer, 'turn_number': 2}),
        event('DartThrown', {
          'player_id': otherPlayer,
          'segment': 2,
          'multiplier': 1,
          'score': 2,
        }),
        event('TurnEnded', {'player_id': otherPlayer}),
        event('TurnStarted',
            {'player_id': otherPlayer, 'turn_number': 3}),
        event('DartThrown', {
          'player_id': otherPlayer,
          'segment': 3,
          'multiplier': 1,
          'score': 3,
        }),
        event('TurnEnded', {'player_id': otherPlayer}),
        gameCompleted(),
      ];

      final stats = assembler.fromEvents(
        playerId: otherPlayer,
        gameType: GameType.aroundTheClock,
        events: events,
        totalGames: 1,
        totalDartsThrown: 3,
      );

      expect(stats.atcSegmentHits, {1: 1, 2: 1, 3: 1},
          reason: "non-winner's hits at 1/2/3 must populate the heatmap");
      expect(stats.atcHitRate, 1.0,
          reason: 'non-winner threw 3 darts, all hits — hit rate 1.0');
      expect(stats.atcCompletions, 0,
          reason: "non-winner didn't reach 20 — no completion");
    });
  });

  group("practice — Bob's 27", () {
    test(
        'one drill with one D1 hit then GameCompleted updates score and rates',
        () {
      // Round 1: hit D1 once (mult=2 on segment 1), miss twice with singles.
      //   doubleAttempts = 3 (every dart at the target counts — #261)
      //   doubleHits     = 1 (D1 = double of round 1)
      //   doubleHitRate  = 1/3 ≈ 0.333
      //   currentScore   = 27 + 1 * 1 * 2 = 29
      // GameCompleted: drill counted as a completed, successful drill. The
      // engine emits GameCompleted directly (no LegCompleted) for Bob's 27.
      final events = [
        turnStarted(turnNumber: 1),
        dart(1, 2),
        dart(20, 1),
        dart(20, 1),
        turnEnded(),
        gameCompleted(winnerPlayerId: playerId),
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
      expect(stats.bobs27DoubleHitRate, closeTo(1 / 3, 0.001));
    });

    test('busted drill is reflected in Best / Avg / Completion Rate (#292)',
        () {
      // All-miss rounds: penalty per round = round * 2. Score progression:
      //   r1: 27 - 2  = 25
      //   r2: 25 - 4  = 21
      //   r3: 21 - 6  = 15
      //   r4: 15 - 8  = 7
      //   r5: 7  - 10 = -3  ← engine emits GameCompleted here (bust).
      final events = <GameEvent>[];
      for (int r = 1; r <= 5; r++) {
        events.addAll([
          turnStarted(turnNumber: r),
          dart(20, 1),
          dart(20, 1),
          dart(20, 1),
          turnEnded(),
        ]);
      }
      events.add(gameCompleted());

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.bobs27,
        events: events,
        totalGames: 1,
        totalDartsThrown: 15,
      );

      // Final busted score is -3; the projection now folds it into
      // Best/Avg instead of returning null.
      expect(stats.bobs27AvgScore, -3.0,
          reason: 'busted final score is the lone data point');
      expect(stats.bobs27BestScore, -3,
          reason: 'best across drills is the only drill — busted but real');
      expect(stats.bobs27CompletionRate, 0.0,
          reason: 'no drill ended above zero, so completion rate is 0%');
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

    test(
        'TurnStarted-consuming projections survive when DartCorrected exists '
        '(regression #164)', () {
      // X01CheckoutProjection counts a "checkout attempt" on every TurnStarted
      // event whose starting_score <= 170. Pre-fix, PlayerStatsAssembler ran
      // a second `replayFrom(filteredEvents, fromSequencePerGame)` pass after
      // the initial `run` — that second pass re-initialised every engine and
      // applied only events with localSequence >= DartCorrected.localSequence,
      // silently dropping the seq=1 TurnStarted and resetting the checkout
      // counter to zero.
      //
      // Layout (single game):
      //   seq=1  TurnStarted        starting_score=170
      //   seq=2  DartThrown T20
      //   seq=3  DartThrown T20
      //   seq=4  DartThrown DB      (170 → 0)
      //   seq=5  LegCompleted       winner_player_id=p1
      //   seq=6  GameCompleted
      //   seq=7  DartCorrected → original_event_id='phantom'
      //
      // The DartCorrected references no real event in this fixture — its
      // sole job is to populate fromSequencePerGame and trigger the buggy
      // replayFrom path.
      final events = <GameEvent>[
        rawEvent(
          gameId: 'g-co',
          seq: 1,
          type: 'TurnStarted',
          payload: {'player_id': playerId, 'starting_score': 170},
        ),
        rawEvent(
          gameId: 'g-co',
          seq: 2,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 20,
            'multiplier': 3,
            'score': 60,
          },
        ),
        rawEvent(
          gameId: 'g-co',
          seq: 3,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 20,
            'multiplier': 3,
            'score': 60,
          },
        ),
        rawEvent(
          gameId: 'g-co',
          seq: 4,
          type: 'DartThrown',
          payload: {
            'player_id': playerId,
            'segment': 25,
            'multiplier': 2,
            'score': 50,
          },
        ),
        rawEvent(
          gameId: 'g-co',
          seq: 5,
          type: 'LegCompleted',
          payload: {'winner_player_id': playerId},
        ),
        rawEvent(
          gameId: 'g-co',
          seq: 6,
          type: 'GameCompleted',
          payload: {'winner_player_id': playerId},
        ),
        rawEvent(
          gameId: 'g-co',
          seq: 7,
          type: 'DartCorrected',
          payload: {'original_event_id': 'phantom'},
        ),
      ];

      final stats = assembler.fromEvents(
        playerId: playerId,
        gameType: GameType.x01,
        events: events,
        totalGames: 1,
        totalDartsThrown: 3,
      );

      // 1 turn at <=170 → 1 attempt, leg won → 1 success → 100% checkout.
      expect(stats.checkoutPercentage, 100.0,
          reason:
              'TurnStarted at seq=1 must reach X01CheckoutProjection even '
              'when a DartCorrected event exists later in the log. Pre-fix, '
              'the second replay pass dropped seq < DartCorrected.seq and '
              'this assertion failed with checkoutPercentage = null/0.');
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

    test(
        'strips corrected DartThrown events (regression for #187)',
        () {
      // gameStatsFromEvents previously consumed raw events. If a player
      // threw a dart, undone it, and re-threw, the corrected original AND
      // its replacement both fed projections — inflating mark buckets,
      // averages, etc.
      //
      // Setup: turn 1 — c1 throws T20 (60), undoes it (DartCorrected
      // references the original's eventId), then re-throws T20 (60).
      // Replay-aware code must count only ONE T20 in the bucket.
      //
      // The helper `event()` assigns sequential localSequence + eventId
      // 'e<seq>'. Predict the original's eventId from its position.
      final events = [
        turnStarted(turnNumber: 1, startingScore: 100), // e1
        dart(20, 3),                                    // e2 (the corrected dart)
        event('DartCorrected', {'original_event_id': 'e2'}), // e3
        dart(20, 3),                                    // e4 (replacement)
        turnEnded(),                                    // e5
      ];

      final stats = assembler.gameStatsFromEvents(
        gameId: gameId,
        gameType: GameType.x01,
        throws: [
          // One throw — caller is responsible for excluding corrected darts
          // from `throws` (UndoLastDartUseCase deletes the dart_throws row).
          (competitorId: 'c1', playerId: playerId, score: 60),
        ],
        competitorNames: const {'c1': 'Alice'},
        events: events,
      );

      final c = stats.byCompetitor.single;
      // Without the strip, the projection sees BOTH T20s in the same turn
      // (60 + 60 = 120) and lands one turn in the 100+ bucket. With the
      // strip, only the replacement contributes (60) and lands in 60+.
      expect(c.sixtyPlusTurns, 1,
          reason: 'corrected dart must not be double-counted');
      expect(c.oneHundredPlusTurns, 0,
          reason: '60+60 from double-count would inflate to 100+ bucket');
    });
  });
}
