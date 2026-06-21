import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/usecases/compute_leg_stats_use_case.dart';

Competitor _solo(String id, String name, String playerId) => Competitor(
      competitorId: id,
      gameId: 'g',
      type: CompetitorType.solo,
      name: name,
      players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
    );

int _seq = 0;
GameEvent _event(
  String type,
  Map<String, dynamic> payload, {
  String actor = 'system',
}) {
  _seq++;
  return GameEvent(
    eventId: 'evt-$_seq',
    gameId: 'g',
    eventType: type,
    localSequence: _seq,
    occurredAt: DateTime(2024),
    payload: payload,
    synced: false,
    actorId: actor,
    source: EventSource.client,
  );
}

void _resetSeq() => _seq = 0;

/// Emits TurnStarted + 3 DartThrown + TurnEnded for [playerId]/[competitorId].
/// Each dart payload has {segment, multiplier, player_id, competitor_id, score}.
List<GameEvent> _turn({
  required String competitorId,
  required String playerId,
  required int startingScore,
  required List<({int segment, int multiplier})> darts,
  String reason = 'normal',
}) {
  return [
    _event('TurnStarted', {
      'competitor_id': competitorId,
      'player_id': playerId,
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

GameEvent _legCompleted({
  required String winnerCompetitorId,
  required String winnerPlayerId,
}) =>
    _event('LegCompleted', {
      'winner_competitor_id': winnerCompetitorId,
      'winner_player_id': winnerPlayerId,
    });

void main() {
  const useCase = ComputeLegStatsUseCase();
  final c1 = _solo('c1', 'Alice', 'p1');
  final c2 = _solo('c2', 'Bob', 'p2');

  setUp(_resetSeq);

  group('empty / unsupported inputs', () {
    test('empty events → empty list', () {
      expect(
        useCase.execute(
          events: const [],
          competitors: [c1, c2],
          gameType: GameType.x01,
        ),
        isEmpty,
      );
    });

    test('no LegCompleted in stream → empty list', () {
      final events = _turn(
        competitorId: 'c1',
        playerId: 'p1',
        startingScore: 501,
        darts: [
          (segment: 20, multiplier: 1),
          (segment: 20, multiplier: 1),
          (segment: 20, multiplier: 1),
        ],
      );
      expect(
        useCase.execute(
          events: events,
          competitors: [c1, c2],
          gameType: GameType.x01,
        ),
        isEmpty,
      );
    });

    test('non-X01/Cricket game type → minimal leg row, no rich stats', () {
      final result = useCase.execute(
        events: [_legCompleted(winnerCompetitorId: 'c1', winnerPlayerId: 'p1')],
        competitors: [c1, c2],
        gameType: GameType.shanghai,
      );
      expect(result, hasLength(1));
      expect(result.first.legNumber, 1);
      expect(result.first.winnerCompetitorId, 'c1');
      // byCompetitor is populated with entries but rich stats stay null/0
      // so callers can still render leg metadata + a turn breakdown.
      expect(result.first.byCompetitor, hasLength(2));
      expect(result.first.byCompetitor.first.threeDartAverage, isNull);
      expect(result.first.byCompetitor.first.marksPerRound, isNull);
    });
  });

  group('x01 two-leg game', () {
    test('computes per-leg stats, isolating legs', () {
      // Leg 1: p1 checks out 170 in 3 darts (T20, T20, DB).
      final leg1 = <GameEvent>[
        ..._turn(
          competitorId: 'c1',
          playerId: 'p1',
          startingScore: 170,
          darts: [
            (segment: 20, multiplier: 3), // T20 = 60
            (segment: 20, multiplier: 3), // T20 = 60
            (segment: 25, multiplier: 2), // DB = 50
          ],
        ),
        _legCompleted(winnerCompetitorId: 'c1', winnerPlayerId: 'p1'),
      ];

      // Leg 2: p1 throws 180, p2 responds with 60, p1 busts on 321 (bust turn
      // excluded from scored points), p2 throws 60 and wins fictitiously.
      // We only need a second LegCompleted to mark the leg end — projections
      // only care about correctness within the slice.
      final leg2 = <GameEvent>[
        ..._turn(
          competitorId: 'c1',
          playerId: 'p1',
          startingScore: 501,
          darts: [
            (segment: 20, multiplier: 3),
            (segment: 20, multiplier: 3),
            (segment: 20, multiplier: 3),
          ],
        ),
        ..._turn(
          competitorId: 'c2',
          playerId: 'p2',
          startingScore: 501,
          darts: [
            (segment: 20, multiplier: 1),
            (segment: 20, multiplier: 1),
            (segment: 20, multiplier: 1),
          ],
        ),
        ..._turn(
          competitorId: 'c1',
          playerId: 'p1',
          startingScore: 321,
          darts: [
            (segment: 20, multiplier: 3),
            (segment: 20, multiplier: 3),
            (segment: 20, multiplier: 3),
          ],
          reason: 'bust',
        ),
        _legCompleted(winnerCompetitorId: 'c2', winnerPlayerId: 'p2'),
      ];

      final result = useCase.execute(
        events: [...leg1, ...leg2],
        competitors: [c1, c2],
        gameType: GameType.x01,
      );

      expect(result, hasLength(2));

      // ── Leg 1 ────────────────────────────────────────────────────
      final l1 = result[0];
      expect(l1.legNumber, 1);
      expect(l1.winnerCompetitorId, 'c1');
      expect(l1.winnerName, 'Alice');

      final l1p1 = l1.byCompetitor.firstWhere((c) => c.competitorId == 'c1');
      expect(l1p1.dartsThrown, 3);
      expect(l1p1.threeDartAverage, closeTo(170.0, 0.001));
      expect(l1p1.checkoutPercentage, 100.0);
      expect(l1p1.highestCheckout, 170);
      // 170 lands exclusively in the 140+ bracket.
      expect(l1p1.oneEightyTurns, 0);
      expect(l1p1.oneFortyPlusTurns, 1);
      expect(l1p1.oneHundredPlusTurns, 0);
      expect(l1p1.sixtyPlusTurns, 0);

      final l1p2 = l1.byCompetitor.firstWhere((c) => c.competitorId == 'c2');
      expect(l1p2.dartsThrown, 0);
      expect(l1p2.threeDartAverage, isNull);
      expect(l1p2.highestCheckout, isNull);
      expect(l1p2.checkoutPercentage, isNull);

      // ── Leg 2 ────────────────────────────────────────────────────
      final l2 = result[1];
      expect(l2.legNumber, 2);
      expect(l2.winnerCompetitorId, 'c2');

      final l2p1 = l2.byCompetitor.firstWhere((c) => c.competitorId == 'c1');
      // Turn 1 (180) counted, Turn 2 (bust, 180) ALSO counted in scored points
      // — busts contribute to AVG (per phase 1.2 of #87).
      // Avg = (180 + 180) * 3 / 6 = 180.
      expect(l2p1.dartsThrown, 6);
      expect(l2p1.threeDartAverage, closeTo(180.0, 0.001));
      // 180 lands exclusively in the 180s bracket. (Buckets still exclude
      // busted turns — the 180-bust does not count as a 180 turn.)
      expect(l2p1.oneEightyTurns, 1);
      expect(l2p1.oneFortyPlusTurns, 0);
      expect(l2p1.oneHundredPlusTurns, 0);
      expect(l2p1.sixtyPlusTurns, 0);
      // No checkout attempted by p1 in leg 2 (starting_score > 170).
      expect(l2p1.checkoutPercentage, isNull);
      expect(l2p1.highestCheckout, isNull);

      final l2p2 = l2.byCompetitor.firstWhere((c) => c.competitorId == 'c2');
      expect(l2p2.dartsThrown, 3);
      expect(l2p2.threeDartAverage, closeTo(60.0, 0.001));
      expect(l2p2.oneFortyPlusTurns, 0);
    });

    test('trailing events after last LegCompleted are ignored', () {
      final events = <GameEvent>[
        ..._turn(
          competitorId: 'c1',
          playerId: 'p1',
          startingScore: 170,
          darts: [
            (segment: 20, multiplier: 3),
            (segment: 20, multiplier: 3),
            (segment: 25, multiplier: 2),
          ],
        ),
        _legCompleted(winnerCompetitorId: 'c1', winnerPlayerId: 'p1'),
        // A partial turn afterward (e.g. game in progress / edge case).
        ..._turn(
          competitorId: 'c2',
          playerId: 'p2',
          startingScore: 501,
          darts: [
            (segment: 20, multiplier: 1),
          ],
        ),
      ];
      final result = useCase.execute(
        events: events,
        competitors: [c1, c2],
        gameType: GameType.x01,
      );
      expect(result, hasLength(1));
      // The trailing dart is not counted against c2.
      final l1p2 = result[0].byCompetitor.firstWhere((c) => c.competitorId == 'c2');
      expect(l1p2.dartsThrown, 0);
    });

    // #637: per-leg checkout % is out-strategy-aware. A visit that finishes from
    // 57 throws a triple (T19) — a finish under master-out but NOT under
    // double-out. The use case must thread outStrategy so the per-leg stat
    // matches the game's rules.
    test('checkout attempt respects outStrategy (master-out triple finish)', () {
      List<GameEvent> events() => <GameEvent>[
            ..._turn(
              competitorId: 'c1',
              playerId: 'p1',
              startingScore: 57,
              darts: [(segment: 19, multiplier: 3)], // T19 → checkout from 57
              reason: 'checkout',
            ),
            _legCompleted(winnerCompetitorId: 'c1', winnerPlayerId: 'p1'),
          ];

      // Default double-out: 57 is not a double finish → no attempt recorded.
      _resetSeq();
      final dbl = useCase.execute(
        events: events(),
        competitors: [c1, c2],
        gameType: GameType.x01,
      );
      expect(
        dbl[0].byCompetitor.firstWhere((c) => c.competitorId == 'c1').checkoutPercentage,
        isNull,
        reason: '57 is not a double-out finish',
      );

      // Master-out: 57 is a triple finish → 1 attempt, leg won → 100%.
      _resetSeq();
      final mas = useCase.execute(
        events: events(),
        competitors: [c1, c2],
        gameType: GameType.x01,
        outStrategy: 'master',
      );
      expect(
        mas[0].byCompetitor.firstWhere((c) => c.competitorId == 'c1').checkoutPercentage,
        closeTo(100.0, 0.001),
        reason: '57 is a master-out (triple) finish',
      );
    });
  });

  group('cricket game', () {
    test('computes per-leg MPR and mark buckets', () {
      // Cricket, single leg. p1 throws T20 T20 T20 (9 marks), T19 T19 T19
      // (9 marks), DB DB DB (6 marks). p2 throws non-scoring. p1 wins.
      final events = <GameEvent>[
        ..._turn(
          competitorId: 'c1',
          playerId: 'p1',
          startingScore: 0,
          darts: [
            (segment: 20, multiplier: 3),
            (segment: 20, multiplier: 3),
            (segment: 20, multiplier: 3),
          ],
        ),
        ..._turn(
          competitorId: 'c2',
          playerId: 'p2',
          startingScore: 0,
          darts: [
            (segment: 1, multiplier: 1),
            (segment: 1, multiplier: 1),
            (segment: 1, multiplier: 1),
          ],
        ),
        ..._turn(
          competitorId: 'c1',
          playerId: 'p1',
          startingScore: 0,
          darts: [
            (segment: 19, multiplier: 3),
            (segment: 19, multiplier: 3),
            (segment: 19, multiplier: 3),
          ],
        ),
        ..._turn(
          competitorId: 'c2',
          playerId: 'p2',
          startingScore: 0,
          darts: [
            (segment: 1, multiplier: 1),
            (segment: 1, multiplier: 1),
            (segment: 1, multiplier: 1),
          ],
        ),
        ..._turn(
          competitorId: 'c1',
          playerId: 'p1',
          startingScore: 0,
          darts: [
            (segment: 25, multiplier: 2),
            (segment: 25, multiplier: 2),
            (segment: 25, multiplier: 2),
          ],
        ),
        _legCompleted(winnerCompetitorId: 'c1', winnerPlayerId: 'p1'),
      ];

      final result = useCase.execute(
        events: events,
        competitors: [c1, c2],
        gameType: GameType.cricket,
      );
      expect(result, hasLength(1));
      final leg = result.single;
      expect(leg.winnerCompetitorId, 'c1');

      final lc1 = leg.byCompetitor.firstWhere((c) => c.competitorId == 'c1');
      expect(lc1.dartsThrown, 9);
      // Marks: 9 + 9 + 6 = 24 across 3 turns → MPR 8.0
      expect(lc1.marksPerRound, closeTo(8.0, 0.001));
      // First 9 darts = turn 1 + turn 2 (cricket first-9 counts across 3 turns
      // of own player). We only have 2 turns in the first 9 darts window for
      // p1 before the mark-buckets apply. 3 player-turns in the leg == first
      // 9. Total marks = 24 / (1 leg × 3) = 8.0
      expect(lc1.firstNineMarksPerRound, closeTo(8.0, 0.001));
      // 9-mark turns: 2 (T20×3, T19×3). 6-mark turn: 1 (DB×3).
      expect(lc1.nineMarkTurns, 2);
      expect(lc1.sixMarkTurns, 1);

      final lc2 = leg.byCompetitor.firstWhere((c) => c.competitorId == 'c2');
      // All non-target hits → 0 marks.
      expect(lc2.dartsThrown, 6);
      expect(lc2.marksPerRound, 0.0);
      expect(lc2.nineMarkTurns, 0);
    });
  });
}
