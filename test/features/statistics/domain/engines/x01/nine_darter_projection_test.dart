import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_runner.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/nine_darter_projection.dart';

int _seq = 0;
GameEvent _ev(String type, Map<String, dynamic> payload,
        {String gameId = 'g1'}) =>
    GameEvent(
      eventId: 'evt-${_seq}-$type',
      gameId: gameId,
      eventType: type,
      localSequence: ++_seq,
      occurredAt: DateTime(2024),
      payload: payload,
      synced: false,
      actorId: 'p1',
      source: EventSource.client,
    );

ProjectionContext _ctx({String playerId = 'p1'}) => ProjectionContext(
      playerId: playerId,
      gameType: GameType.x01,
      inStrategy: 'straight',
      outStrategy: 'double',
    );

/// Emits a [dartCount]-dart leg for [player] split into 3-dart turns, with the
/// per-turn `starting_score` decreasing from [startingScore]; ends with a
/// LegCompleted won by [winner].
List<GameEvent> _leg({
  required int startingScore,
  required int dartCount,
  String player = 'p1',
  String winner = 'p1',
  String gameId = 'g1',
}) {
  final events = <GameEvent>[];
  var remaining = startingScore;
  var thrown = 0;
  while (thrown < dartCount) {
    events.add(_ev('TurnStarted',
        {'player_id': player, 'starting_score': remaining}, gameId: gameId));
    for (var d = 0; d < 3 && thrown < dartCount; d++) {
      events.add(_ev('DartThrown',
          {'player_id': player, 'segment': 20, 'multiplier': 3, 'score': 60},
          gameId: gameId));
      thrown++;
    }
    events.add(_ev('TurnEnded', {'player_id': player, 'reason': 'normal'},
        gameId: gameId));
    remaining -= 180;
  }
  events.add(
      _ev('LegCompleted', {'winner_player_id': winner}, gameId: gameId));
  return events;
}

Map<String, dynamic> _run(List<GameEvent> events, {String playerId = 'p1'}) {
  final runner = ProjectionRunner([NineDarterProjection()])..init(_ctx(playerId: playerId));
  runner.run(events);
  return runner.snapshot()['x01.nineDarter']!;
}

void main() {
  setUp(() => _seq = 0);

  test('501 leg won in 9 darts → hasNineDarter, count 1', () {
    final snap = _run(_leg(startingScore: 501, dartCount: 9));
    expect(snap['hasNineDarter'], isTrue);
    expect(snap['nineDarterCount'], 1);
  });

  test('501 leg won in 12 darts → not a nine-darter', () {
    final snap = _run(_leg(startingScore: 501, dartCount: 12));
    expect(snap['hasNineDarter'], isFalse);
    expect(snap['nineDarterCount'], 0);
  });

  test('9 darts but starting score 301 → not a nine-darter', () {
    final snap = _run(_leg(startingScore: 301, dartCount: 9));
    expect(snap['hasNineDarter'], isFalse);
  });

  test('9 darts but the leg was won by the opponent → not counted', () {
    final snap = _run(_leg(startingScore: 501, dartCount: 9, winner: 'p2'));
    expect(snap['hasNineDarter'], isFalse);
  });

  test('two 9-darters across two games → count 2 (per-leg reset works)', () {
    final events = [
      ..._leg(startingScore: 501, dartCount: 9, gameId: 'g1'),
      ..._leg(startingScore: 501, dartCount: 9, gameId: 'g2'),
    ];
    final snap = _run(events);
    expect(snap['hasNineDarter'], isTrue);
    expect(snap['nineDarterCount'], 2);
  });

  test('a 12-dart leg before a 9-dart leg does not leak darts across legs', () {
    final events = [
      ..._leg(startingScore: 501, dartCount: 12, gameId: 'g1'),
      ..._leg(startingScore: 501, dartCount: 9, gameId: 'g2'),
    ];
    final snap = _run(events);
    expect(snap['nineDarterCount'], 1);
  });

  test('no events → no nine-darter', () {
    final snap = _run(const []);
    expect(snap['hasNineDarter'], isFalse);
    expect(snap['nineDarterCount'], 0);
  });

  test('descriptor declares only x01', () {
    expect(NineDarterProjection().descriptor.supportedGameTypes,
        equals({GameType.x01}));
  });
}
