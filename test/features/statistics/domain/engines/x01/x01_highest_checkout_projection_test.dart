import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';
import 'package:my_darts/features/statistics/domain/engines/x01/x01_highest_checkout_projection.dart';

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

// Helper: apply TurnStarted then LegCompleted for a winning checkout turn
void _applyWinningLeg(
  X01HighestCheckoutProjection engine,
  int startingScore, {
  int seq = 1,
  String winner = 'p1',
}) {
  engine.apply(_makeEvent('TurnStarted',
      {'player_id': winner, 'starting_score': startingScore}, seq: seq));
  engine.apply(_makeEvent('LegCompleted', {'winner_player_id': winner}, seq: seq + 1));
}

void main() {
  late X01HighestCheckoutProjection engine;

  setUp(() {
    engine = X01HighestCheckoutProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces null highestCheckout', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['highestCheckout'], isNull);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — TurnStarted + LegCompleted with winning player updates highest', () {
    engine.init(_makeContext());
    _applyWinningLeg(engine, 120);
    expect(engine.snapshot()['highestCheckout'], 120);
  });

  test('B2 — DartThrown ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['highestCheckout'], isNull);
  });

  test('B2 — LegCompleted for other player ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted',
        {'player_id': 'p2', 'starting_score': 170}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 2));
    expect(engine.snapshot()['highestCheckout'], isNull);
  });

  test('B2 — TurnStarted for other player does not affect own checkout', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted',
        {'player_id': 'p2', 'starting_score': 170}, seq: 1));
    engine.apply(_makeEvent('TurnStarted',
        {'player_id': 'p1', 'starting_score': 120}, seq: 2));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3));
    expect(engine.snapshot()['highestCheckout'], 120);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — highest of multiple legs is tracked', () {
    engine.init(_makeContext());
    _applyWinningLeg(engine, 40, seq: 1);
    _applyWinningLeg(engine, 120, seq: 3);
    _applyWinningLeg(engine, 80, seq: 5);
    expect(engine.snapshot()['highestCheckout'], 120);
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01HighestCheckoutProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 100}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2),
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 3),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 4),
    ];
    for (final e in events) {
      engine.apply(e);
      e2.apply(e);
    }
    expect(engine.snapshot(), e2.snapshot());
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D3 — reset(match) is a no-op (cumulative career stat)', () {
    engine.init(_makeContext());
    _applyWinningLeg(engine, 170, seq: 1);
    engine.reset(ProjectionScope.match);
    expect(engine.snapshot()['highestCheckout'], 170);
  });

  test('D1 — reset(turn) is a no-op', () {
    engine.init(_makeContext());
    _applyWinningLeg(engine, 80, seq: 1);
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['highestCheckout'], 80);
  });

  test('D2 — reset(leg) is a no-op', () {
    engine.init(_makeContext());
    _applyWinningLeg(engine, 80, seq: 1);
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['highestCheckout'], 80);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay yields same snapshot', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 60}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2),
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 140}, seq: 3),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 4),
    ];
    for (final e in events) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in events) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  test('Ext3 — replay after correction can lower highest (re-init yields fresh state)', () {
    engine.init(_makeContext());
    _applyWinningLeg(engine, 140, seq: 1);
    // Correction: re-init with only lower checkout
    engine.init(_makeContext());
    _applyWinningLeg(engine, 60, seq: 1);
    expect(engine.snapshot()['highestCheckout'], 60);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F2 — no LegCompleted returns null', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}));
    expect(engine.snapshot()['highestCheckout'], isNull);
  });

  test('F3 — partial match (no GameCompleted) is valid', () {
    engine.init(_makeContext());
    _applyWinningLeg(engine, 80, seq: 1);
    expect(engine.snapshot()['highestCheckout'], 80);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01HighestCheckoutProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    _applyWinningLeg(engine, 100, seq: 1);
    expect(e2.snapshot()['highestCheckout'], isNull);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 1000 leg events processed correctly', () {
    engine.init(_makeContext());
    for (int i = 1; i <= 1000; i++) {
      engine.apply(_makeEvent('TurnStarted',
          {'player_id': 'p1', 'starting_score': i}, seq: i * 2 - 1));
      engine.apply(_makeEvent('LegCompleted',
          {'winner_player_id': 'p1'}, seq: i * 2));
    }
    expect(engine.snapshot()['highestCheckout'], 1000);
  });

  // ── GS1/GS2 ───────────────────────────────────────────────────────────────

  test('GS1 — descriptor declares only x01', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes, equals({GameType.x01}));
  });

  test('GS2 — cricket not in supported game types', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes.contains(GameType.cricket), isFalse);
  });
}
