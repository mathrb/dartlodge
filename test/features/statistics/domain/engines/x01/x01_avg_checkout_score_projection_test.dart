import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_avg_checkout_score_projection.dart';

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

void main() {
  late X01AvgCheckoutScoreProjection engine;

  setUp(() {
    engine = X01AvgCheckoutScoreProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces null avgCheckoutScore', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['avgCheckoutScore'], isNull);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — single checkout records starting score', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 32}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(32.0, 0.001));
  });

  test('B1 — two checkouts compute mean', () {
    engine.init(_makeContext());
    // First leg: checkout 40
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    // Second leg: checkout 80
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 80}, seq: 3));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 4));
    // Mean = (40+80)/2 = 60.0
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(60.0, 0.001));
  });

  test('B2 — LegCompleted won by other player does not count', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 2));
    expect(engine.snapshot()['avgCheckoutScore'], isNull);
  });

  test('B2 — TurnStarted for other player does not affect cached score', () {
    engine.init(_makeContext());
    // p2's TurnStarted should not affect p1's cached score
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p2', 'starting_score': 100}, seq: 1));
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 2));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3));
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(40.0, 0.001));
  });

  test('B1 — uses last TurnStarted for player before LegCompleted', () {
    engine.init(_makeContext());
    // Two consecutive TurnStarted for p1; the second one is the checkout turn
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 100}, seq: 1));
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 2));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3));
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(40.0, 0.001));
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — average of many checkouts is correct', () {
    engine.init(_makeContext());
    final scores = [20, 40, 60, 80, 100];
    int seq = 1;
    for (final s in scores) {
      engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': s}, seq: seq++));
      engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: seq++));
    }
    final expected = scores.reduce((a, b) => a + b) / scores.length;
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(expected, 0.001));
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D2 — reset(leg) is a no-op (career stat)', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(40.0, 0.001));
  });

  test('D1 — reset(turn) is a no-op', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.reset(ProjectionScope.turn);
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(40.0, 0.001));
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay from zero yields same result', () {
    final evts = [
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2),
      _makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 60}, seq: 3),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 4),
    ];
    engine.init(_makeContext());
    for (final e in evts) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in evts) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream without LegCompleted: null', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    expect(engine.snapshot()['avgCheckoutScore'], isNull);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01AvgCheckoutScoreProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 40}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    expect(e2.snapshot()['avgCheckoutScore'], isNull);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 1000 checkouts processed without issue', () {
    engine.init(_makeContext());
    int seq = 1;
    for (int i = 0; i < 1000; i++) {
      engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 50}, seq: seq++));
      engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: seq++));
    }
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(50.0, 0.001));
  });

  // ── GS1/GS2/GS3 ───────────────────────────────────────────────────────────

  test('GS1 — descriptor declares only x01', () {
    engine.init(_makeContext());
    expect(engine.descriptor.supportedGameTypes, equals({GameType.x01}));
  });

  test('GS2 — cricket not in supported game types', () {
    expect(engine.descriptor.supportedGameTypes.contains(GameType.cricket), isFalse);
  });

  test('GS3 — null-safe: no crash when starting_score is absent from payload', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('TurnStarted', {'player_id': 'p1'}, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    // Should record 0 (default) as checkout score
    expect(engine.snapshot()['avgCheckoutScore'], closeTo(0.0, 0.001));
  });
}
