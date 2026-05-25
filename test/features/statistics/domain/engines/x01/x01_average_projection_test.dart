import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_average_projection.dart';

GameEvent _makeEvent(
  String type,
  Map<String, dynamic> payload, {
  int seq = 1,
}) =>
    GameEvent(
      eventId: 'evt-$seq-$type',
      gameId: 'game-1',
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
    );

void main() {
  late X01AverageProjection engine;

  setUp(() {
    engine = X01AverageProjection();
  });

  // ── Category A: Construction & Initialization ──────────────────────────────

  test('A1 — init produces zero snapshot', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['threeDartAverage'], 0.0);
    expect(s['totalScoredPoints'], 0);
    expect(s['totalDartsThrown'], 0);
  });

  test('A2 — init with different context does not bleed into snapshot', () {
    engine.init(_makeContext(playerId: 'p2'));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['totalDartsThrown'], 0);
  });

  test('A4 — snapshot after init is deterministic across two calls', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B: Single Event Application ──────────────────────────────────

  test('B1 — DartThrown increments dart count', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 20}));
    expect(engine.snapshot()['totalDartsThrown'], 1);
  });

  test('B2 — unsupported events (TurnStarted) are ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1'}));
    final s = engine.snapshot();
    expect(s['totalDartsThrown'], 0);
    expect(s['totalScoredPoints'], 0);
  });

  test('B2 — DartThrown for other player ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p2', 'score': 60}));
    expect(engine.snapshot()['totalDartsThrown'], 0);
  });

  // ── Category C: Ordering & Determinism ────────────────────────────────────

  test('C1 — two darts then TurnEnded yields correct average', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 20}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 20}, seq: 2));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 20}, seq: 3));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 4));
    // 60 points / 3 darts * 3 = 60
    expect(engine.snapshot()['threeDartAverage'], closeTo(60.0, 0.001));
  });

  test('C3 — parallel engines with same events converge', () {
    final e2 = X01AverageProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 40}, seq: 1),
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 40}, seq: 2),
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 3),
    ];
    for (final e in events) {
      engine.apply(e);
      e2.apply(e);
    }
    expect(engine.snapshot(), e2.snapshot());
  });

  // ── Category D: Scope Reset Semantics ─────────────────────────────────────

  test('D1 — reset(turn) clears _turnScore but not totals', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2));
    // now start another turn, add a dart, then reset(turn)
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 20}, seq: 3));
    engine.reset(ProjectionScope.turn);
    // totalDartsThrown still counts previous turn's darts + the one just thrown
    expect(engine.snapshot()['totalScoredPoints'], 60);
    // currentTurnScore reset — next TurnEnded with reason normal contributes 0
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 4));
    expect(engine.snapshot()['totalScoredPoints'], 60);
  });

  test('D1 — reset(leg) is a no-op for turn-scoped projection', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2));
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['totalScoredPoints'], 60);
  });

  // ── Category E: Replay & Correction Safety ────────────────────────────────

  test('E1 — replay from zero yields same snapshot', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 45}, seq: 1),
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 45}, seq: 2),
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 45}, seq: 3),
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 4),
    ];
    for (final e in events) engine.apply(e);
    final first = engine.snapshot();

    engine.init(_makeContext());
    for (final e in events) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F: Partial Streams ────────────────────────────────────────────

  test('F1 — mid-turn truncation yields valid snapshot', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    // No TurnEnded — valid snapshot still returned
    final s = engine.snapshot();
    expect(s['totalDartsThrown'], 1);
    expect(s['totalScoredPoints'], 0); // not committed yet
  });

  test(
      'F2 — legacy TurnEnded without turn_score falls back to dart-sum (backward compat)',
      () {
    // Pre-#318 events do not carry `turn_score` in the payload. The
    // projection falls back to summing per-dart scores, preserving the
    // numbers historical games already had. This means a busted turn from
    // an old game STILL counts its dart sum — accepted because rewriting
    // old games' stats is out of scope for the fix.
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 2));
    expect(engine.snapshot()['totalScoredPoints'], 60);
  });

  test(
      'F3 — TurnEnded with turn_score=0 (bust) contributes 0 to numerator (#318)',
      () {
    // New events carry the spec-correct turn_score: bust → turn_start_score
    // - turn_end_score = 0 (engine reverts on bust).
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 2));
    engine.apply(_makeEvent('TurnEnded',
        {'player_id': 'p1', 'reason': 'bust', 'turn_score': 0}, seq: 3));
    final s = engine.snapshot();
    expect(s['totalScoredPoints'], 0,
        reason: 'spec §5.2: bust turn contributes 0 points');
    expect(s['totalDartsThrown'], 2,
        reason: 'partial turns still count their darts in the denominator');
  });

  test(
      'F4 — TurnEnded with turn_score=0 (Double-In not-in) contributes 0 (#318)',
      () {
    // Double-In: player throws three singles without hitting a double →
    // engine leaves score unchanged → turn_score = 0. Without this fix
    // the projection summed the dart scores (57) and reported PPR 57.
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 20}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 19}, seq: 2));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 18}, seq: 3));
    engine.apply(_makeEvent('TurnEnded',
        {'player_id': 'p1', 'reason': 'normal', 'turn_score': 0}, seq: 4));
    expect(engine.snapshot()['totalScoredPoints'], 0);
  });

  test(
      'F5 — TurnEnded with turn_score > 0 contributes that exact amount (#318)',
      () {
    // Normal scoring turn: engine reports turn_score; projection uses it
    // verbatim regardless of the per-dart sum (which equals it anyway).
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 2));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 3));
    engine.apply(_makeEvent('TurnEnded',
        {'player_id': 'p1', 'reason': 'normal', 'turn_score': 180}, seq: 4));
    expect(engine.snapshot()['totalScoredPoints'], 180);
  });

  // ── Category G: Isolation ─────────────────────────────────────────────────

  test('G2 — two engine instances do not share state', () {
    final e2 = X01AverageProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    expect(e2.snapshot()['totalDartsThrown'], 0);
  });

  // ── Category H: Performance ────────────────────────────────────────────────

  test('H1 — large event list processes without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 1000; i++) {
      engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 1}, seq: i * 2));
      engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: i * 2 + 1));
    }
    final s = engine.snapshot();
    expect(s['totalDartsThrown'], 1000);
    expect(s['totalScoredPoints'], 1000);
  });

  // ── GS1/GS2/GS3 ───────────────────────────────────────────────────────────

  test('GS1 — descriptor declares only x01 support', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes, equals({GameType.x01}));
  });

  test('GS2 — engine not invoked under cricket game type', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes.contains(GameType.cricket), isFalse);
  });
}
