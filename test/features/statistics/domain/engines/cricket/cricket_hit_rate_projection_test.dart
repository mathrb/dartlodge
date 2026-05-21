import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_hit_rate_projection.dart';

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
    );

void main() {
  late CricketHitRateProjection engine;

  setUp(() {
    engine = CricketHitRateProjection();
  });

  // ── Category A: Construction & Initialization ──────────────────────────────

  test('A1 — init produces zero snapshot', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['hitRate'], 0.0);
    expect(s['cricketDarts'], 0);
    expect(s['totalDarts'], 0);
  });

  // ── Category B: Single Event Application ──────────────────────────────────

  test('B1 — T20 is a cricket hit', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    expect(engine.snapshot()['cricketDarts'], 1);
    expect(engine.snapshot()['totalDarts'], 1);
  });

  test('B2 — MISS is not a cricket hit', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'MISS'}, seq: 1));
    expect(engine.snapshot()['cricketDarts'], 0);
    expect(engine.snapshot()['totalDarts'], 1);
  });

  test('B3 — non-cricket segment (T10) is not a hit', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T10'}, seq: 1));
    expect(engine.snapshot()['cricketDarts'], 0);
    expect(engine.snapshot()['totalDarts'], 1);
  });

  test('B4 — other player events ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p2', 'segment': 'T20'}, seq: 1));
    expect(engine.snapshot()['totalDarts'], 0);
  });

  // ── Category C: Multi-Event Sequences ─────────────────────────────────────

  test('C1 — 2 cricket darts out of 3 → hitRate = 2/3', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': '15'}, seq: 2));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'MISS'}, seq: 3));
    final rate = engine.snapshot()['hitRate'] as double;
    expect(rate, closeTo(2.0 / 3.0, 0.001));
  });

  test('C2 — SB and DB both count as hits', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'SB'}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'DB'}, seq: 2));
    expect(engine.snapshot()['cricketDarts'], 2);
    expect(engine.snapshot()['totalDarts'], 2);
    expect(engine.snapshot()['hitRate'], 1.0);
  });

  // ── Category D: Scope Reset ────────────────────────────────────────────────

  test('D1 — reset does not wipe career totals', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.reset(ProjectionScope.turn);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.career);
    expect(engine.snapshot()['totalDarts'], 1);
    expect(engine.snapshot()['cricketDarts'], 1);
  });

  // ── Category E: Edge Cases ─────────────────────────────────────────────────

  test('E1 — zero darts yields hitRate 0.0', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['hitRate'], 0.0);
  });

  // ── Category F: Re-initialization ─────────────────────────────────────────

  test('F1 — init twice resets all state', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.init(_makeContext());
    expect(engine.snapshot()['totalDarts'], 0);
  });

  // ── Category G: Descriptor Metadata ───────────────────────────────────────

  test('G1 — descriptor id is cricket.hitRate', () {
    expect(engine.descriptor.id, 'cricket.hitRate');
  });

  test('G2 — supports only cricket', () {
    expect(engine.descriptor.supportedGameTypes, {GameType.cricket});
  });

  test('G3 — consumes DartThrown plus cricket target-set lifecycle events', () {
    // `GameCreated` and `CricketTargetsAssigned` are consumed so the
    // projection tracks the active cricket target set (random mode);
    // they are otherwise inert for hit-rate counting. See
    // `docs/plans/2026-05-19-cricket-target-modes-design.md` §6.
    expect(
      engine.descriptor.consumedEventTypes,
      {'GameCreated', 'CricketTargetsAssigned', 'DartThrown'},
    );
  });

  // ── GS1–GS3 ───────────────────────────────────────────────────────────────

  test('GS1 — not applicable to X01', () {
    expect(engine.descriptor.supportedGameTypes, isNot(contains(GameType.x01)));
  });

  test('GS2 — applicable to cricket', () {
    expect(engine.descriptor.supportedGameTypes, contains(GameType.cricket));
  });

  test('GS3 — all cricket targets counted as hits', () {
    engine.init(_makeContext());
    for (final seg in ['15', 'T15', 'D15', '16', '17', '18', '19', '20', 'SB', 'DB']) {
      engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': seg}, seq: 1));
    }
    expect(engine.snapshot()['cricketDarts'], 10);
    expect(engine.snapshot()['totalDarts'], 10);
    expect(engine.snapshot()['hitRate'], 1.0);
  });
}
