import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_runner.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_average_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_checkout_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_legs_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_win_rate_projection.dart';

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
  // ── Test 1 ──────────────────────────────────────────────────────────────────

  test('T1 — turn scope reset fires before TurnStarted is dispatched to engines', () {
    final runner = ProjectionRunner([X01AverageProjection()]);
    runner.init(_makeContext());

    // DartThrown: _turnScore=60, _totalDartsThrown=1
    runner.run([_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1)]);

    // TurnStarted: reset(turn) fires first → _turnScore=0; engine doesn't consume TurnStarted
    runner.run([_makeEvent('TurnStarted', {'player_id': 'p1'}, seq: 2)]);

    // TurnEnded: _totalScoredPoints += 0 (turnScore was wiped), _turnScore=0
    runner.run([_makeEvent('TurnEnded', {'player_id': 'p1', 'reason': 'normal'}, seq: 3)]);

    final snap = runner.snapshot()['x01_average']!;
    // totalScoredPoints=0, totalDartsThrown=1 → avg = 0/1*3 = 0.0
    expect(snap['threeDartAverage'], 0.0);
    expect(snap['totalDartsThrown'], 1);
    expect(snap['totalScoredPoints'], 0);
  });

  // ── Test 2 ──────────────────────────────────────────────────────────────────

  test('T2 — leg scope reset is a no-op for cumulative checkout projection', () {
    final runner = ProjectionRunner([X01CheckoutProjection()]);
    runner.init(_makeContext());

    // TurnStarted: starting_score=50 ≤ 170 → checkoutAttempts=1
    runner.run([_makeEvent('TurnStarted', {'player_id': 'p1', 'starting_score': 50}, seq: 1)]);

    // LegCompleted: apply → successfulCheckouts=1; reset(leg) is a no-op (cumulative)
    runner.run([_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2)]);

    final snap = runner.snapshot()['x01_checkout']!;
    // Cumulative — counters are retained across legs
    expect(snap['checkoutAttempts'], 1);
    expect(snap['successfulCheckouts'], 1);
  });

  // ── Test 3 ──────────────────────────────────────────────────────────────────

  test('T3 — match scope reset fires after GameCompleted apply (no-op reset preserves data)', () {
    final runner = ProjectionRunner([X01WinRateProjection()]);
    runner.init(_makeContext());

    // GameCompleted: apply → gamesPlayed=1, gamesWon=1; reset(match) is no-op
    runner.run([_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1)]);

    final snap = runner.snapshot()['x01.winRate']!;
    expect(snap['gamesWon'], 1);
    expect(snap['gamesPlayed'], 1);
  });

  // ── Test 4 ──────────────────────────────────────────────────────────────────

  test('T4 — full run and re-run after init() produce identical snapshots', () {
    final ctx = _makeContext();
    final runner = ProjectionRunner([X01LegsProjection()]);
    runner.init(ctx);

    final events = [
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3),
      _makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 4),
      _makeEvent('LegCompleted', {'winner_player_id': 'p2'}, seq: 5),
    ];

    runner.run(events);
    final s1 = runner.snapshot();

    runner.init(ctx);
    runner.run(events);
    final s2 = runner.snapshot();

    expect(s1, s2);
  });

  // ── Test 5 ──────────────────────────────────────────────────────────────────

  test('T5 — only engines that consume an event type receive it', () {
    final runner = ProjectionRunner([X01LegsProjection(), X01WinRateProjection()]);
    runner.init(_makeContext());

    // DartThrown: neither X01LegsProjection nor X01WinRateProjection consumes it
    runner.run([_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}, seq: 1)]);
    expect(runner.snapshot()['x01.legs']!['legsPlayed'], 0);
    expect(runner.snapshot()['x01.winRate']!['gamesPlayed'], 0);

    // LegCompleted: only X01LegsProjection consumes it
    runner.run([_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2)]);
    expect(runner.snapshot()['x01.legs']!['legsPlayed'], 1);
    expect(runner.snapshot()['x01.winRate']!['gamesPlayed'], 0);
  });

  // ── Test 6 ──────────────────────────────────────────────────────────────────

  test('T6 — replayFrom() re-inits engines and runs only events from given sequence', () {
    final ctx = _makeContext();
    final runner = ProjectionRunner([X01LegsProjection()]);
    runner.init(ctx);

    final allEvents = [
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 2),
      _makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 3),
    ];

    runner.run(allEvents);
    expect(runner.snapshot()['x01.legs']!['legsWon'], 3);

    // Replay from seq=2 → only events at seq 2 and 3 are replayed
    runner.replayFrom(allEvents, 2);
    expect(runner.snapshot()['x01.legs']!['legsWon'], 2);
  });
}
