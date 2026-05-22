import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/history/domain/turn_breakdown.dart';

Competitor _solo(String id, String name, String playerId) => Competitor(
      competitorId: id,
      gameId: 'g',
      type: CompetitorType.solo,
      name: name,
      players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
    );

int _seq = 0;
GameEvent _event(String type, Map<String, dynamic> payload) {
  _seq++;
  return GameEvent(
    eventId: 'evt-$_seq',
    gameId: 'g',
    eventType: type,
    localSequence: _seq,
    occurredAt: DateTime(2024),
    payload: payload,
    synced: false,
    actorId: 'system',
    source: EventSource.client,
  );
}

List<GameEvent> _x01Turn({
  required String competitorId,
  required String playerId,
  required int turnIndex,
  required int legIndex,
  required int startingScore,
  required List<({int segment, int multiplier})> darts,
  String reason = 'normal',
}) {
  return [
    _event('TurnStarted', {
      'competitor_id': competitorId,
      'player_id': playerId,
      'turn_index': turnIndex,
      'leg_index': legIndex,
      'starting_score': startingScore,
    }),
    ...darts.map((d) => _event('DartThrown', {
          'competitor_id': competitorId,
          'player_id': playerId,
          'segment': d.segment,
          'multiplier': d.multiplier,
          'score': d.segment * d.multiplier,
          'input_method': 'manual',
        })),
    _event('TurnEnded', {
      'competitor_id': competitorId,
      'player_id': playerId,
      'reason': reason,
    }),
  ];
}

GameEvent _legCompleted(String winnerId) => _event('LegCompleted', {
      'winner_competitor_id': winnerId,
    });

GameEvent _gameCompleted(String? winnerId) => _event('GameCompleted', {
      'winner_id': winnerId,
    });

void main() {
  setUp(() => _seq = 0);

  group('X01 turn breakdown', () {
    test('170 checkout in three darts: T20, T20, DB', () {
      final c1 = _solo('c1', 'Alice', 'p1');
      final game = Game(
        gameId: 'g',
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 170,
          inStrategy: 'straight',
          outStrategy: 'double',
        ),
        startTime: DateTime(2024),
      );
      final events = <GameEvent>[
        _event('GameCreated', {}),
        ..._x01Turn(
          competitorId: 'c1',
          playerId: 'p1',
          turnIndex: 1,
          legIndex: 0,
          startingScore: 170,
          darts: [
            (segment: 20, multiplier: 3),
            (segment: 20, multiplier: 3),
            (segment: 25, multiplier: 2),
          ],
        ),
        _legCompleted('c1'),
        _gameCompleted('c1'),
      ];

      final result = const TurnBreakdownBuilder().build(
        game: game,
        competitors: [c1],
        events: events,
      );

      expect(result, hasLength(1));
      final leg = result[1]!;
      expect(leg.atcSegments, isEmpty);
      expect(leg.turns, hasLength(1));
      final turn = leg.turns.first;
      expect(turn.round, 1);
      expect(turn.competitorId, 'c1');
      expect(turn.darts, ['T20', 'T20', 'DB']);
      expect(turn.turnScore, 170);
      expect(turn.startingScore, 170);
      expect(turn.remainingScore, 0);
      expect(turn.bust, isFalse);
      expect(turn.checkout, isTrue);
    });

    test('bust turn keeps starting score, marks bust=true', () {
      final c1 = _solo('c1', 'Alice', 'p1');
      final game = Game(
        gameId: 'g',
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 50,
          inStrategy: 'straight',
          outStrategy: 'double',
        ),
        startTime: DateTime(2024),
      );
      final events = <GameEvent>[
        _event('GameCreated', {}),
        ..._x01Turn(
          competitorId: 'c1',
          playerId: 'p1',
          turnIndex: 1,
          legIndex: 0,
          startingScore: 50,
          darts: [
            (segment: 20, multiplier: 3), // T20=60 → bust
          ],
          reason: 'bust',
        ),
        _legCompleted('c1'),
      ];

      final result = const TurnBreakdownBuilder().build(
        game: game,
        competitors: [c1],
        events: events,
      );

      expect(result, hasLength(1));
      final turn = result[1]!.turns.single;
      expect(turn.bust, isTrue);
      expect(turn.startingScore, 50);
      expect(turn.remainingScore, 50);
    });
  });

  group('Around-the-Clock per-segment hit rate', () {
    test('counts attempts/hits per current target', () {
      final c1 = _solo('c1', 'Alice', 'p1');
      final game = Game(
        gameId: 'g',
        gameType: GameType.aroundTheClock,
        config: const GameConfig.aroundTheClock(),
        startTime: DateTime(2024),
      );
      // Player attempts target 1: misses, then hits → target advances to 2.
      // Then attempts target 2: hits immediately.
      final events = <GameEvent>[
        _event('GameCreated', {}),
        _event('TurnStarted', {
          'competitor_id': 'c1',
          'player_id': 'p1',
          'turn_index': 1,
          'leg_index': 0,
        }),
        _event('DartThrown', {
          'competitor_id': 'c1',
          'segment': 5,
          'multiplier': 1,
          'score': 5,
        }),
        _event('DartThrown', {
          'competitor_id': 'c1',
          'segment': 1,
          'multiplier': 1,
          'score': 1,
        }),
        _event('DartThrown', {
          'competitor_id': 'c1',
          'segment': 2,
          'multiplier': 1,
          'score': 2,
        }),
        _event('TurnEnded', {
          'competitor_id': 'c1',
          'reason': 'normal',
        }),
        _legCompleted('c1'),
      ];

      final result = const TurnBreakdownBuilder().build(
        game: game,
        competitors: [c1],
        events: events,
      );

      final segments = result[1]!.atcSegments;
      expect(result[1]!.turns, isEmpty);
      // 21 segments emitted: 1..20 + Bull
      expect(segments, hasLength(21));
      final seg1 = segments.firstWhere((s) => s.segmentLabel == '1');
      // 2 attempts on target 1 (the 5 missed and the 1 hit), 1 hit
      expect(seg1.attempts, 2);
      expect(seg1.hits, 1);
      final seg2 = segments.firstWhere((s) => s.segmentLabel == '2');
      // 1 attempt on target 2 (after advance), 1 hit
      expect(seg2.attempts, 1);
      expect(seg2.hits, 1);
    });
  });

  group('Round numbering (#256)', () {
    // Regression for #256. Production providers stamp `turn_index` with the
    // *competitor index* (`newGs.currentTurnIndex`) — so a 3-player X01 game
    // would see turn_index cycle 0, 1, 2, 0, 1, 2, ... The breakdown UI
    // labelled that as ROUND, producing the wrong column. The builder must
    // derive the round by counting how many TurnStarted events the
    // competitor has had since the last LegCompleted.
    test('3-player X01: each row shows the player\'s 1-based round', () {
      final c1 = _solo('c1', 'Alice', 'p1');
      final c2 = _solo('c2', 'Bob', 'p2');
      final c3 = _solo('c3', 'Cara', 'p3');
      final game = Game(
        gameId: 'g',
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
        ),
        startTime: DateTime(2024),
      );

      // Three players, two full rounds. turn_index in real production
      // payloads matches the COMPETITOR INDEX (0, 1, 2 cycling), NOT a
      // round. The builder must ignore that and derive the round itself.
      final events = <GameEvent>[
        _event('GameCreated', {}),
        // Round 1
        ..._x01Turn(
          competitorId: 'c1', playerId: 'p1',
          turnIndex: 0, legIndex: 0, startingScore: 501,
          darts: [(segment: 20, multiplier: 1)],
        ),
        ..._x01Turn(
          competitorId: 'c2', playerId: 'p2',
          turnIndex: 1, legIndex: 0, startingScore: 501,
          darts: [(segment: 20, multiplier: 1)],
        ),
        ..._x01Turn(
          competitorId: 'c3', playerId: 'p3',
          turnIndex: 2, legIndex: 0, startingScore: 501,
          darts: [(segment: 20, multiplier: 1)],
        ),
        // Round 2 — turn_index resets to 0/1/2 like production does.
        ..._x01Turn(
          competitorId: 'c1', playerId: 'p1',
          turnIndex: 0, legIndex: 0, startingScore: 481,
          darts: [(segment: 20, multiplier: 1)],
        ),
        ..._x01Turn(
          competitorId: 'c2', playerId: 'p2',
          turnIndex: 1, legIndex: 0, startingScore: 481,
          darts: [(segment: 20, multiplier: 1)],
        ),
        ..._x01Turn(
          competitorId: 'c3', playerId: 'p3',
          turnIndex: 2, legIndex: 0, startingScore: 481,
          darts: [(segment: 20, multiplier: 1)],
        ),
        _legCompleted('c1'),
        _gameCompleted('c1'),
      ];

      final result = const TurnBreakdownBuilder().build(
        game: game,
        competitors: [c1, c2, c3],
        events: events,
      );
      final turns = result[1]!.turns;
      expect(turns.map((t) => t.competitorId).toList(),
          ['c1', 'c2', 'c3', 'c1', 'c2', 'c3']);
      expect(turns.map((t) => t.round).toList(), [1, 1, 1, 2, 2, 2]);
    });

    test('per-competitor round counter resets on LegCompleted', () {
      final c1 = _solo('c1', 'Alice', 'p1');
      final c2 = _solo('c2', 'Bob', 'p2');
      final game = Game(
        gameId: 'g',
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 50,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: 2,
        ),
        startTime: DateTime(2024),
      );

      final events = <GameEvent>[
        _event('GameCreated', {}),
        // Leg 1 — 2 rounds.
        ..._x01Turn(
          competitorId: 'c1', playerId: 'p1',
          turnIndex: 0, legIndex: 0, startingScore: 50,
          darts: [(segment: 1, multiplier: 1)],
        ),
        ..._x01Turn(
          competitorId: 'c2', playerId: 'p2',
          turnIndex: 1, legIndex: 0, startingScore: 50,
          darts: [(segment: 25, multiplier: 2)], // DB = 50 → checkout
        ),
        _legCompleted('c2'),
        // Leg 2 — Alice goes first, one round.
        ..._x01Turn(
          competitorId: 'c1', playerId: 'p1',
          turnIndex: 0, legIndex: 1, startingScore: 50,
          darts: [(segment: 25, multiplier: 2)],
        ),
        _legCompleted('c1'),
      ];

      final result = const TurnBreakdownBuilder().build(
        game: game,
        competitors: [c1, c2],
        events: events,
      );
      // Round counters reset per leg.
      expect(result[1]!.turns.map((t) => (t.competitorId, t.round)).toList(),
          [('c1', 1), ('c2', 1)]);
      expect(result[2]!.turns.map((t) => (t.competitorId, t.round)).toList(),
          [('c1', 1)]);
    });
  });

  group('Count-Up turn breakdown (#256)', () {
    test('3-player count-up: round + total per row', () {
      final c1 = _solo('c1', 'Alice', 'p1');
      final c2 = _solo('c2', 'Bob', 'p2');
      final c3 = _solo('c3', 'Cara', 'p3');
      final game = Game(
        gameId: 'g',
        gameType: GameType.countUp,
        config: const GameConfig.countUp(totalRounds: 2),
        startTime: DateTime(2024),
      );

      // turn_index cycles 0/1/2 in production — builder must derive the
      // round itself. Each row's TOTAL is the running cumulative score.
      List<GameEvent> turn({
        required String compId,
        required String pId,
        required int compIdx,
        required List<({int segment, int multiplier})> darts,
      }) {
        return [
          _event('TurnStarted', {
            'competitor_id': compId,
            'player_id': pId,
            'turn_index': compIdx,
            'leg_index': 0,
          }),
          ...darts.map((d) => _event('DartThrown', {
                'competitor_id': compId,
                'player_id': pId,
                'segment': d.segment,
                'multiplier': d.multiplier,
                'score': d.segment * d.multiplier,
                'input_method': 'manual',
              })),
          _event('TurnEnded', {
            'competitor_id': compId,
            'player_id': pId,
            'reason': 'normal',
          }),
        ];
      }

      final events = <GameEvent>[
        _event('GameCreated', {}),
        // Round 1: Alice 60, Bob 20, Cara 25.
        ...turn(compId: 'c1', pId: 'p1', compIdx: 0, darts: [
          (segment: 20, multiplier: 1),
          (segment: 20, multiplier: 1),
          (segment: 20, multiplier: 1),
        ]),
        ...turn(compId: 'c2', pId: 'p2', compIdx: 1, darts: [
          (segment: 20, multiplier: 1),
          (segment: 0, multiplier: 1),
          (segment: 0, multiplier: 1),
        ]),
        ...turn(compId: 'c3', pId: 'p3', compIdx: 2, darts: [
          (segment: 25, multiplier: 1),
          (segment: 0, multiplier: 1),
          (segment: 0, multiplier: 1),
        ]),
        // Round 2: Alice 60, Bob 25, Cara 0.
        ...turn(compId: 'c1', pId: 'p1', compIdx: 0, darts: [
          (segment: 20, multiplier: 1),
          (segment: 20, multiplier: 1),
          (segment: 20, multiplier: 1),
        ]),
        ...turn(compId: 'c2', pId: 'p2', compIdx: 1, darts: [
          (segment: 25, multiplier: 1),
          (segment: 0, multiplier: 1),
          (segment: 0, multiplier: 1),
        ]),
        ...turn(compId: 'c3', pId: 'p3', compIdx: 2, darts: [
          (segment: 0, multiplier: 1),
          (segment: 0, multiplier: 1),
          (segment: 0, multiplier: 1),
        ]),
        _legCompleted('c1'),
        _gameCompleted('c1'),
      ];

      final result = const TurnBreakdownBuilder().build(
        game: game,
        competitors: [c1, c2, c3],
        events: events,
      );
      final turns = result[1]!.turns;
      // Round numbers are 1-based per competitor.
      expect(turns.map((t) => (t.competitorId, t.round)).toList(),
          [('c1', 1), ('c2', 1), ('c3', 1), ('c1', 2), ('c2', 2), ('c3', 2)]);
      // Running totals accumulate per competitor.
      expect(turns.map((t) => (t.competitorId, t.runningTotal)).toList(), [
        ('c1', 60),
        ('c2', 20),
        ('c3', 25),
        ('c1', 120),
        ('c2', 45),
        ('c3', 25),
      ]);
    });
  });

  group('multi-leg slicing', () {
    test('emits one breakdown entry per LegCompleted', () {
      final c1 = _solo('c1', 'Alice', 'p1');
      final game = Game(
        gameId: 'g',
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 50,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: 2,
        ),
        startTime: DateTime(2024),
      );

      final events = <GameEvent>[
        _event('GameCreated', {}),
        ..._x01Turn(
          competitorId: 'c1',
          playerId: 'p1',
          turnIndex: 1,
          legIndex: 0,
          startingScore: 50,
          darts: [
            (segment: 25, multiplier: 2), // DB = 50 → checkout
          ],
        ),
        _legCompleted('c1'),
        ..._x01Turn(
          competitorId: 'c1',
          playerId: 'p1',
          turnIndex: 1,
          legIndex: 1,
          startingScore: 50,
          darts: [
            (segment: 20, multiplier: 1),
            (segment: 25, multiplier: 1),
            (segment: 5, multiplier: 1),
          ],
        ),
        _legCompleted('c1'),
      ];

      final result = const TurnBreakdownBuilder().build(
        game: game,
        competitors: [c1],
        events: events,
      );
      expect(result.keys, [1, 2]);
      expect(result[1]!.turns.single.checkout, isTrue);
      expect(result[2]!.turns.single.checkout, isFalse);
    });
  });
}
