import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_best_game_checkout_percentage_projection.dart';

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
      gameType: GameType.x01,
      inStrategy: 'straight',
      outStrategy: 'double',
      playerIds: ['p1', 'p2'],
    );

// Helpers to build a game sequence
GameEvent _turnStarted(int score, int seq) =>
    _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': score}, seq: seq);

GameEvent _legCompleted(String winner, int seq) =>
    _makeEvent('LegCompleted', {'winner_player_id': winner}, seq: seq);

GameEvent _gameCompleted(int seq) =>
    _makeEvent('GameCompleted', {'winner_competitor_id': 'comp-1'}, seq: seq);

void main() {
  late X01BestGameCheckoutPercentageProjection engine;

  setUp(() {
    engine = X01BestGameCheckoutPercentageProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces null bestGameCheckoutPercentage', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — single game 1 attempt 1 success → 100%', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(40, 1));    // attempt
    engine.apply(_legCompleted('p1', 2)); // success
    engine.apply(_gameCompleted(3));
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('B1 — single game 2 attempts 1 success → 50%', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(40, 1));    // attempt
    engine.apply(_turnStarted(40, 2));    // attempt (missed checkout, try again)
    engine.apply(_legCompleted('p1', 3)); // 1 success
    engine.apply(_gameCompleted(4));
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(50.0, 0.001));
  });

  test('B1 — TurnStarted with score > 170 not counted as attempt', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(171, 1)); // NOT an attempt
    engine.apply(_turnStarted(40, 2));  // attempt
    engine.apply(_legCompleted('p1', 3));
    engine.apply(_gameCompleted(4));
    // 1 attempt, 1 success → 100%
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('B1 — score exactly 170 counts as attempt', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(170, 1));
    engine.apply(_legCompleted('p1', 2));
    engine.apply(_gameCompleted(3));
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('B2 — LegCompleted won by other player does not count as success', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(40, 1));
    engine.apply(_legCompleted('p2', 2)); // p2 wins
    engine.apply(_gameCompleted(3));
    // 1 attempt, 0 success → 0% (but that IS the best for this game)
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(0.0, 0.001));
  });

  test('B2 — other player TurnStarted not counted as attempt', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p2', 'starting_score': 40}, seq: 1));
    engine.apply(_legCompleted('p1', 2));
    engine.apply(_gameCompleted(3));
    // 0 attempts → no game CO% computed; best remains null
    expect(engine.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — best of two games keeps higher value', () {
    engine.init(_makeContext());
    // Game 1: 2 attempts, 1 success → 50%
    engine.apply(_turnStarted(40, 1));
    engine.apply(_turnStarted(40, 2));
    engine.apply(_legCompleted('p1', 3));
    engine.apply(_gameCompleted(4));

    // Game 2: 1 attempt, 1 success → 100%
    engine.apply(_turnStarted(40, 5));
    engine.apply(_legCompleted('p1', 6));
    engine.apply(_gameCompleted(7));

    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  test('C1 — game with 0 attempts does not affect best', () {
    engine.init(_makeContext());
    // Game 1: 1 attempt, 1 success → 100%
    engine.apply(_turnStarted(40, 1));
    engine.apply(_legCompleted('p1', 2));
    engine.apply(_gameCompleted(3));

    // Game 2: no checkout attempts (only scores > 170)
    engine.apply(_turnStarted(200, 4));
    engine.apply(_gameCompleted(5)); // ignored since 0 attempts

    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D2 — reset(match) clears game counters', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(40, 1));
    engine.apply(_legCompleted('p1', 2));
    engine.reset(ProjectionScope.match);
    // After reset, game counters are cleared; GameCompleted would see 0 attempts
    engine.apply(_gameCompleted(3));
    // No attempts recorded after reset → best should remain null
    // (but the leg success already processed before reset — this tests that
    // reset clears in-progress game state)
    expect(engine.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay from zero yields same result', () {
    final evts = [
      _turnStarted(40, 1),
      _turnStarted(40, 2),
      _legCompleted('p1', 3),
      _gameCompleted(4),
    ];
    engine.init(_makeContext());
    for (final e in evts) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in evts) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream without GameCompleted: no best recorded', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(40, 1));
    engine.apply(_legCompleted('p1', 2));
    // No GameCompleted — best not finalised yet
    expect(engine.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01BestGameCheckoutPercentageProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_turnStarted(40, 1));
    engine.apply(_legCompleted('p1', 2));
    engine.apply(_gameCompleted(3));
    expect(e2.snapshot()['bestGameCheckoutPercentage'], isNull);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 100 games processed without issue', () {
    engine.init(_makeContext());
    int seq = 1;
    for (int i = 0; i < 100; i++) {
      engine.apply(_turnStarted(40, seq++));
      engine.apply(_legCompleted('p1', seq++));
      engine.apply(_gameCompleted(seq++));
    }
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });

  // ── GS1/GS2/GS3 ───────────────────────────────────────────────────────────

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
    engine.apply(_turnStarted(40, 1));
    engine.apply(_legCompleted('p1', 2));
    engine.apply(_gameCompleted(3));

    // Apply 2 more TurnStarted events (next game in progress)
    engine.apply(_turnStarted(40, 4));
    engine.apply(_turnStarted(40, 5));
    // Before GameCompleted, game counters should reflect only post-reset state
    // Apply GameCompleted with 2 attempts, 0 success → 0%
    engine.apply(_gameCompleted(6));

    // bestGameCo should still be 100 (from game 1)
    expect(engine.snapshot()['bestGameCheckoutPercentage'], closeTo(100.0, 0.001));
  });
}
