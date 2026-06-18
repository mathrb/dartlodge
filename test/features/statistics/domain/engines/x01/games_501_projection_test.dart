import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_runner.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/games_501_projection.dart';

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

ProjectionContext _ctx() => const ProjectionContext(
      playerId: 'p1',
      gameType: GameType.x01,
      inStrategy: 'straight',
      outStrategy: 'double',
    );

/// A completed X01 game with the given [startingScore].
List<GameEvent> _game(int startingScore, {String gameId = 'g1', bool completed = true}) =>
    [
      _ev('TurnStarted', {'player_id': 'p1', 'starting_score': startingScore},
          gameId: gameId),
      _ev('DartThrown',
          {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60},
          gameId: gameId),
      _ev('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, gameId: gameId),
      if (completed)
        _ev('GameCompleted', {'winner_player_id': 'p1'}, gameId: gameId),
    ];

int _run(List<GameEvent> events) {
  final runner = ProjectionRunner([Games501Projection()])..init(_ctx());
  runner.run(events);
  return runner.snapshot()['x01.games501']!['games501Played'] as int;
}

void main() {
  setUp(() => _seq = 0);

  test('a completed 501 game counts', () {
    expect(_run(_game(501)), 1);
  });

  test('a 301 game does not count', () {
    expect(_run(_game(301)), 0);
  });

  test('two completed 501 games count 2', () {
    expect(_run([..._game(501, gameId: 'g1'), ..._game(501, gameId: 'g2')]), 2);
  });

  test('a 501 game with no GameCompleted does not count', () {
    expect(_run(_game(501, completed: false)), 0);
  });

  test('mixed 501 and 301 games count only the 501s', () {
    expect(
      _run([
        ..._game(501, gameId: 'g1'),
        ..._game(301, gameId: 'g2'),
        ..._game(501, gameId: 'g3'),
      ]),
      2,
    );
  });

  test('descriptor declares only x01', () {
    expect(Games501Projection().descriptor.supportedGameTypes,
        equals({GameType.x01}));
  });
}
