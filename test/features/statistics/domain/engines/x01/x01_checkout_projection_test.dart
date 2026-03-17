import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_checkout_projection.dart';

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

ProjectionContext _makeContext({
  String playerId = 'p1',
  String outStrategy = 'double',
}) =>
    ProjectionContext(
      playerId: playerId,
      gameType: GameType.x01,
      inStrategy: 'straight',
      outStrategy: outStrategy,
      playerIds: ['p1', 'p2'],
    );

void main() {
  late X01CheckoutProjection engine;

  setUp(() {
    engine = X01CheckoutProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces null checkoutPercentage and zero counters', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['checkoutPercentage'], isNull);
    expect(s['checkoutAttempts'], 0);
    expect(s['successfulCheckouts'], 0);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — TurnStarted with score ≤ 170 increments attempts', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent(
        'TurnStarted', {'player_id': 'p1', 'starting_score': 170}));
    expect(engine.snapshot()['checkoutAttempts'], 1);
  });

  test('B1 — TurnStarted with score > 170 does not increment', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent(
        'TurnStarted', {'player_id': 'p1', 'starting_score': 171}));
    expect(engine.snapshot()['checkoutAttempts'], 0);
  });

  test('B1 — LegCompleted with matching winner increments successes', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent(
        'TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.apply(_makeEvent(
        'LegCompleted', {'winner_player_id': 'p1', 'checkout_score': 40}, seq: 2));
    expect(engine.snapshot()['successfulCheckouts'], 1);
  });

  test('B2 — DartThrown ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 40}));
    expect(engine.snapshot()['checkoutAttempts'], 0);
  });

  test('B2 — other player TurnStarted ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent(
        'TurnStarted', {'player_id': 'p2', 'starting_score': 40}));
    expect(engine.snapshot()['checkoutAttempts'], 0);
  });

  test('B2 — other player LegCompleted does not count success', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent(
        'TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.apply(_makeEvent(
        'LegCompleted', {'winner_player_id': 'p2', 'checkout_score': 40}, seq: 2));
    expect(engine.snapshot()['successfulCheckouts'], 0);
    expect(engine.snapshot()['checkoutAttempts'], 1);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — checkout percentage is correct', () {
    engine.init(_makeContext());
    // 2 attempts, 1 success
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 2));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1', 'checkout_score': 40}, seq: 3));
    expect(engine.snapshot()['checkoutPercentage'], closeTo(50.0, 0.001));
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01CheckoutProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1', 'checkout_score': 40}, seq: 2),
    ];
    for (final e in events) {
      engine.apply(e);
      e2.apply(e);
    }
    expect(engine.snapshot(), e2.snapshot());
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D2 — reset(leg) is a no-op (cumulative career stat)', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1', 'checkout_score': 40}, seq: 2));
    engine.reset(ProjectionScope.leg);
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 1);
    expect(s['successfulCheckouts'], 1);
    expect(s['checkoutPercentage'], 100.0);
  });

  test('D1 — reset(turn) is a no-op', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['checkoutAttempts'], 1);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay from zero yields same result', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1),
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 2),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1', 'checkout_score': 40}, seq: 3),
    ];
    for (final e in events) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in events) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream without LegCompleted is valid', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 1);
    expect(s['successfulCheckouts'], 0);
    expect(s['checkoutPercentage'], 0.0);
  });

  test('Rat1 — division by zero safe when no attempts', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['checkoutPercentage'], isNull);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01CheckoutProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}));
    expect(e2.snapshot()['checkoutAttempts'], 0);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 1000 legs processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 1000; i++) {
      engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: i * 2));
      engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1', 'checkout_score': 40}, seq: i * 2 + 1));
    }
    // Cumulative — all 1000 attempts and successes are retained
    expect(engine.snapshot()['checkoutAttempts'], 1000);
    expect(engine.snapshot()['successfulCheckouts'], 1000);
  });

  // ── GS1/GS2/GS3 ───────────────────────────────────────────────────────────

  test('GS1 — descriptor declares only x01', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes, equals({GameType.x01}));
  });

  test('GS2 — cricket not in supported game types', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes.contains(GameType.cricket), isFalse);
  });

  test('GS3 — same events with different outStrategy context yields valid snapshot', () {
    // The checkout projection counts attempts regardless of outStrategy;
    // the outStrategy affects the game engine's validation, not the projection counting.
    // Both contexts should show same attempt/success counts.
    final engine1 = X01CheckoutProjection();
    final engine2 = X01CheckoutProjection();
    engine1.init(_makeContext(outStrategy: 'double'));
    engine2.init(_makeContext(outStrategy: 'straight'));
    final events = [
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1', 'checkout_score': 40}, seq: 2),
    ];
    for (final e in events) {
      engine1.apply(e);
      engine2.apply(e);
    }
    // Both record the same checkout attempt and success
    expect(engine1.snapshot()['checkoutAttempts'],
        engine2.snapshot()['checkoutAttempts']);
    expect(engine1.snapshot()['successfulCheckouts'],
        engine2.snapshot()['successfulCheckouts']);
  });
}
