// Behaviour-preservation tests for `PlayerStatsAssembler.legHistoryFromEvents`.
//
// These golden-style tests pin down the per-leg snapshot values that the old
// in-loader implementation produced (issue #137 §sub-task 3). The assembler
// must keep these values stable across the loader/computation split.

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const assembler = PlayerStatsAssembler();
  const playerId = 'p1';
  const gameId = 'g1';
  final gameDate = DateTime.utc(2026, 1, 1);

  int seq = 0;
  GameEvent event(
    String type,
    Map<String, dynamic> payload, {
    String pid = playerId,
  }) {
    seq++;
    return GameEvent(
      eventId: 'e$seq',
      gameId: gameId,
      eventType: type,
      localSequence: seq,
      occurredAt: gameDate,
      payload: payload,
      synced: false,
      actorId: pid,
      source: EventSource.client,
    );
  }

  setUp(() {
    seq = 0;
  });

  GameEvent dart(
    int segment,
    int multiplier, {
    String pid = playerId,
  }) =>
      event('DartThrown', {
        'player_id': pid,
        'segment': segment,
        'multiplier': multiplier,
        'score': segment * multiplier,
      }, pid: pid);

  GameEvent turnStarted({
    int turnNumber = 1,
    int? startingScore,
    String pid = playerId,
  }) {
    final payload = <String, dynamic>{
      'player_id': pid,
      'turn_number': turnNumber,
    };
    if (startingScore != null) payload['starting_score'] = startingScore;
    return event('TurnStarted', payload, pid: pid);
  }

  GameEvent turnEnded({String? reason, String pid = playerId}) {
    final payload = <String, dynamic>{'player_id': pid};
    if (reason != null) payload['reason'] = reason;
    return event('TurnEnded', payload, pid: pid);
  }

  GameEvent legCompleted({String? winnerPlayerId}) {
    final payload = <String, dynamic>{};
    if (winnerPlayerId != null) payload['winner_player_id'] = winnerPlayerId;
    return event('LegCompleted', payload);
  }

  group('legHistoryFromEvents — X01 PPR / checkout score', () {
    test('one clean leg → PPR = (score / darts) * 3', () {
      final events = [
        turnStarted(startingScore: 501),
        dart(20, 3), // 60
        dart(20, 3), // 60
        dart(20, 3), // 60 → 180 total
        turnEnded(),
        legCompleted(winnerPlayerId: 'someone-else'),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.x01,
        startingScore: 501,
        events: events,
      );

      expect(snaps, hasLength(1));
      expect(snaps[0].gameId, gameId);
      expect(snaps[0].legIndex, 1);
      expect(snaps[0].startingScore, 501);
      expect(snaps[0].ppr, 180.0);
      // No double-out attempt → checkout % is null (no attempts).
      expect(snaps[0].checkoutPct, isNull);
      // Player did not win → checkoutScore null.
      expect(snaps[0].checkoutScore, isNull);
      // X01 is not a practice game → practiceScore null.
      expect(snaps[0].practiceScore, isNull);
    });

    test('player wins on a double-out → checkoutScore = last starting score',
        () {
      // Player is on 40, hits D20 (a checkout attempt + success).
      final events = [
        turnStarted(startingScore: 40),
        dart(20, 2), // D20 = 40 → checkout
        turnEnded(reason: 'checkout'),
        legCompleted(winnerPlayerId: playerId),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.x01,
        startingScore: 501,
        events: events,
      );

      expect(snaps, hasLength(1));
      // Single double-out attempt that succeeded → 100%.
      expect(snaps[0].checkoutPct, 100.0);
      expect(snaps[0].checkoutScore, 40);
    });

    test('legIndex increments across multi-leg games', () {
      final events = [
        turnStarted(startingScore: 501),
        dart(20, 1),
        turnEnded(),
        legCompleted(),
        turnStarted(startingScore: 501),
        dart(19, 1),
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.x01,
        startingScore: 501,
        events: events,
      );

      expect(snaps.map((s) => s.legIndex), [1, 2]);
    });

    test('startingLegIndex offsets the indices for cross-game concatenation',
        () {
      final events = [
        turnStarted(startingScore: 501),
        dart(20, 1),
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.x01,
        startingScore: 501,
        events: events,
        startingLegIndex: 7,
      );

      expect(snaps.single.legIndex, 8);
    });
  });

  group('legHistoryFromEvents — cricket MPT', () {
    test('numeric-payload cricket darts produce per-leg MPT', () {
      // 2 turns: turn 1 = T20 + T20 + S20 (3+3+1=7 marks);
      //          turn 2 = D19 + S19 + miss (2+1+0=3 marks). Total 10 marks / 2 turns = 5.0
      final events = [
        turnStarted(),
        dart(20, 3), // 3 marks
        dart(20, 3), // 3 marks
        dart(20, 1), // 1 mark
        turnEnded(),
        turnStarted(),
        dart(19, 2), // 2 marks
        dart(19, 1), // 1 mark
        dart(5, 1), // 0 marks (not a cricket target)
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.cricket,
        startingScore: null,
        events: events,
      );

      expect(snaps, hasLength(1));
      expect(snaps[0].mpt, 5.0); // 10 marks / 2 turns
    });

    test('canonical-string segment payloads also count cricket marks', () {
      // Mimic engines that emit segment as a canonical string.
      GameEvent stringDart(String segStr, int mult) {
        seq++;
        return GameEvent(
          eventId: 'e$seq',
          gameId: gameId,
          eventType: 'DartThrown',
          localSequence: seq,
          occurredAt: gameDate,
          payload: {
            'player_id': playerId,
            'segment': segStr, // string variant
            'multiplier': mult,
            'score': 0,
          },
          synced: false,
          actorId: playerId,
          source: EventSource.client,
        );
      }

      final events = [
        turnStarted(),
        stringDart('T20', 3), // 3 marks
        stringDart('D19', 2), // 2 marks
        stringDart('SB', 1), // 1 mark
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.cricket,
        startingScore: null,
        events: events,
      );

      expect(snaps.single.mpt, 6.0); // 6 marks / 1 turn
    });

    test('zero turns → mpt is null', () {
      final events = [legCompleted()];
      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.cricket,
        startingScore: null,
        events: events,
      );
      expect(snaps.single.mpt, isNull);
      expect(snaps.single.ppr, 0.0);
    });

    test('dead-number marks are suppressed (#638)', () {
      // The inline legHistoryFromEvents tracker mirrors the projection: a hit on
      // a number closed by ALL competitors counts 0 marks. p1 (c1) closes 20,
      // p2 (c2) closes 20 → 20 dead; p1's wasted T20 then counts 0.
      // p1 turns: turn 1 = 3 marks, turn 3 = 0 → 3 marks / 2 turns = 1.5.
      GameEvent cdart(int seg, int mult, {required String cid, required String pid}) =>
          event('DartThrown', {
            'player_id': pid,
            'competitor_id': cid,
            'segment': seg,
            'multiplier': mult,
            'score': seg * mult,
          }, pid: pid);

      final events = [
        event('GameCreated', {
          'competitors': ['c1', 'c2'],
        }),
        // p1 closes 20 (live → 3 marks).
        turnStarted(),
        cdart(20, 3, cid: 'c1', pid: 'p1'),
        turnEnded(),
        // p2 closes 20 → 20 now dead for all.
        turnStarted(pid: 'p2'),
        cdart(20, 3, cid: 'c2', pid: 'p2'),
        turnEnded(pid: 'p2'),
        // p1 wastes a T20 on the dead number → 0 marks.
        turnStarted(),
        cdart(20, 3, cid: 'c1', pid: 'p1'),
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.cricket,
        startingScore: null,
        events: events,
      );

      expect(snaps.single.mpt, closeTo(1.5, 0.001),
          reason: 'wasted dart on a dead number counts 0 marks');
    });
  });

  group('legHistoryFromEvents — ATC hit-rate practice score', () {
    test('progressing through targets increments hits monotonically', () {
      // Standard ATC: hit current target → currentTarget++. Player gets 3
      // darts at target 1 — hits on the 2nd.
      final events = [
        turnStarted(),
        dart(5, 1), // miss target 1
        dart(1, 1), // hit target 1 → currentTarget = 2
        dart(2, 1), // hit target 2 → currentTarget = 3
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.aroundTheClock,
        startingScore: null,
        events: events,
      );

      expect(snaps, hasLength(1));
      // 3 darts at targets, 2 hits → hit rate 2/3.
      expect(snaps[0].practiceScore, closeTo(2 / 3, 1e-9));
    });

    test('no darts at a target → practiceScore null', () {
      final events = [legCompleted()];
      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.aroundTheClock,
        startingScore: null,
        events: events,
      );
      expect(snaps.single.practiceScore, isNull);
    });

    test('reverse variant: descending target progression 20 → 19 → 18', () {
      // Reverse ATC starts at target 20 and decrements. Three darts: miss
      // target 20 with S5, hit S20 → target 19, hit S19 → target 18.
      final events = [
        turnStarted(),
        dart(5, 1), // miss target 20
        dart(20, 1), // hit target 20 → currentTarget = 19
        dart(19, 1), // hit target 19 → currentTarget = 18
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.aroundTheClock,
        startingScore: null,
        events: events,
        atcVariant: 'reverse',
      );

      expect(snaps, hasLength(1));
      // 3 darts at targets, 2 hits → hit rate 2/3.
      expect(snaps[0].practiceScore, closeTo(2 / 3, 1e-9));
    });

    test('reverse variant: a standard ascending hit no longer counts', () {
      // In reverse mode the first target is 20, not 1. A pure S1 dart that
      // would have counted as a hit under 'standard' must register as a miss.
      final events = [
        turnStarted(),
        dart(1, 1), // miss target 20 (was hit under standard)
        dart(1, 1), // miss target 20
        dart(1, 1), // miss target 20
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.aroundTheClock,
        startingScore: null,
        events: events,
        atcVariant: 'reverse',
      );

      // 3 darts at target, 0 hits → 0.0 (not 1.0 as the standard branch
      // would have computed).
      expect(snaps.single.practiceScore, 0.0);
    });

    test('doublesOnly variant: only multiplier==2 hits advance the target',
        () {
      // doublesOnly still ascends 1 → 20, but a hit requires D<N>. A single
      // S1 must register as a miss; D1 must count as a hit and advance.
      final events = [
        turnStarted(),
        dart(1, 1), // S1 → miss (singles don't count in doublesOnly)
        dart(1, 2), // D1 → hit → currentTarget = 2
        dart(2, 2), // D2 → hit → currentTarget = 3
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.aroundTheClock,
        startingScore: null,
        events: events,
        atcVariant: 'doublesOnly',
      );

      expect(snaps, hasLength(1));
      // 3 darts at targets, 2 hits → 2/3.
      expect(snaps[0].practiceScore, closeTo(2 / 3, 1e-9));
    });

    test('doublesOnly variant: triples are NOT hits (multiplier strictly 2)',
        () {
      final events = [
        turnStarted(),
        dart(1, 3), // T1 — multiplier 3, not a hit in doublesOnly
        dart(1, 3), // T1 — still a miss
        dart(1, 3), // T1 — still a miss
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.aroundTheClock,
        startingScore: null,
        events: events,
        atcVariant: 'doublesOnly',
      );

      // 3 darts at target 1, 0 hits.
      expect(snaps.single.practiceScore, 0.0);
    });
  });

  group('legHistoryFromEvents — non-ATC practice score semantics', () {
    test('Shanghai practice: practiceScore = legScoreTotal', () {
      final events = [
        turnStarted(),
        dart(1, 1), // 1
        dart(1, 2), // 2
        dart(1, 3), // 3 → total 6
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.shanghai,
        startingScore: null,
        events: events,
      );
      expect(snaps.single.practiceScore, 6.0);
    });

    test(
        "Bob's 27: practiceScore uses bonus/penalty mechanics, not raw sum "
        '(regression for #190)', () {
      // Round 1 (target = 1): player throws D1 → 1 double hit on target.
      // Round 2 (target = 2): no doubles on 2.
      //
      // Canonical Bob's 27 score:
      //   Start: 27
      //   Round 1: +1 * 1 * 2 = +2  → 29
      //   Round 2: -2 * 2 = -4      → 25
      //
      // Pre-fix: practiceScore = sum of DartThrown.score across the leg.
      //   = (1*2)  +  0  +  0   from round 1 (D1=2)
      //   + (1*1)  + (5*1) + (8*1) from round 2 (random misses 1,5,8 = 14)
      //   = 16   (wrong — would plot a wildly different trend line)
      //
      // Post-fix: practiceScore = 25.0 (matches _computeBobs27Stats).
      final events = [
        turnStarted(turnNumber: 1),
        dart(1, 2),  // D1 — hits round 1's target
        dart(20, 1), // miss target 1
        dart(20, 1),
        turnEnded(),
        turnStarted(turnNumber: 2),
        dart(1, 1),  // S1 — wrong round; not target 2
        dart(5, 1),
        dart(8, 1),
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.bobs27,
        startingScore: null,
        events: events,
      );
      expect(snaps.single.practiceScore, 25.0,
          reason:
              "Bob's 27 score must use the canonical bonus/penalty replay, "
              'not a raw sum of dart scores');
    });

    test(
        'Checkout Practice: practiceScore is null (no per-leg score concept)',
        () {
      // Checkout practice has no canonical per-leg score — only attempts /
      // successes. Pre-fix legHistoryFromEvents emitted a meaningless raw
      // dart sum here; post-fix should be null.
      final events = [
        turnStarted(),
        dart(20, 3), // T20 = 60
        dart(20, 3), // T20 = 60
        dart(25, 2), // DB = 50
        turnEnded(reason: 'checkout'),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.checkoutPractice,
        startingScore: null,
        events: events,
      );
      expect(snaps.single.practiceScore, isNull,
          reason: 'Checkout Practice has no per-leg score');
    });
  });

  group('legHistoryFromEvents — player isolation', () {
    test('darts/turns from another player do NOT contribute', () {
      const otherPlayer = 'p2';
      final events = [
        turnStarted(pid: otherPlayer),
        dart(20, 3, pid: otherPlayer), // ignored
        turnEnded(pid: otherPlayer),
        turnStarted(startingScore: 501),
        dart(20, 1), // 20
        turnEnded(),
        legCompleted(),
      ];

      final snaps = assembler.legHistoryFromEvents(
        playerId: playerId,
        gameId: gameId,
        gameDate: gameDate,
        gameType: GameType.x01,
        startingScore: 501,
        events: events,
      );

      // PPR = 20 / 1 dart * 3 = 60. The other player's 180 must be ignored.
      expect(snaps.single.ppr, 60.0);
    });
  });
}
