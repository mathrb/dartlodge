import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/event_leg_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int seq = 0;
  GameEvent event(String type, {String gameId = 'g'}) {
    seq++;
    return GameEvent(
      eventId: 'e$seq',
      gameId: gameId,
      eventType: type,
      localSequence: seq,
      occurredAt: DateTime.utc(2026, 1, 1),
      payload: const {},
      synced: false,
      actorId: 'p1',
      source: EventSource.client,
    );
  }

  setUp(() {
    seq = 0;
  });

  test('null legLimit returns events unchanged', () {
    final events = [event('TurnStarted'), event('LegCompleted')];
    expect(EventLegLimiter.trim(events, null), same(events));
  });

  test('legLimit ≤ 0 returns events unchanged', () {
    final events = [event('TurnStarted'), event('LegCompleted')];
    expect(EventLegLimiter.trim(events, 0), same(events));
    expect(EventLegLimiter.trim(events, -1), same(events));
  });

  test('input with fewer LegCompleted than legLimit returns unchanged', () {
    // 2 legs in input, asking for last 5 → no trimming.
    final events = [
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'),
    ];
    expect(EventLegLimiter.trim(events, 5), same(events));
  });

  test('trims to keep last N legs and the events after them', () {
    // 4 legs total; keep last 2.
    // [TS, LC, TS, LC, TS, LC, TS, LC]
    //  0   1   2   3   4   5   6   7
    // legCompleted at indices [1, 3, 5, 7]
    // For legLimit=2: prev = indices[4-2-1] = indices[1] = 3
    // Result: events.sublist(4) → [TS@4, LC@5, TS@6, LC@7]
    final events = [
      event('TurnStarted'),
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'),
    ];

    final result = EventLegLimiter.trim(events, 2);

    expect(result.length, 4);
    expect(result.first.localSequence, 5); // first kept event = TS@4 → seq 5
    expect(result.last.localSequence, 8);
  });

  test('events after the last LegCompleted are kept (open in-progress leg)', () {
    // 2 completed legs + a started-but-uncompleted leg.
    // legLimit=1 should keep last completed leg's events + the trailing
    // events after it.
    final events = [
      event('TurnStarted'),
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'), // index 3 — the boundary cut for legLimit=1
      event('TurnStarted'), // these stay
      event('DartThrown'),
    ];

    final result = EventLegLimiter.trim(events, 1);

    // Wait — legCompletedIndices=[1,3], legLimit=1, prev=indices[2-1-1]=indices[0]=1.
    // So result = sublist(2) → events[2..5] = [TS, LC, TS, DT].
    expect(result.length, 4);
    expect(result.first.eventType, 'TurnStarted');
    expect(result[1].eventType, 'LegCompleted');
  });

  test('drops the cut game\'s trailing GameCompleted', () {
    // Game a's only leg is outside a Last 1 window, so its GameCompleted
    // must not leak into the window (win rate counts GameCompleted).
    final events = [
      event('TurnStarted', gameId: 'a'),
      event('LegCompleted', gameId: 'a'),
      event('GameCompleted', gameId: 'a'),
      event('TurnStarted', gameId: 'b'),
      event('LegCompleted', gameId: 'b'),
      event('GameCompleted', gameId: 'b'),
    ];

    final result = EventLegLimiter.trim(events, 1);

    expect(result.map((e) => e.gameId).toSet(), {'b'});
    expect(result.map((e) => e.eventType).toList(),
        ['TurnStarted', 'LegCompleted', 'GameCompleted']);
  });

  test('match types ignore GameCompleted as a leg end by default', () {
    // An abandoned game ends on GameCompleted with an open leg: not a leg.
    final events = [
      event('TurnStarted', gameId: 'a'),
      event('GameCompleted', gameId: 'a'),
      event('TurnStarted', gameId: 'b'),
      event('LegCompleted', gameId: 'b'),
      event('GameCompleted', gameId: 'b'),
    ];
    expect(EventLegLimiter.trim(events, 1), same(events));
  });

  group('closeLegOnGameCompleted (practice drills)', () {
    test('each drill ending on GameCompleted counts as one leg', () {
      final events = [
        event('TurnStarted', gameId: 'a'),
        event('DartThrown', gameId: 'a'),
        event('GameCompleted', gameId: 'a'),
        event('TurnStarted', gameId: 'b'),
        event('DartThrown', gameId: 'b'),
        event('GameCompleted', gameId: 'b'),
      ];

      final result =
          EventLegLimiter.trim(events, 1, closeLegOnGameCompleted: true);

      expect(result.map((e) => e.gameId).toSet(), {'b'});
      expect(result.length, 3);
    });

    test('a GameCompleted right after LegCompleted is not a second leg', () {
      // Game a: two legs (LegCompleted, then the final GameCompleted closes
      // the second). Game b: one leg closed by LegCompleted + GameCompleted.
      final events = [
        event('TurnStarted', gameId: 'a'),
        event('LegCompleted', gameId: 'a'),
        event('TurnStarted', gameId: 'a'),
        event('GameCompleted', gameId: 'a'),
        event('TurnStarted', gameId: 'b'),
        event('LegCompleted', gameId: 'b'),
        event('GameCompleted', gameId: 'b'),
      ];

      // 3 legs in total; Last 2 keeps a's second leg and b.
      final result =
          EventLegLimiter.trim(events, 2, closeLegOnGameCompleted: true);
      expect(result.length, 5);
      expect(result.first.localSequence, 3);
      // Last 3 keeps everything.
      expect(
          EventLegLimiter.trim(events, 3, closeLegOnGameCompleted: true),
          same(events));
    });
  });
  test('a LegCompleted superseded by an undo does not count as a leg', () {
    final voidedDart = event('DartThrown');
    final voidedLeg = event('LegCompleted');
    final voidedNextLeg = event('TurnStarted');
    final events = [
      event('TurnStarted'),
      voidedDart,
      voidedLeg,
      voidedNextLeg,
      event('DartCorrected').copyWith(payload: {
        'original_event_id': voidedDart.eventId,
        'superseded_event_ids': [voidedLeg.eventId, voidedNextLeg.eventId],
      }),
      event('DartThrown'),
      event('LegCompleted'), // real leg 1 (e7)
      event('TurnStarted'),
      event('LegCompleted'), // real leg 2 (e9)
    ];

    // Two real legs: Last 2 keeps everything.
    expect(EventLegLimiter.trim(events, 2), same(events));
    // Last 1 keeps only the second real leg.
    expect(
      EventLegLimiter.trim(events, 1).map((e) => e.eventId).toList(),
      ['e8', 'e9'],
    );
  });
}
