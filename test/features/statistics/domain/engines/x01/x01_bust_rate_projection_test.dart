import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_bust_rate_projection.dart';

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
  late X01BustRateProjection engine;

  setUp(() {
    engine = X01BustRateProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces zero snapshot', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['bustRate'], 0.0);
    expect(s['bustTurns'], 0);
    expect(s['totalTurns'], 0);
  });

  test('A4 — snapshot after init is deterministic', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — normal TurnEnded increments totalTurns only', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}));
    expect(engine.snapshot()['totalTurns'], 1);
    expect(engine.snapshot()['bustTurns'], 0);
  });

  test('B1 — bust TurnEnded increments both counters', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}));
    expect(engine.snapshot()['totalTurns'], 1);
    expect(engine.snapshot()['bustTurns'], 1);
  });

  test('B2 — DartThrown ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['totalTurns'], 0);
  });

  test('B2 — other player TurnEnded ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p2', 'reason': 'bust'}));
    expect(engine.snapshot()['totalTurns'], 0);
    expect(engine.snapshot()['bustTurns'], 0);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — bust rate calculates correctly', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 2));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 3));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 4));
    // 2 busts / 4 turns = 0.5
    expect(engine.snapshot()['bustRate'], closeTo(0.5, 0.001));
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01BustRateProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 1),
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2),
    ];
    for (final e in events) {
      engine.apply(e);
      e2.apply(e);
    }
    expect(engine.snapshot(), e2.snapshot());
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D1 — reset(turn) does not clear lifetime counters', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 1));
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['totalTurns'], 1);
    expect(engine.snapshot()['bustTurns'], 1);
  });

  test('D2 — reset(leg) does not clear counters', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 1));
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['bustTurns'], 1);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay yields identical snapshot', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 1),
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 2),
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 3),
    ];
    for (final e in events) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in events) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream (no GameCompleted) handled gracefully', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 1));
    final s = engine.snapshot();
    expect(s['bustRate'], 0.0);
    expect(s['totalTurns'], 1);
  });

  test('Rat1 — division by zero safe when no turns', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['bustRate'], 0.0);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01BustRateProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 1));
    expect(e2.snapshot()['bustTurns'], 0);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 1000 turns processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 1000; i++) {
      engine.apply(_makeEvent(
          'TurnEnded', {'player_id': 'p1', 'reason': i.isEven ? 'normal' : 'bust'}, seq: i));
    }
    expect(engine.snapshot()['totalTurns'], 1000);
    expect(engine.snapshot()['bustTurns'], 500);
  });

  // ── GS1/GS2 ───────────────────────────────────────────────────────────────

  test('GS1 — descriptor declares only x01', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes, equals({GameType.x01}));
  });

  test('GS2 — cricket not in supported game types', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes.contains(GameType.cricket), isFalse);
  });
}
