import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_highest_turn_score_projection.dart';

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
  late X01HighestTurnScoreProjection engine;

  setUp(() {
    engine = X01HighestTurnScoreProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces zeros', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['highestTurnScore'], 0);
    expect(s['currentTurnScore'], 0);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — DartThrown accumulates currentTurnScore', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['currentTurnScore'], 60);
  });

  test('B1 — TurnEnded (non-bust) updates highestTurnScore', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2));
    expect(engine.snapshot()['highestTurnScore'], 60);
    expect(engine.snapshot()['currentTurnScore'], 0);
  });

  test('B1 — TurnEnded (bust) does not update highestTurnScore', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 2));
    expect(engine.snapshot()['highestTurnScore'], 0);
    expect(engine.snapshot()['currentTurnScore'], 0);
  });

  test('B2 — LegCompleted ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}));
    expect(engine.snapshot()['highestTurnScore'], 0);
  });

  test('B2 — other player DartThrown ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p2', 'score': 180}));
    expect(engine.snapshot()['currentTurnScore'], 0);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — highest across multiple turns tracked correctly', () {
    engine.init(_makeContext());
    // Turn 1: 60
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2));
    // Turn 2: 180
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 180}, seq: 3));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 4));
    // Turn 3: 100
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 100}, seq: 5));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 6));
    expect(engine.snapshot()['highestTurnScore'], 180);
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01HighestTurnScoreProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 100}, seq: 1),
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2),
    ];
    for (final e in events) {
      engine.apply(e);
      e2.apply(e);
    }
    expect(engine.snapshot(), e2.snapshot());
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D1 — reset(turn) clears currentTurnScore only', () {
    engine.init(_makeContext());
    // Complete a turn to set highestTurnScore
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2));
    // Accumulate in next turn
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 20}, seq: 3));
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['currentTurnScore'], 0);
    expect(engine.snapshot()['highestTurnScore'], 60); // preserved
  });

  test('D2 — reset(leg) is a no-op', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2));
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['highestTurnScore'], 60);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay from zero yields same snapshot', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1),
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2),
      _makeEvent('DartThrown', {'player_id': 'p1', 'score': 180}, seq: 3),
      _makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 4),
    ];
    for (final e in events) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in events) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F3 — mid-turn truncation returns valid snapshot', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    // No TurnEnded
    final s = engine.snapshot();
    expect(s['currentTurnScore'], 60);
    expect(s['highestTurnScore'], 0);
  });

  test('F1 — bust does not corrupt highestTurnScore', () {
    engine.init(_makeContext());
    // Good turn: 60
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2));
    // Bust turn: would have been 100, but bust
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 100}, seq: 3));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'bust'}, seq: 4));
    expect(engine.snapshot()['highestTurnScore'], 60);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01HighestTurnScoreProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 180}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 2));
    expect(e2.snapshot()['highestTurnScore'], 0);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 1000 turns processed correctly', () {
    engine.init(_makeContext());
    for (int i = 0; i < 1000; i++) {
      engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': i + 1}, seq: i * 2));
      engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: i * 2 + 1));
    }
    expect(engine.snapshot()['highestTurnScore'], 1000);
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
