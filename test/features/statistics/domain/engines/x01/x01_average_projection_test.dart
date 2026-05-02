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
      playerIds: ['p1', 'p2'],
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

  test('F2 — bust turn does not add to scored points', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 2));
    expect(engine.snapshot()['totalScoredPoints'], 0);
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
