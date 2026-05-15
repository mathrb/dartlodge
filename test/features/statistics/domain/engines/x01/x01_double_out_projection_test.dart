import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_double_out_projection.dart';

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

// Helper: emit TurnStarted with starting_score so the projection can
// compute preDartRemaining without the (non-existent) `remaining_after`
// payload key. See #185.
GameEvent _turnStarted({
  required String playerId,
  required int startingScore,
  int seq = 1,
}) =>
    _makeEvent(
      'TurnStarted',
      {
        'player_id': playerId,
        'competitor_id': playerId,
        'starting_score': startingScore,
      },
      seq: seq,
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

void main() {
  late X01DoubleOutProjection engine;

  setUp(() {
    engine = X01DoubleOutProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init with double out produces null rate and zero counters', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['doubleOutSuccessRate'], isNull);
    expect(s['doubleAttempts'], 0);
    expect(s['doubleSuccesses'], 0);
  });

  test('A1 — init with straight out returns empty snapshot', () {
    engine.init(_makeContext(outStrategy: 'straight'));
    expect(engine.snapshot(), isEmpty);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — DartThrown with preDartRemaining ≤ 50 and double segment increments attempts', () {
    engine.init(_makeContext());
    // starting_score=40 → preDartRemaining=40, dart D15 (mult=2) → attempt.
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D15',
      'score': 30,
    }, seq: 2));
    expect(engine.snapshot()['doubleAttempts'], 1);
  });

  test('B1 — DartThrown with preDartRemaining > 50 does not count attempt', () {
    engine.init(_makeContext());
    // starting_score=90 → preDartRemaining=90 > 50.
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 90, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D20',
      'score': 60,
    }, seq: 2));
    expect(engine.snapshot()['doubleAttempts'], 0);
  });

  test('B1 — DartThrown with preDartRemaining ≤ 50 but non-double segment does not count', () {
    engine.init(_makeContext());
    // preDartRemaining=30 (≤50), but multiplier=1 (single).
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 30, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': '20',
      'score': 20,
    }, seq: 2));
    expect(engine.snapshot()['doubleAttempts'], 0);
  });

  test('B1 — LegCompleted with player winning increments successes', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D20',
      'score': 40,
    }, seq: 2));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3));
    expect(engine.snapshot()['doubleSuccesses'], 1);
  });

  test('B2 — other player DartThrown ignored', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(playerId: 'p2', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p2',
      'segment': 'D20',
      'score': 40,
    }, seq: 2));
    expect(engine.snapshot()['doubleAttempts'], 0);
  });

  test('B2 — LegCompleted where other player wins does not increment successes', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}));
    expect(engine.snapshot()['doubleSuccesses'], 0);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — success rate calculates correctly', () {
    engine.init(_makeContext());
    // 2 double attempts, 1 success.
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40,
    }, seq: 2));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 3));
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 4));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40,
    }, seq: 5));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 6));
    expect(engine.snapshot()['doubleAttempts'], 2);
    expect(engine.snapshot()['doubleSuccesses'], 1);
    expect(engine.snapshot()['doubleOutSuccessRate'], closeTo(50.0, 0.001));
  });

  test('C1 — master out: triple segment counts as attempt', () {
    engine.init(_makeContext(outStrategy: 'master'));
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'T10', 'score': 30,
    }, seq: 2));
    expect(engine.snapshot()['doubleAttempts'], 1);
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01DoubleOutProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _turnStarted(playerId: 'p1', startingScore: 40, seq: 1),
      _makeEvent('DartThrown', {
        'player_id': 'p1', 'segment': 'D20', 'score': 40,
      }, seq: 2),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3),
    ];
    for (final e in events) {
      engine.apply(e);
      e2.apply(e);
    }
    expect(engine.snapshot(), e2.snapshot());
  });

  // ── Category D ─────────────────────────────────────────────────────────────

  test('D1 — reset(turn) does not clear counters', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40,
    }, seq: 2));
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['doubleAttempts'], 1);
  });

  test('D2 — reset(leg) does not clear counters (cumulative)', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40,
    }, seq: 2));
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['doubleAttempts'], 1);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay yields identical snapshot', () {
    engine.init(_makeContext());
    final events = [
      _turnStarted(playerId: 'p1', startingScore: 40, seq: 1),
      _makeEvent('DartThrown', {
        'player_id': 'p1', 'segment': 'D20', 'score': 40,
      }, seq: 2),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3),
      _turnStarted(playerId: 'p1', startingScore: 40, seq: 4),
      _makeEvent('DartThrown', {
        'player_id': 'p1', 'segment': 'D20', 'score': 40,
      }, seq: 5),
      _makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 6),
    ];
    for (final e in events) {
      engine.apply(e);
    }
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in events) {
      engine.apply(e);
    }
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream without LegCompleted is valid', () {
    engine.init(_makeContext());
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40,
    }, seq: 2));
    expect(engine.snapshot()['doubleAttempts'], 1);
    expect(engine.snapshot()['doubleSuccesses'], 0);
    expect(engine.snapshot()['doubleOutSuccessRate'], 0.0);
  });

  test('Rat1 — division by zero safe when no attempts', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['doubleOutSuccessRate'], isNull);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01DoubleOutProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40,
    }, seq: 2));
    expect(e2.snapshot()['doubleAttempts'], 0);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 500 double attempts processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 500; i++) {
      engine.apply(
          _turnStarted(playerId: 'p1', startingScore: 40, seq: i * 3));
      engine.apply(_makeEvent('DartThrown', {
        'player_id': 'p1', 'segment': 'D20', 'score': 40,
      }, seq: i * 3 + 1));
      if (i.isEven) {
        engine.apply(_makeEvent('LegCompleted',
            {'winner_player_id': 'p1'}, seq: i * 3 + 2));
      }
    }
    expect(engine.snapshot()['doubleAttempts'], 500);
    expect(engine.snapshot()['doubleSuccesses'], 250);
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

  test('GS3 — straight out context returns empty snapshot', () {
    engine.init(_makeContext(outStrategy: 'straight'));
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 40, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40,
    }, seq: 2));
    expect(engine.snapshot(), isEmpty);
  });

  // ── Regression: #185 ─────────────────────────────────────────────────────

  test('regression #185 — no false positives when remaining_after is absent',
      () {
    // This is the production payload shape: buildDartThrownEvent emits only
    // {competitor_id, player_id, segment, multiplier, score, input_method}
    // — no remaining_after. Pre-fix, the projection assumed
    //   preDartRemaining = (remaining_after ?? -1) + score = score - 1
    // and counted every dart with score <= 51 and multiplier matching the
    // strategy as an attempt. A T20 (score=60) was NOT flagged (60-1=59 > 50),
    // but a D20 (score=40, mult=2) WAS — even when thrown at a remaining of
    // 200 (i.e. nowhere near a checkout).
    //
    // Verify a D20 thrown WITHOUT any preceding TurnStarted is NOT counted.
    // Without the seed the projection can't infer remaining, so the dart is
    // simply skipped — strictly safer than the pre-fix over-counting.
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D20',
      'multiplier': 2,
      'score': 40,
      // intentionally no 'remaining_after'
    }, seq: 1));
    expect(engine.snapshot()['doubleAttempts'], 0,
        reason: 'D20 at unknown remaining must not auto-count');
  });

  test('regression #185 — TurnStarted-seeded attempt counts only when remaining ≤ 50',
      () {
    // Production scenario: player starts a turn at 200 (way over checkout
    // range), throws D20 — should NOT be a double-out attempt despite the
    // double multiplier. Pre-fix this would have counted as an attempt.
    engine.init(_makeContext());
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 200, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D20',
      'multiplier': 2,
      'score': 40,
    }, seq: 2));
    expect(engine.snapshot()['doubleAttempts'], 0,
        reason: 'D20 at 200 remaining is not a checkout attempt');

    // After dart 1, remaining is 200 - 40 = 160. Still > 50.
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D20',
      'multiplier': 2,
      'score': 40,
    }, seq: 3));
    expect(engine.snapshot()['doubleAttempts'], 0);

    // After dart 2, remaining = 120. Dart 3 D20 → 80 — still > 50, no attempt.
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D20',
      'multiplier': 2,
      'score': 40,
    }, seq: 4));
    expect(engine.snapshot()['doubleAttempts'], 0);
  });

  test('regression #185 — remaining decrements correctly across darts in a turn',
      () {
    // Turn starts at 100. Dart 1 T20 (60) → remaining 40 entering dart 2.
    // Dart 2 D20 (40, mult=2) at remaining=40 ≤ 50 → ATTEMPT.
    engine.init(_makeContext());
    engine.apply(_turnStarted(playerId: 'p1', startingScore: 100, seq: 1));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'T20', 'score': 60,
    }, seq: 2));
    expect(engine.snapshot()['doubleAttempts'], 0,
        reason: 'T20 at remaining=100 is not a checkout attempt');

    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40,
    }, seq: 3));
    expect(engine.snapshot()['doubleAttempts'], 1,
        reason: 'D20 at remaining=40 (after T20 in same turn) IS an attempt');
  });
}
