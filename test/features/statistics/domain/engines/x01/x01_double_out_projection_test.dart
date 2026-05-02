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

ProjectionContext _makeContext({
  String playerId = 'p1',
  String outStrategy = 'Double Out',
}) =>
    ProjectionContext(
      playerId: playerId,
      gameType: GameType.x01,
      inStrategy: 'Straight In',
      outStrategy: outStrategy,
      playerIds: ['p1', 'p2'],
    );

void main() {
  late X01DoubleOutProjection engine;

  setUp(() {
    engine = X01DoubleOutProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init with Double Out produces null rate and zero counters', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['doubleOutSuccessRate'], isNull);
    expect(s['doubleAttempts'], 0);
    expect(s['doubleSuccesses'], 0);
  });

  test('A1 — init with Straight Out returns empty snapshot', () {
    engine.init(_makeContext(outStrategy: 'Straight Out'));
    expect(engine.snapshot(), isEmpty);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — DartThrown with preDartRemaining ≤ 50 and double segment increments attempts', () {
    engine.init(_makeContext());
    // preDartRemaining = remaining_after + score = 10 + 30 = 40 ≤ 50, segment D15
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D15',
      'score': 30,
      'remaining_after': 10,
    }));
    expect(engine.snapshot()['doubleAttempts'], 1);
  });

  test('B1 — DartThrown with preDartRemaining > 50 does not count attempt', () {
    engine.init(_makeContext());
    // preDartRemaining = 30 + 60 = 90 > 50
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D20',
      'score': 60,
      'remaining_after': 30,
    }));
    expect(engine.snapshot()['doubleAttempts'], 0);
  });

  test('B1 — DartThrown with preDartRemaining ≤ 50 but non-double segment does not count', () {
    engine.init(_makeContext());
    // preDartRemaining = 10 + 20 = 30 ≤ 50, but segment is single '20'
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': '20',
      'score': 20,
      'remaining_after': 10,
    }));
    expect(engine.snapshot()['doubleAttempts'], 0);
  });

  test('B1 — LegCompleted with player winning increments successes', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1',
      'segment': 'D20',
      'score': 40,
      'remaining_after': 0,
    }, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2));
    expect(engine.snapshot()['doubleSuccesses'], 1);
  });

  test('B2 — other player DartThrown ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p2',
      'segment': 'D20',
      'score': 40,
      'remaining_after': 0,
    }));
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
    // 2 double attempts, 1 success
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
    }, seq: 1));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 2));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
    }, seq: 3));
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 4));
    expect(engine.snapshot()['doubleAttempts'], 2);
    expect(engine.snapshot()['doubleSuccesses'], 1);
    expect(engine.snapshot()['doubleOutSuccessRate'], closeTo(50.0, 0.001));
  });

  test('C1 — Master Out: triple segment counts as attempt', () {
    engine.init(_makeContext(outStrategy: 'Master Out'));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'T10', 'score': 30, 'remaining_after': 10,
    }));
    // preDartRemaining = 10 + 30 = 40 ≤ 50, segment starts with T
    expect(engine.snapshot()['doubleAttempts'], 1);
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01DoubleOutProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('DartThrown', {
        'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
      }, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2),
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
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
    }));
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['doubleAttempts'], 1);
  });

  test('D2 — reset(leg) does not clear counters (cumulative)', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
    }));
    engine.reset(ProjectionScope.leg);
    expect(engine.snapshot()['doubleAttempts'], 1);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay yields identical snapshot', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('DartThrown', {
        'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
      }, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2),
      _makeEvent('DartThrown', {
        'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
      }, seq: 3),
      _makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 4),
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
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
    }));
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
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
    }));
    expect(e2.snapshot()['doubleAttempts'], 0);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 500 double attempts processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 500; i++) {
      engine.apply(_makeEvent('DartThrown', {
        'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
      }, seq: i * 2));
      if (i.isEven) {
        engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: i * 2 + 1));
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

  test('GS3 — Straight Out context returns empty snapshot', () {
    engine.init(_makeContext(outStrategy: 'Straight Out'));
    engine.apply(_makeEvent('DartThrown', {
      'player_id': 'p1', 'segment': 'D20', 'score': 40, 'remaining_after': 0,
    }));
    expect(engine.snapshot(), isEmpty);
  });
}
