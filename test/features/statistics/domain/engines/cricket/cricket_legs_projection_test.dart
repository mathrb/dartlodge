import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_legs_projection.dart';

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
      gameType: GameType.cricket,
      inStrategy: 'straight',
      outStrategy: 'double',
      playerIds: ['p1', 'p2'],
    );

void main() {
  late CricketLegsProjection engine;

  setUp(() {
    engine = CricketLegsProjection();
  });

  // ── Category A: Construction & Initialization ──────────────────────────────

  test('A1 — init produces zero counts', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['legsPlayed'], 0);
    expect(s['legsWon'], 0);
  });

  // ── Category B: Single Event Application ──────────────────────────────────

  test('B1 — LegCompleted increments legsPlayed', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 1));
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 0);
  });

  test('B2 — LegCompleted with own player as winner increments legsWon', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1));
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 1);
  });

  test('B3 — non-LegCompleted events are ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    expect(engine.snapshot()['legsPlayed'], 0);
  });

  // ── Category C: Multi-Event Sequences ─────────────────────────────────────

  test('C1 — multiple legs accumulate correctly', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 2));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3));
    final s = engine.snapshot();
    expect(s['legsPlayed'], 3);
    expect(s['legsWon'], 2);
  });

  // ── Category D: Scope Reset ────────────────────────────────────────────────

  test('D1 — reset does not wipe career totals', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.reset(ProjectionScope.turn);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.career);
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 1);
  });

  // ── Category E: Edge Cases ─────────────────────────────────────────────────

  test('E1 — null winner_player_id does not increment legsWon', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {}, seq: 1));
    expect(engine.snapshot()['legsPlayed'], 1);
    expect(engine.snapshot()['legsWon'], 0);
  });

  // ── Category F: Re-initialization ─────────────────────────────────────────

  test('F1 — init twice resets all state', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.init(_makeContext());
    expect(engine.snapshot()['legsPlayed'], 0);
    expect(engine.snapshot()['legsWon'], 0);
  });

  // ── Category G: Descriptor Metadata ───────────────────────────────────────

  test('G1 — descriptor id is cricket.legs', () {
    expect(engine.descriptor.id, 'cricket.legs');
  });

  test('G2 — supports only cricket', () {
    expect(engine.descriptor.supportedGameTypes, {GameType.cricket});
  });

  test('G3 — consumes LegCompleted only', () {
    expect(engine.descriptor.consumedEventTypes, {'LegCompleted'});
  });

  // ── GS1–GS3 ───────────────────────────────────────────────────────────────

  test('GS1 — not applicable to X01', () {
    expect(engine.descriptor.supportedGameTypes, isNot(contains(GameType.x01)));
  });

  test('GS2 — applicable to cricket', () {
    expect(engine.descriptor.supportedGameTypes, contains(GameType.cricket));
  });

  test('GS3 — win tracked by player_id not competitor_id', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted',
        {'winner_player_id': 'p1', 'winner_competitor_id': 'c99'}, seq: 1));
    expect(engine.snapshot()['legsWon'], 1);
  });
}
