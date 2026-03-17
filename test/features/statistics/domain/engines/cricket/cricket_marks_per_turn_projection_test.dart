import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';
import 'package:my_darts/features/statistics/domain/engines/cricket/cricket_marks_per_turn_projection.dart';

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
  late CricketMarksPerTurnProjection engine;

  setUp(() {
    engine = CricketMarksPerTurnProjection();
  });

  // ── Category A: Construction & Initialization ──────────────────────────────

  test('A1 — init produces zero snapshot', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['marksPerTurn'], 0.0);
    expect(s['totalMarks'], 0);
    expect(s['totalTurns'], 0);
  });

  test('A2 — init for different player ignores other player darts', () {
    engine.init(_makeContext(playerId: 'p2'));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalTurns'], 0);
  });

  test('A4 — snapshot after init is deterministic', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B: Single Event Application ──────────────────────────────────

  test('B1 — T20 in turn scores 3 marks', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalMarks'], 3);
    expect(engine.snapshot()['totalTurns'], 1);
  });

  test('B2 — D20 scores 2 marks', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'D20'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalMarks'], 2);
  });

  test('B3 — 20 (single) scores 1 mark', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': '20'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalMarks'], 1);
  });

  test('B4 — SB scores 1 mark', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'SB'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalMarks'], 1);
  });

  test('B5 — DB scores 2 marks', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'DB'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalMarks'], 2);
  });

  test('B6 — MISS scores 0 marks', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'MISS'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalMarks'], 0);
  });

  test('B7 — non-cricket target (T10) scores 0 marks', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T10'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalMarks'], 0);
  });

  // ── Category C: Multi-Event Sequences ─────────────────────────────────────

  test('C1 — MPT = totalMarks / totalTurns', () {
    engine.init(_makeContext());
    // Turn 1: T20 + T19 + T18 = 9 marks
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T19'}, seq: 2));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T18'}, seq: 3));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 4));
    // Turn 2: T15 + MISS + MISS = 3 marks
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T15'}, seq: 5));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'MISS'}, seq: 6));
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'MISS'}, seq: 7));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 8));
    final s = engine.snapshot();
    expect(s['totalMarks'], 12);
    expect(s['totalTurns'], 2);
    expect((s['marksPerTurn'] as double).toStringAsFixed(1), '6.0');
  });

  test('C2 — other player events are ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p2', 'segment': 'T20'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p2'}, seq: 2));
    expect(engine.snapshot()['totalTurns'], 0);
    expect(engine.snapshot()['totalMarks'], 0);
  });

  // ── Category D: Scope Reset ────────────────────────────────────────────────

  test('D1 — reset(turn) clears turn marks mid-turn', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.reset(ProjectionScope.turn);
    // After reset, applying TurnEnded should commit 0 marks
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalMarks'], 0);
    expect(engine.snapshot()['totalTurns'], 1);
  });

  test('D2 — reset(leg) and reset(career) do not wipe accumulated totals', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.career);
    expect(engine.snapshot()['totalMarks'], 3);
    expect(engine.snapshot()['totalTurns'], 1);
  });

  // ── Category E: Edge Cases ─────────────────────────────────────────────────

  test('E1 — zero turns yields MPT of 0.0', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['marksPerTurn'], 0.0);
  });

  test('E2 — turn with 0 marks still increments turn count', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'MISS'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['totalTurns'], 1);
    expect(engine.snapshot()['totalMarks'], 0);
    expect(engine.snapshot()['marksPerTurn'], 0.0);
  });

  // ── Category F: Re-initialization ─────────────────────────────────────────

  test('F1 — init twice resets all state', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    engine.init(_makeContext());
    expect(engine.snapshot()['totalTurns'], 0);
    expect(engine.snapshot()['totalMarks'], 0);
  });

  // ── Category G: Descriptor Metadata ───────────────────────────────────────

  test('G1 — descriptor id is cricket.mpt', () {
    expect(engine.descriptor.id, 'cricket.mpt');
  });

  test('G2 — supported game types contains cricket only', () {
    expect(engine.descriptor.supportedGameTypes, {GameType.cricket});
    expect(engine.descriptor.supportedGameTypes, isNot(contains(GameType.x01)));
  });

  test('G3 — consumed event types are DartThrown and TurnEnded', () {
    expect(engine.descriptor.consumedEventTypes, containsAll({'DartThrown', 'TurnEnded'}));
  });

  // ── GS1–GS3: Game-Specific Descriptor Tests ───────────────────────────────

  test('GS1 — not applicable to X01', () {
    expect(engine.descriptor.supportedGameTypes, isNot(contains(GameType.x01)));
  });

  test('GS2 — applicable to cricket', () {
    expect(engine.descriptor.supportedGameTypes, contains(GameType.cricket));
  });

  test('GS3 — 15–20 and Bull are all valid targets', () {
    engine.init(_makeContext());
    for (final seg in ['15', '16', '17', '18', '19', '20', 'SB', 'DB']) {
      engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'segment': seg}, seq: 1));
    }
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 9));
    // 15+16+17+18+19+20 = 6 singles + SB=1 + DB=2 = 9 marks total
    expect(engine.snapshot()['totalMarks'], 9);
  });
}
