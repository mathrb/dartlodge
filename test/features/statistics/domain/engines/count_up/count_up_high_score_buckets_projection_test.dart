import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/count_up/count_up_high_score_buckets_projection.dart';

GameEvent _e(String type, Map<String, dynamic> payload, {int seq = 1}) =>
    GameEvent(
      eventId: 'evt-$seq-$type',
      gameId: 'g',
      eventType: type,
      localSequence: seq,
      occurredAt: DateTime(2024),
      payload: payload,
      synced: false,
      actorId: 'p1',
      source: EventSource.client,
    );

GameEvent _dart(String pid, int seg, int mult, {int seq = 1}) => _e(
      'DartThrown',
      {'player_id': pid, 'segment': seg, 'multiplier': mult},
      seq: seq,
    );

GameEvent _turnEnded(String pid, {int seq = 1, String reason = 'normal'}) =>
    _e('TurnEnded', {'player_id': pid, 'reason': reason}, seq: seq);

ProjectionContext _ctx({String playerId = 'p1'}) => ProjectionContext(
      playerId: playerId,
      gameType: GameType.countUp,
      inStrategy: 'straight',
      outStrategy: 'straight',
      playerIds: ['p1', 'p2'],
    );

/// Helper to apply a 3-dart turn ending in a TurnEnded event.
void _applyTurn(
  CountUpHighScoreBucketsProjection engine,
  String pid,
  List<({int seg, int mult})> darts, {
  int seqStart = 1,
  String reason = 'normal',
}) {
  var s = seqStart;
  for (final d in darts) {
    engine.apply(_dart(pid, d.seg, d.mult, seq: s++));
  }
  engine.apply(_turnEnded(pid, seq: s, reason: reason));
}

void main() {
  late CountUpHighScoreBucketsProjection engine;

  setUp(() => engine = CountUpHighScoreBucketsProjection());

  test('init yields all-zero buckets', () {
    engine.init(_ctx());
    final s = engine.snapshot();
    expect(s['sixtyPlusTurns'], 0);
    expect(s['oneHundredPlusTurns'], 0);
    expect(s['oneFortyPlusTurns'], 0);
    expect(s['oneEightyTurns'], 0);
  });

  test('descriptor wired correctly', () {
    expect(engine.descriptor.id, 'count_up.highScoreBuckets');
    expect(engine.descriptor.supportedGameTypes, {GameType.countUp});
  });

  test('exact 180 → oneEighty bucket', () {
    engine.init(_ctx());
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
    ]);
    expect(engine.snapshot()['oneEightyTurns'], 1);
    expect(engine.snapshot()['oneFortyPlusTurns'], 0);
  });

  test('140–179 → oneFortyPlus bucket', () {
    engine.init(_ctx());
    // T20 + T20 + S20 = 60 + 60 + 20 = 140
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 20, mult: 1),
    ]);
    expect(engine.snapshot()['oneFortyPlusTurns'], 1);
    expect(engine.snapshot()['oneEightyTurns'], 0);
  });

  test('100–139 → oneHundredPlus bucket', () {
    engine.init(_ctx());
    // T20 + T20 + MISS = 60 + 60 + 0 = 120
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 0, mult: 1),
    ]);
    expect(engine.snapshot()['oneHundredPlusTurns'], 1);
    expect(engine.snapshot()['oneFortyPlusTurns'], 0);
  });

  test('60–99 → sixtyPlus bucket', () {
    engine.init(_ctx());
    // T20 + MISS + MISS = 60
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 0, mult: 1),
      (seg: 0, mult: 1),
    ]);
    expect(engine.snapshot()['sixtyPlusTurns'], 1);
    expect(engine.snapshot()['oneHundredPlusTurns'], 0);
  });

  test('< 60 → no bucket', () {
    engine.init(_ctx());
    // 20 + 20 + MISS = 40
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
      (seg: 0, mult: 1),
    ]);
    final s = engine.snapshot();
    expect(s['sixtyPlusTurns'], 0);
    expect(s['oneHundredPlusTurns'], 0);
  });

  test('exactly 60 boundary → sixtyPlus', () {
    engine.init(_ctx());
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 0, mult: 1),
      (seg: 0, mult: 1),
    ]);
    expect(engine.snapshot()['sixtyPlusTurns'], 1);
  });

  test('exactly 100 boundary → oneHundredPlus', () {
    engine.init(_ctx());
    // T20 + D20 = 60 + 40 = 100
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 2),
      (seg: 0, mult: 1),
    ]);
    expect(engine.snapshot()['oneHundredPlusTurns'], 1);
  });

  test('exactly 140 boundary → oneFortyPlus', () {
    engine.init(_ctx());
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 20, mult: 1),
    ]);
    expect(engine.snapshot()['oneFortyPlusTurns'], 1);
  });

  test('multiple turns accumulate', () {
    engine.init(_ctx());
    var s = 1;
    // Turn 1: 60
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 0, mult: 1),
      (seg: 0, mult: 1),
    ], seqStart: s);
    s += 4;
    // Turn 2: 180
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
    ], seqStart: s);
    s += 4;
    // Turn 3: 60
    _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 0, mult: 1),
      (seg: 0, mult: 1),
    ], seqStart: s);
    final out = engine.snapshot();
    expect(out['sixtyPlusTurns'], 2);
    expect(out['oneEightyTurns'], 1);
  });

  test('darts for other players are ignored', () {
    engine.init(_ctx());
    _applyTurn(engine, 'p2', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
    ]);
    expect(engine.snapshot()['oneEightyTurns'], 0);
  });

  test('reset(turn) wipes in-flight turn score before bucketing', () {
    engine.init(_ctx());
    engine.apply(_dart('p1', 20, 3, seq: 1));
    engine.reset(ProjectionScope.turn);
    engine.apply(_dart('p1', 20, 1, seq: 2));
    engine.apply(_turnEnded('p1', seq: 3));
    // Only the post-reset 20 counted → no bucket entry.
    expect(engine.snapshot()['sixtyPlusTurns'], 0);
  });
}
