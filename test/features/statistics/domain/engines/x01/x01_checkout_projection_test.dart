import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_checkout_projection.dart';

// #637: an ATTEMPT is a visit in which the player threw ≥1 dart from a
// single-dart finish position (isOnAFinish for the out strategy); a SUCCESS is a
// LegCompleted won by the player. The attempt is tallied on the player's
// TurnEnded. These tests drive full visits (TurnStarted → DartThrown… →
// TurnEnded) rather than bare TurnStarted events.

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

ProjectionContext _makeContext({
  String playerId = 'p1',
  String outStrategy = 'double',
}) =>
    ProjectionContext(
      playerId: playerId,
      gameType: GameType.x01,
      inStrategy: 'straight',
      outStrategy: outStrategy,
    );

/// Applies one full visit for [playerId]: TurnStarted(startingScore) → a
/// DartThrown per entry in [dartScores] → TurnEnded(reason).
void _visit(
  X01CheckoutProjection e,
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

void _legCompleted(X01CheckoutProjection e, String winner) =>
    e.apply(_makeEvent('LegCompleted', {'winner_player_id': winner}));

void main() {
  late X01CheckoutProjection engine;

  setUp(() {
    _seq = 0;
    engine = X01CheckoutProjection();
  });

  // ── Category A — init ───────────────────────────────────────────────────────

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

  // ── Category B — basic attempt / success ────────────────────────────────────

  test('B1 — a visit that throws from a double-finish counts as an attempt', () {
    engine.init(_makeContext());
    // 40 (D20) is a finish: the dart is thrown from a finish position.
    _visit(engine, 40, [40], reason: 'normal');
    expect(engine.snapshot()['checkoutAttempts'], 1);
  });

  test('B1 — leg-winning visit is an attempt + a success', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40]); // checkout
    _legCompleted(engine, 'p1');
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 1);
    expect(s['successfulCheckouts'], 1);
    expect(s['checkoutPercentage'], closeTo(100.0, 0.001));
  });

  test('B2 — setup-only visit (no dart from a finish) is NOT an attempt', () {
    engine.init(_makeContext());
    // 170 → T19(57), T18(54) leaves 59; neither 170 nor 113 is a finish.
    _visit(engine, 170, [57, 54], reason: 'normal');
    expect(engine.snapshot()['checkoutAttempts'], 0);
  });

  test('B2 — bogey-number visit (169) with setup darts is NOT an attempt', () {
    engine.init(_makeContext());
    // 169 → 3,3,3 leaves 160; never reaches a single-dart finish.
    _visit(engine, 169, [3, 3, 3], reason: 'normal');
    expect(engine.snapshot()['checkoutAttempts'], 0);
  });

  test('B2 — other player\'s visit is ignored', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40], playerId: 'p2');
    _legCompleted(engine, 'p2');
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 0);
    expect(s['successfulCheckouts'], 0);
  });

  // ── Category C — multi-visit leg / percentage ───────────────────────────────

  test('C1 — multi-visit leg counts ONE attempt, not three', () {
    engine.init(_makeContext());
    // 170 → setup, leaves 59 (no finish dart).
    _visit(engine, 170, [57, 54]);
    // 59 → S19(19) leaves 40 (no finish dart: 59 not a finish).
    _visit(engine, 59, [19]);
    // 40 → D20 checkout (finish dart).
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 1, reason: 'only the final visit threw at a finish');
    expect(s['successfulCheckouts'], 1);
    expect(s['checkoutPercentage'], closeTo(100.0, 0.001));
  });

  test('C2 — two finishing visits, one win → 50%', () {
    engine.init(_makeContext());
    _visit(engine, 40, [60], reason: 'bust'); // threw at 40, busted → attempt, no win
    _visit(engine, 40, [40]); // checkout
    _legCompleted(engine, 'p1');
    expect(engine.snapshot()['checkoutPercentage'], closeTo(50.0, 0.001));
  });

  // ── Bust handling ───────────────────────────────────────────────────────────

  test('Bust1 — busting FROM a finish position counts as an attempt', () {
    engine.init(_makeContext());
    // 40 (finish) → T20(60) busts; the dart was thrown from a finish position.
    _visit(engine, 40, [60], reason: 'bust');
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 1);
    expect(s['successfulCheckouts'], 0);
  });

  // ── Category D — reset ──────────────────────────────────────────────────────

  test('D1/D2 — reset(turn/leg) keeps cumulative counters', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40]);
    _legCompleted(engine, 'p1');
    engine.reset(ProjectionScope.turn);
    engine.reset(ProjectionScope.leg);
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 1);
    expect(s['successfulCheckouts'], 1);
  });

  // ── Category E — replay determinism ─────────────────────────────────────────

  test('E1 — replay from zero yields same result', () {
    Map<String, dynamic> run() {
      _seq = 0;
      final e = X01CheckoutProjection()..init(_makeContext());
      _visit(e, 170, [57, 54]);
      _visit(e, 40, [40]);
      _legCompleted(e, 'p1');
      return e.snapshot();
    }

    expect(run(), run());
  });

  // ── Category F — partial stream ─────────────────────────────────────────────

  test('F1 — partial stream without LegCompleted is valid', () {
    engine.init(_makeContext());
    _visit(engine, 40, [40]); // attempt, no win yet
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 1);
    expect(s['successfulCheckouts'], 0);
    expect(s['checkoutPercentage'], 0.0);
  });

  test('Rat1 — division by zero safe when no attempts', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['checkoutPercentage'], isNull);
  });

  test('Seed1 — DartThrown with no TurnStarted seed is skipped', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 40}));
    engine.apply(_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}));
    expect(engine.snapshot()['checkoutAttempts'], 0);
  });

  // ── Category G — isolation ──────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01CheckoutProjection()..init(_makeContext());
    engine.init(_makeContext());
    _visit(engine, 40, [40]);
    expect(e2.snapshot()['checkoutAttempts'], 0);
  });

  // ── Category H — scale ──────────────────────────────────────────────────────

  test('H1 — 1000 legs processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 1000; i++) {
      _visit(engine, 40, [40]);
      _legCompleted(engine, 'p1');
    }
    final s = engine.snapshot();
    expect(s['checkoutAttempts'], 1000);
    expect(s['successfulCheckouts'], 1000);
  });

  // ── Out-strategy aware finish (#637) ────────────────────────────────────────

  test('GS3 — straight-out counts a single finish that double-out ignores', () {
    final dbl = X01CheckoutProjection()..init(_makeContext(outStrategy: 'double'));
    final str =
        X01CheckoutProjection()..init(_makeContext(outStrategy: 'straight'));
    // 17 is a single-dart finish (S17) but NOT a double finish.
    void scenario(X01CheckoutProjection e) => _visit(e, 17, [17]);
    _seq = 0;
    scenario(dbl);
    _seq = 0;
    scenario(str);
    expect(dbl.snapshot()['checkoutAttempts'], 0);
    expect(str.snapshot()['checkoutAttempts'], 1);
  });

  test('GS3b — master-out counts a triple finish that double-out ignores', () {
    final dbl = X01CheckoutProjection()..init(_makeContext(outStrategy: 'double'));
    final mas =
        X01CheckoutProjection()..init(_makeContext(outStrategy: 'master'));
    // 57 (T19) is a triple finish but NOT a double finish.
    void scenario(X01CheckoutProjection e) => _visit(e, 57, [57]);
    _seq = 0;
    scenario(dbl);
    _seq = 0;
    scenario(mas);
    expect(dbl.snapshot()['checkoutAttempts'], 0);
    expect(mas.snapshot()['checkoutAttempts'], 1);
  });

  // ── Descriptor ──────────────────────────────────────────────────────────────

  test('GS1 — descriptor declares only x01 and consumes the visit events', () {
    expect(engine.descriptor.supportedGameTypes, equals({GameType.x01}));
    expect(
      engine.descriptor.consumedEventTypes,
      containsAll(<String>{'TurnStarted', 'DartThrown', 'TurnEnded', 'LegCompleted'}),
    );
  });

  test('GS2 — cricket not in supported game types', () {
    expect(engine.descriptor.supportedGameTypes.contains(GameType.cricket), isFalse);
  });
}
