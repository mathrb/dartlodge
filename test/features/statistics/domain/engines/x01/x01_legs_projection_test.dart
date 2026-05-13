import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_legs_projection.dart';

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
  late X01LegsProjection engine;

  setUp(() {
    engine = X01LegsProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces zero counters', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['legsWon'], 0);
    expect(s['legsPlayed'], 0);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — LegCompleted increments legsPlayed', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}));
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 0);
  });

  test('B1 — LegCompleted with player as winner increments legsWon', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}));
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 1);
  });

  test('B2 — DartThrown ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['legsPlayed'], 0);
  });

  test('B2 — TurnStarted ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}));
    expect(engine.snapshot()['legsPlayed'], 0);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — multiple legs tracked correctly', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 2));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3));
    expect(engine.snapshot()['legsPlayed'], 3);
    expect(engine.snapshot()['legsWon'], 2);
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01LegsProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 2),
    ];
    for (final e in events) {
      engine.apply(e);
      e2.apply(e);
    }
    expect(engine.snapshot(), e2.snapshot());
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D1 — reset(turn) does not clear counters', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}));
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 1);
  });

  test('D2 — reset(leg) does not clear counters (cumulative)', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}));
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 1);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay yields identical snapshot', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 2),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3),
    ];
    for (final e in events) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in events) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream without GameCompleted is valid', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}));
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 0);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01LegsProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}));
    expect(e2.snapshot()['legsPlayed'], 0);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 500 legs processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 500; i++) {
      engine.apply(_makeEvent(
          'LegCompleted',
          {'winner_player_id': i.isEven ? 'p1' : 'p2'},
          seq: i));
    }
    expect(engine.snapshot()['legsPlayed'], 500);
    expect(engine.snapshot()['legsWon'], 250);
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
