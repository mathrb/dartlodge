import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';
import 'package:my_darts/features/statistics/domain/engines/cricket/cricket_mark_buckets_projection.dart';

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

void _applyTurn(CricketMarkBucketsProjection engine, List<String> segments,
    {int startSeq = 1}) {
  int seq = startSeq;
  for (final seg in segments) {
    engine.apply(
        _makeEvent('DartThrown', {'player_id': 'p1', 'segment': seg}, seq: seq++));
  }
  engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: seq));
}

void main() {
  late CricketMarkBucketsProjection engine;

  setUp(() {
    engine = CricketMarkBucketsProjection();
  });

  // ── Category A: Construction & Initialization ──────────────────────────────

  test('A1 — init produces zero counts', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['sixMarkTurns'], 0);
    expect(s['nineMarkTurns'], 0);
  });

  // ── Category B: Single Event Application ──────────────────────────────────

  test('B1 — turn with 9 marks increments both buckets', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'T19', 'T18']); // 9 marks
    final s = engine.snapshot();
    expect(s['nineMarkTurns'], 1);
    expect(s['sixMarkTurns'], 1);
  });

  test('B2 — turn with 6 marks increments only sixMarkTurns', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'T19', 'MISS']); // 6 marks
    final s = engine.snapshot();
    expect(s['sixMarkTurns'], 1);
    expect(s['nineMarkTurns'], 0);
  });

  test('B3 — turn with 5 marks increments neither bucket', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'D19', 'MISS']); // 3+2+0 = 5 marks
    final s = engine.snapshot();
    expect(s['sixMarkTurns'], 0);
    expect(s['nineMarkTurns'], 0);
  });

  test('B4 — non-cricket target darts count as zero marks', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T10', 'T5', 'T1']); // all non-cricket
    final s = engine.snapshot();
    expect(s['sixMarkTurns'], 0);
    expect(s['nineMarkTurns'], 0);
  });

  test('B5 — other player turn is ignored', () {
    engine.init(_makeContext());
    engine.apply(
        _makeEvent('DartThrown', {'player_id': 'p2', 'segment': 'T20'}, seq: 1));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p2'}, seq: 2));
    expect(engine.snapshot()['sixMarkTurns'], 0);
  });

  // ── Category C: Multi-Turn Sequences ─────────────────────────────────────

  test('C1 — accumulates across multiple turns', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'T19', 'T18'], startSeq: 1);  // 9 marks
    _applyTurn(engine, ['T20', 'T19', 'MISS'], startSeq: 10); // 6 marks
    _applyTurn(engine, ['T20', 'MISS', 'MISS'], startSeq: 20); // 3 marks
    final s = engine.snapshot();
    expect(s['sixMarkTurns'], 2); // turns with ≥6
    expect(s['nineMarkTurns'], 1); // only first turn had 9
  });

  test('C2 — DB (2 marks) contributes to total', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'T15', 'DB']); // 3+3+2 = 8 marks → ≥6
    expect(engine.snapshot()['sixMarkTurns'], 1);
    expect(engine.snapshot()['nineMarkTurns'], 0);
  });

  // ── Category D: Scope Reset ────────────────────────────────────────────────

  test('D1 — reset(turn) clears in-progress turn marks', () {
    engine.init(_makeContext());
    engine.apply(
        _makeEvent('DartThrown', {'player_id': 'p1', 'segment': 'T20'}, seq: 1));
    engine.reset(ProjectionScope.turn);
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1'}, seq: 2));
    // After reset, turn had 0 marks → no bucket increment
    expect(engine.snapshot()['sixMarkTurns'], 0);
  });

  test('D2 — reset(leg/career) does not wipe accumulated counts', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'T19', 'T18']);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.career);
    expect(engine.snapshot()['nineMarkTurns'], 1);
  });

  // ── Category E: Edge Cases ─────────────────────────────────────────────────

  test('E1 — turn with exactly 6 marks hits boundary correctly', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'T15', '15']); // 3+3+1 = 7? No: T20=3, T15=3, 15=1 = 7
    // Let's try T20+D19+MISS = 3+2+0 = 5 (not hit) and T20+T15+15 = 7 (hit)
    _applyTurn(engine, ['T20', 'D15', '15'], startSeq: 10); // 3+2+1 = 6 marks → hit
    expect(engine.snapshot()['sixMarkTurns'], 2); // both turns have ≥6 (7 and 6)
  });

  // ── Category F: Re-initialization ─────────────────────────────────────────

  test('F1 — init twice resets all counts', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'T19', 'T18']);
    engine.init(_makeContext());
    expect(engine.snapshot()['sixMarkTurns'], 0);
    expect(engine.snapshot()['nineMarkTurns'], 0);
  });

  // ── Category G: Descriptor Metadata ───────────────────────────────────────

  test('G1 — descriptor id is cricket.markBuckets', () {
    expect(engine.descriptor.id, 'cricket.markBuckets');
  });

  test('G2 — supports only cricket', () {
    expect(engine.descriptor.supportedGameTypes, {GameType.cricket});
  });

  test('G3 — consumes DartThrown and TurnEnded', () {
    expect(engine.descriptor.consumedEventTypes,
        containsAll({'DartThrown', 'TurnEnded'}));
  });

  // ── GS1–GS3 ───────────────────────────────────────────────────────────────

  test('GS1 — not applicable to X01', () {
    expect(engine.descriptor.supportedGameTypes, isNot(contains(GameType.x01)));
  });

  test('GS2 — applicable to cricket', () {
    expect(engine.descriptor.supportedGameTypes, contains(GameType.cricket));
  });

  test('GS3 — maximum 9-mark turn (T20+T19+T18) is counted correctly', () {
    engine.init(_makeContext());
    _applyTurn(engine, ['T20', 'T19', 'T18']); // 3+3+3 = 9 marks
    expect(engine.snapshot()['nineMarkTurns'], 1);
    expect(engine.snapshot()['sixMarkTurns'], 1);
  });
}
