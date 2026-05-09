import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/count_up/count_up_average_projection.dart';

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

GameEvent _turnEnded(String pid, {int seq = 1}) =>
    _e('TurnEnded', {'player_id': pid, 'reason': 'normal'}, seq: seq);

ProjectionContext _ctx({String playerId = 'p1'}) => ProjectionContext(
      playerId: playerId,
      gameType: GameType.countUp,
      inStrategy: 'straight',
      outStrategy: 'straight',
      playerIds: ['p1', 'p2'],
    );

void main() {
  late CountUpAverageProjection engine;

  setUp(() => engine = CountUpAverageProjection());

  test('init yields zeros', () {
    engine.init(_ctx());
    final s = engine.snapshot();
    expect(s['threeDartAverage'], 0.0);
    expect(s['totalScoredPoints'], 0);
    expect(s['totalDartsThrown'], 0);
  });

  test('descriptor: id, supportedGameTypes, scope', () {
    expect(engine.descriptor.id, 'count_up.average');
    expect(engine.descriptor.supportedGameTypes, {GameType.countUp});
    expect(engine.descriptor.scope, ProjectionScope.turn);
  });

  test('3 darts of T20 + TurnEnded → PPR = 180', () {
    engine.init(_ctx());
    engine.apply(_dart('p1', 20, 3, seq: 1));
    engine.apply(_dart('p1', 20, 3, seq: 2));
    engine.apply(_dart('p1', 20, 3, seq: 3));
    engine.apply(_turnEnded('p1', seq: 4));
    final s = engine.snapshot();
    expect(s['totalDartsThrown'], 3);
    expect(s['totalScoredPoints'], 180);
    expect(s['threeDartAverage'], 180.0);
  });

  test('darts for other players are ignored', () {
    engine.init(_ctx());
    engine.apply(_dart('p2', 20, 3, seq: 1));
    engine.apply(_dart('p2', 20, 3, seq: 2));
    expect(engine.snapshot()['totalDartsThrown'], 0);
  });

  test('TurnEnded for other player does not flush', () {
    engine.init(_ctx());
    engine.apply(_dart('p1', 20, 1, seq: 1));
    engine.apply(_turnEnded('p2', seq: 2));
    // p1's 20 still in-flight, not flushed
    expect(engine.snapshot()['totalScoredPoints'], 0);
    // p1's TurnEnded flushes it
    engine.apply(_turnEnded('p1', seq: 3));
    expect(engine.snapshot()['totalScoredPoints'], 20);
  });

  test('MISS adds 0 darts thrown but no score', () {
    engine.init(_ctx());
    engine.apply(_dart('p1', 0, 1, seq: 1)); // MISS
    engine.apply(_dart('p1', 0, 1, seq: 2));
    engine.apply(_dart('p1', 0, 1, seq: 3));
    engine.apply(_turnEnded('p1', seq: 4));
    final s = engine.snapshot();
    expect(s['totalDartsThrown'], 3);
    expect(s['totalScoredPoints'], 0);
    expect(s['threeDartAverage'], 0.0);
  });

  test('SB and DB count correctly (25 / 50)', () {
    engine.init(_ctx());
    engine.apply(_dart('p1', 25, 1, seq: 1)); // SB
    engine.apply(_dart('p1', 25, 2, seq: 2)); // DB
    engine.apply(_dart('p1', 0, 1, seq: 3));  // MISS
    engine.apply(_turnEnded('p1', seq: 4));
    expect(engine.snapshot()['totalScoredPoints'], 75);
  });

  test('two-turn average accumulates correctly', () {
    engine.init(_ctx());
    // Turn 1: T20+T20+T20 = 180
    for (var i = 0; i < 3; i++) {
      engine.apply(_dart('p1', 20, 3, seq: i));
    }
    engine.apply(_turnEnded('p1', seq: 4));
    // Turn 2: 20+20+20 = 60
    for (var i = 0; i < 3; i++) {
      engine.apply(_dart('p1', 20, 1, seq: 5 + i));
    }
    engine.apply(_turnEnded('p1', seq: 8));
    final s = engine.snapshot();
    expect(s['totalDartsThrown'], 6);
    expect(s['totalScoredPoints'], 240);
    // (240 / 6) * 3 = 120
    expect(s['threeDartAverage'], 120.0);
  });

  test('reset(turn) clears in-flight turn score but not committed total', () {
    engine.init(_ctx());
    engine.apply(_dart('p1', 20, 1, seq: 1));
    engine.apply(_turnEnded('p1', seq: 2));
    expect(engine.snapshot()['totalScoredPoints'], 20);
    engine.apply(_dart('p1', 20, 1, seq: 3));
    engine.reset(ProjectionScope.turn);
    engine.apply(_turnEnded('p1', seq: 4));
    // The dart thrown after the prior TurnEnded was 20 points but reset
    // wiped the in-flight turn — so the second TurnEnded contributes 0.
    expect(engine.snapshot()['totalScoredPoints'], 20);
  });
}
