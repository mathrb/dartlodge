import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_best_game_checkout_percentage_projection.dart';

// #637: attempts use the per-visit "reached-a-finish" definition (isOnAFinish),
// not "every visit ≤170". These tests drive full visits.

int _seq = 0;

GameEvent _makeEvent(String type, Map<String, dynamic> payload) => GameEvent(
      eventId: 'evt-${_seq}-$type',
      gameId: 'game-1',
      eventType: type,
      localSequence: _seq++,
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
    );

void _visit(
  X01BestGameCheckoutPercentageProjection e,
  int startingScore,
  List<int> dartScores, {
  String playerId = 'p1',
  String reason = 'normal',
}) {
  e.apply(_makeEvent(
      'TurnStarted', {'player_id': playerId, 'starting_score': startingScore}));
  for (final d in dartScores) {
    e.apply(_makeEvent('DartThrown', {'player_id': playerId, 'score': d}));
  }
  e.apply(_makeEvent('TurnEnded', {'player_id': playerId, 'reason': reason}));
}

void _legCompleted(X01BestGameCheckoutPercentageProjection e, String winner) =>
    e.apply(_makeEvent('LegCompleted', {'winner_player_id': winner}));

void _gameCompleted(X01BestGameCheckoutPercentageProjection e) =>
    e.apply(_makeEvent('GameCompleted', {'winner_competitor_id': 'comp-1'}));

void main() {
  late X01BestGameCheckoutPercentageProjection engine;

  setUp(() {
    _seq = 0;
    engine = X01BestGameCheckoutPercentageProjection();
  });

  test('A1 — init produces null bestGameCheckoutPercentage', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  test('B1 — single game 1 attempt 1 success → 100%', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('B1 — two finishing visits, 1 success → 50%', () {
    engine.init(_makeContext());
    _visit(engine, 40, [60], reason: 'bust'); // attempt, no win
    _visit(engine, 40, [40]); // checkout
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(50.0, 0.001));
  });

  test('B1 — setup-only visit does not dilute the denominator', () {
    engine.init(_makeContext());
    _visit(engine, 200, [60]); // not a finish → not an attempt
    _visit(engine, 40, [40]); // checkout
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    // 1 attempt, 1 success → 100%
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('B2 — LegCompleted won by other player is not a success', () {
    engine.init(_makeContext());
    _visit(engine, 40, [60], reason: 'bust'); // attempt
    _legCompleted(engine, 'p2');
    _gameCompleted(engine);
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(0.0, 0.001));
  });

  test('B2 — other player\'s visit is not an attempt', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40], playerId: 'p2');
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    // 0 attempts → no game CO% computed; best remains null
    expect(engine.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  test('C1 — best of two games keeps higher value', () {
    engine.init(_makeContext());
    // Game 1: 2 attempts, 1 success → 50%
    _visit(engine, 40, [60], reason: 'bust');
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    // Game 2: 1 attempt, 1 success → 100%
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('C1 — game with 0 attempts does not affect best', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    // Game 2: only non-finishing visits.
    _visit(engine, 200, [60]);
    _gameCompleted(engine);
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('D2 — reset(match) clears in-progress game counters', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    engine.reset(ProjectionScope.match);
    _gameCompleted(engine); // sees 0 attempts after reset
    expect(engine.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  test('E1 — replay from zero yields same result', () {
    Map<String, dynamic> run() {
      _seq = 0;
      final e = X01BestGameCheckoutPercentageProjection()..init(_makeContext());
      _visit(e, 40, [60], reason: 'bust');
      _visit(e, 40, [40]);
      _legCompleted(e, 'p1');
      _gameCompleted(e);
      return e.snapshot();
    }

    expect(run(), run());
  });

  test('F1 — partial stream without GameCompleted: no best recorded', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    expect(engine.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  test('G2 — two instances do not share state', () {
    final e2 = X01BestGameCheckoutPercentageProjection()..init(_makeContext());
    engine.init(_makeContext());
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    expect(e2.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  test('H1 — 100 games processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 100; i++) {
      _visit(engine, 40, [40]);
      _legCompleted(engine, 'p1');
      _gameCompleted(engine);
    }
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('GS1 — descriptor declares only x01', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes, equals({GameType.x01}));
  });

  test('GS2 — cricket not in supported game types', () {
    expect(engine.descriptor.supportedGameTypes.contains(GameType.cricket), isFalse);
  });

  test('GS3 — game counters reset after GameCompleted', () {
    engine.init(_makeContext());
    // Game 1: 100%
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    _gameCompleted(engine);
    // Game 2: 2 attempts, 0 success → 0% (does not lower the best).
    _visit(engine, 40, [60], reason: 'bust');
    _visit(engine, 40, [60], reason: 'bust');
    _gameCompleted(engine);
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });
}
