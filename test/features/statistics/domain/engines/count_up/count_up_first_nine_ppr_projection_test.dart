import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/count_up/count_up_first_nine_ppr_projection.dart';

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

GameEvent _turnStarted(String pid, {int seq = 1}) =>
    _e('TurnStarted', {'player_id': pid}, seq: seq);

GameEvent _dart(String pid, int seg, int mult, {int seq = 1}) => _e(
      'DartThrown',
      {'player_id': pid, 'segment': seg, 'multiplier': mult},
      seq: seq,
    );

GameEvent _turnEnded(String pid, {int seq = 1}) =>
    _e('TurnEnded', {'player_id': pid, 'reason': 'normal'}, seq: seq);

GameEvent _legCompleted({int seq = 1}) =>
    _e('LegCompleted', {'winner_competitor_id': 'c1'}, seq: seq);

ProjectionContext _ctx({String playerId = 'p1'}) => ProjectionContext(
      playerId: playerId,
      gameType: GameType.countUp,
      inStrategy: 'straight',
      outStrategy: 'straight',
      playerIds: ['p1', 'p2'],
    );

/// Apply a 3-dart turn for [pid] starting at sequence [seqStart].
/// Returns the next free sequence number.
int _applyTurn(
  CountUpFirstNinePprProjection engine,
  String pid,
  List<({int seg, int mult})> darts,
  int seqStart,
) {
  var s = seqStart;
  engine.apply(_turnStarted(pid, seq: s++));
  for (final d in darts) {
    engine.apply(_dart(pid, d.seg, d.mult, seq: s++));
  }
  engine.apply(_turnEnded(pid, seq: s++));
  return s;
}

void main() {
  late CountUpFirstNinePprProjection engine;

  setUp(() => engine = CountUpFirstNinePprProjection());

  test('init yields null PPR', () {
    engine.init(_ctx());
    final s = engine.snapshot();
    expect(s['firstNinePpr'], isNull);
    expect(s['totalFirstNineLegs'], 0);
  });

  test('descriptor wired correctly', () {
    expect(engine.descriptor.id, 'count_up.firstNineAverage');
    expect(engine.descriptor.supportedGameTypes, {GameType.countUp});
  });

  test('first 3 turns of 60 points each, then LegCompleted → PPR = 60', () {
    engine.init(_ctx());
    var s = 1;
    s = _applyTurn(engine, 'p1', [
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
    ], s);
    s = _applyTurn(engine, 'p1', [
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
    ], s);
    s = _applyTurn(engine, 'p1', [
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
    ], s);
    engine.apply(_legCompleted(seq: s));
    final out = engine.snapshot();
    // (180 / 9) * 3 = 60
    expect(out['firstNinePpr'], 60.0);
    expect(out['totalFirstNineLegs'], 1);
  });

  test('turn 4+ does NOT contribute to first-nine total', () {
    engine.init(_ctx());
    var s = 1;
    // Three turns of MISSes → 0 first-nine points
    for (var i = 0; i < 3; i++) {
      s = _applyTurn(engine, 'p1', [
        (seg: 0, mult: 1),
        (seg: 0, mult: 1),
        (seg: 0, mult: 1),
      ], s);
    }
    // Turn 4 of T20s — should not count
    s = _applyTurn(engine, 'p1', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
    ], s);
    engine.apply(_legCompleted(seq: s));
    expect(engine.snapshot()['firstNinePpr'], 0.0);
  });

  test('first-nine darts from other players are ignored', () {
    engine.init(_ctx());
    // p2's full turns should not contribute to p1's first-nine PPR
    var s = 1;
    s = _applyTurn(engine, 'p2', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
    ], s);
    s = _applyTurn(engine, 'p1', [
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
    ], s);
    s = _applyTurn(engine, 'p2', [
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
      (seg: 20, mult: 3),
    ], s);
    s = _applyTurn(engine, 'p1', [
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
    ], s);
    s = _applyTurn(engine, 'p1', [
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
      (seg: 20, mult: 1),
    ], s);
    engine.apply(_legCompleted(seq: s));
    // p1's first nine darts: 9 × 20 = 180; PPR = 60
    expect(engine.snapshot()['firstNinePpr'], 60.0);
  });

  test('LegCompleted with no turns recorded does not increment totalFirstNineLegs', () {
    engine.init(_ctx());
    engine.apply(_legCompleted(seq: 1));
    expect(engine.snapshot()['totalFirstNineLegs'], 0);
    expect(engine.snapshot()['firstNinePpr'], isNull);
  });
}
