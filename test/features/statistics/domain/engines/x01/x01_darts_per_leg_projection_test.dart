import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_darts_per_leg_projection.dart';

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
      inStrategy: 'Straight In',
      outStrategy: 'Double Out',
      playerIds: ['p1', 'p2'],
    );

void main() {
  late X01DartsPerLegProjection engine;

  setUp(() {
    engine = X01DartsPerLegProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces null dartsPerLeg and zero counters', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['dartsPerLeg'], isNull);
    expect(s['totalDartsThrown'], 0);
    expect(s['legsWon'], 0);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — DartThrown by player increments totalDartsThrown', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['totalDartsThrown'], 1);
    expect(engine.snapshot()['legsWon'], 0);
  });

  test('B1 — LegCompleted with player as winner increments legsWon', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['legsWon'], 1);
    expect(engine.snapshot()['totalDartsThrown'], 1);
  });

  test('B2 — DartThrown by other player ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p2', 'score': 60}));
    expect(engine.snapshot()['totalDartsThrown'], 0);
  });

  test('B2 — LegCompleted where other player wins does not increment legsWon', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}));
    expect(engine.snapshot()['legsWon'], 0);
  });

  test('B2 — TurnStarted event ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 501}));
    expect(engine.snapshot()['totalDartsThrown'], 0);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — dartsPerLeg calculates correctly', () {
    engine.init(_makeContext());
    // 18 darts thrown, 2 legs won → 9.0
    for (int i = 0; i < 18; i++) {
      engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: i * 2));
    }
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 37));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 38));
    expect(engine.snapshot()['dartsPerLeg'], closeTo(9.0, 0.001));
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01DartsPerLegProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2),
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
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['totalDartsThrown'], 1);
    expect(engine.snapshot()['legsWon'], 1);
  });

  test('D2 — reset(leg) does not clear counters (cumulative)', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['totalDartsThrown'], 1);
    expect(engine.snapshot()['legsWon'], 1);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay yields identical snapshot', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1),
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 2),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3),
    ];
    for (final e in events) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in events) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream without LegCompleted returns null dartsPerLeg', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['dartsPerLeg'], isNull);
    expect(engine.snapshot()['totalDartsThrown'], 1);
  });

  test('Rat1 — division by zero safe when no legs won', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['dartsPerLeg'], isNull);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01DartsPerLegProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(e2.snapshot()['totalDartsThrown'], 0);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 1000 darts and 100 legs processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 1000; i++) {
      engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: i * 2));
    }
    for (int i = 0; i < 100; i++) {
      engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: i * 2 + 1));
    }
    expect(engine.snapshot()['totalDartsThrown'], 1000);
    expect(engine.snapshot()['legsWon'], 100);
    expect(engine.snapshot()['dartsPerLeg'], closeTo(10.0, 0.001));
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
