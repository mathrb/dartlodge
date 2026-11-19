// A practice drill closed with no terminating event (abandoned before the
// lazy-abandon path wrote GameCompleted, #280) must not carry its progress
// into the next drill: the game boundary resets the drill.

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const assembler = PlayerStatsAssembler();
  const playerId = 'p1';
  final fixedTime = DateTime.utc(2026, 1, 1);

  final seqByGame = <String, int>{};
  GameEvent event(String gameId, String type, Map<String, dynamic> payload) {
    final seq = (seqByGame[gameId] ?? 0) + 1;
    seqByGame[gameId] = seq;
    return GameEvent(
      eventId: '$gameId-e$seq',
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

  setUp(seqByGame.clear);

  List<GameEvent> turn(String gameId, List<(int, int)> darts) => [
        event(gameId, 'TurnStarted', {'player_id': playerId}),
        for (final (seg, mult) in darts)
          event(gameId, 'DartThrown', {
            'player_id': playerId,
            'segment': seg,
            'multiplier': mult,
            'score': seg * mult,
          }),
        event(gameId, 'TurnEnded', {'player_id': playerId}),
      ];

  GameEvent gameCompleted(String gameId) =>
      event(gameId, 'GameCompleted', {'winner_competitor_id': null});

  test('Around the Clock: the next drill starts again from target 1', () {
    final events = [
      // Abandoned drill: 1, 2, 3 hit (target now 4), no GameCompleted.
      ...turn('g-a', [(1, 1), (2, 1), (3, 1)]),
      // Next drill: 1, 2, 3 again, all hits.
      ...turn('g-b', [(1, 1), (2, 1), (3, 1)]),
      gameCompleted('g-b'),
    ];

    final stats = assembler.fromEvents(
      playerId: playerId,
      gameType: GameType.aroundTheClock,
      events: events,
      totalGames: 2,
      totalDartsThrown: 6,
    );

    expect(stats.atcHitRate, 1.0);
    expect(stats.atcSegmentHits, {1: 2, 2: 2, 3: 2});
  });

  test("Bob's 27: the next drill starts again from round 1 at 27", () {
    final events = [
      // Abandoned drill: rounds 1 and 2 missed (27 -> 25 -> 21), no
      // GameCompleted.
      ...turn('g-a', [(20, 1), (20, 1), (20, 1)]),
      ...turn('g-a', [(20, 1), (20, 1), (20, 1)]),
      // Next drill: one D1 in round 1 -> 29.
      ...turn('g-b', [(1, 2), (20, 1), (20, 1)]),
      gameCompleted('g-b'),
    ];

    final stats = assembler.fromEvents(
      playerId: playerId,
      gameType: GameType.bobs27,
      events: events,
      totalGames: 2,
      totalDartsThrown: 9,
    );

    expect(stats.bobs27BestScore, 29);
    expect(stats.bobs27AvgScore, 29.0);
  });
}
