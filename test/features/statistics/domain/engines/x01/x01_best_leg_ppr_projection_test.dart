import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_best_leg_ppr_projection.dart';

GameEvent _makeEvent(
  String type,
  Map<String, dynamic> payload, {
  int seq = 1,
  String gameId = 'game-1',
}) =>
    GameEvent(
      eventId: 'evt-$seq-$type',
      gameId: gameId,
      eventType: type,
      localSequence: seq,
      occurredAt: DateTime(2024),
      payload: payload,
      synced: false,
      actorId: 'p1',
      source: EventSource.client,
    );

ProjectionContext _makeContext({String playerId = 'p1'}) => ProjectionContext(
      playerId: playerId,
      gameType: GameType.x01,
      inStrategy: 'straight',
      outStrategy: 'double',
      playerIds: ['p1', 'p2'],
    );

void main() {
  late X01BestLegPprProjection engine;

  setUp(() {
    engine = X01BestLegPprProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces null bestLegPpr and bestFirstNinePpr', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['bestLegPpr'], isNull);
    expect(s['bestFirstNinePpr'], isNull);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — best leg PPR computed correctly: 180 in 3 darts = 180.0', () {
    engine.init(_makeContext());
    // Leg: startingScore=180, 3 darts (T20 T20 T20 = 180), won by p1
    final evts = <GameEvent>[];
    evts.add(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 180}, seq: 1));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 2));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 3));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 4));
    evts.add(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 5));
    evts.add(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 6));
    for (final e in evts) engine.apply(e);
    // 180 / 3 darts * 3 = 180.0
    expect(engine.snapshot()['bestLegPpr'], closeTo(180.0, 0.001));
  });

  test('B1 — best first nine PPR requires ≥3 turns', () {
    engine.init(_makeContext());
    // Only 1 turn in leg: no bestFirstNinePpr
    final evts = <GameEvent>[];
    evts.add(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 180}, seq: 1));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 2));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 3));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 4));
    evts.add(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 5));
    evts.add(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 6));
    for (final e in evts) engine.apply(e);
    expect(engine.snapshot()['bestFirstNinePpr'], isNull);
  });

  test('B1 — best first nine PPR computed from 3-turn leg', () {
    engine.init(_makeContext());
    // 3 turns of T20 T20 T20 (3 × 60 = 180 per turn), 9 darts total, won by p1
    // firstNineScore = 540, bestFirstNinePpr = 540/9*3 = 180.0
    final evts = <GameEvent>[];
    int seq = 1;
    for (int t = 0; t < 3; t++) {
      evts.add(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501 - t * 180}, seq: seq++));
      for (int d = 0; d < 3; d++) {
        evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: seq++));
      }
      evts.add(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: seq++));
    }
    evts.add(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: seq++));
    for (final e in evts) engine.apply(e);
    // firstNineScore = 540 (3 turns × 180), bestFirstNinePpr = 540/9*3 = 180.0
    expect(engine.snapshot()['bestFirstNinePpr'], closeTo(180.0, 0.001));
  });

  test('B2 — other player events ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p2', 'starting_score': 501}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p2', 'segment': 20, 'multiplier': 3}, seq: 2));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p2', 'reason': 'normal'}, seq: 3));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 4));
    expect(engine.snapshot()['bestLegPpr'], isNull);
  });

  test('B2 — non-winner LegCompleted does not update bestLegPpr', () {
    engine.init(_makeContext());
    final evts = <GameEvent>[];
    evts.add(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}, seq: 1));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 2));
    evts.add(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 3));
    // p2 wins, not p1
    evts.add(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 4));
    for (final e in evts) engine.apply(e);
    expect(engine.snapshot()['bestLegPpr'], isNull);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — best of two legs keeps the higher value', () {
    engine.init(_makeContext());
    // Leg 1: 501 in 18 darts → PPR = 501/18*3 = 83.5
    // Leg 2: 501 in 9 darts → PPR = 501/9*3 = 167.0
    // Best = 167.0
    int seq = 1;

    // Leg 1: 18 darts
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}, seq: seq++));
    for (int i = 0; i < 18; i++) {
      engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 5, 'multiplier': 3}, seq: seq++));
    }
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: seq++));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: seq++));

    // Leg 2: 9 darts
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}, seq: seq++));
    for (int i = 0; i < 9; i++) {
      engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 5, 'multiplier': 3}, seq: seq++));
    }
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: seq++));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: seq++));

    final bestLeg2 = 501 / 9 * 3;
    expect(engine.snapshot()['bestLegPpr'], closeTo(bestLeg2, 0.001));
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D2 — reset(leg) resets per-leg counters, preserves career bests', () {
    engine.init(_makeContext());
    // Complete one leg to establish a best
    final evts = <GameEvent>[];
    evts.add(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 180}, seq: 1));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 2));
    evts.add(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 3));
    evts.add(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 4));
    for (final e in evts) engine.apply(e);
    final bestBefore = engine.snapshot()['bestLegPpr'] as double?;
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['bestLegPpr'], bestBefore);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay from zero yields same result', () {
    final evts = <GameEvent>[];
    evts.add(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 180}, seq: 1));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 2));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 3));
    evts.add(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 4));
    evts.add(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 5));
    evts.add(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 6));

    engine.init(_makeContext());
    for (final e in evts) engine.apply(e);
    final first = engine.snapshot();

    engine.init(_makeContext());
    for (final e in evts) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream without LegCompleted returns null bests', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 2));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 3));
    expect(engine.snapshot()['bestLegPpr'], isNull);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01BestLegPprProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 180}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: 2));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 3));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 4));
    expect(e2.snapshot()['bestLegPpr'], isNull);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 100 legs processed without issue', () {
    engine.init(_makeContext());
    int seq = 1;
    for (int i = 0; i < 100; i++) {
      engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}, seq: seq++));
      for (int d = 0; d < 9; d++) {
        engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 10, 'multiplier': 3}, seq: seq++));
      }
      engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: seq++));
      engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: seq++));
    }
    expect(engine.snapshot()['bestLegPpr'], isNotNull);
  });

  // ── GS1/GS2/GS3 ───────────────────────────────────────────────────────────

  test('GS1 — descriptor declares only x01', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes, equals({GameType.x01}));
  });

  test('GS2 — cricket not in supported game types', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes.contains(GameType.cricket), isFalse);
  });

  test('GS3 — bust turn does not contribute to first nine score', () {
    engine.init(_makeContext());
    int seq = 1;
    // Turn 1: bust — should NOT be counted in firstNineScore
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}, seq: seq++));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: seq++));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: seq++));
    // Turn 2
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}, seq: seq++));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: seq++));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: seq++));
    // Turn 3
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 441}, seq: seq++));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3}, seq: seq++));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: seq++));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: seq++));

    // firstNineScore = 0 (bust) + 60 + 60 = 120
    // bestFirstNinePpr = 120/9*3 = 40.0
    expect(engine.snapshot()['bestFirstNinePpr'], closeTo(40.0, 0.001));
  });
}
