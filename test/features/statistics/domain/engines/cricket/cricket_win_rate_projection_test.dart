import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_win_rate_projection.dart';

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
      gameType: GameType.cricket,
      inStrategy: 'straight',
      outStrategy: 'double',
      playerIds: ['p1', 'p2'],
    );

void main() {
  late CricketWinRateProjection engine;

  setUp(() {
    engine = CricketWinRateProjection();
  });

  // ── Category A: Construction & Initialization ──────────────────────────────

  test('A1 — init produces zero snapshot', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['winRate'], 0.0);
    expect(s['gamesWon'], 0);
    expect(s['gamesPlayed'], 0);
  });

  // ── Category B: Single Event Application ──────────────────────────────────

  test('B1 — GameCompleted increments gamesPlayed', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p2'}, seq: 1));
    expect(engine.snapshot()['gamesPlayed'], 1);
    expect(engine.snapshot()['gamesWon'], 0);
  });

  test('B2 — GameCompleted with own player as winner increments gamesWon', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1));
    expect(engine.snapshot()['gamesPlayed'], 1);
    expect(engine.snapshot()['gamesWon'], 1);
    expect(engine.snapshot()['winRate'], 1.0);
  });

  test('B3 — non-GameCompleted events are ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}, seq: 1));
    expect(engine.snapshot()['gamesPlayed'], 0);
  });

  // ── Category C: Multi-Event Sequences ─────────────────────────────────────

  test('C1 — winRate = gamesWon / gamesPlayed', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p2'}, seq: 2));
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 3));
    final s = engine.snapshot();
    expect(s['gamesPlayed'], 3);
    expect(s['gamesWon'], 2);
    expect((s['winRate'] as double).toStringAsFixed(4), '0.6667');
  });

  // ── Category D: Scope Reset ────────────────────────────────────────────────

  test('D1 — reset does not wipe career totals', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.reset(ProjectionScope.turn);
    engine.reset(ProjectionScope.leg);
    engine.reset(ProjectionScope.match);
    engine.reset(ProjectionScope.career);
    expect(engine.snapshot()['gamesPlayed'], 1);
    expect(engine.snapshot()['gamesWon'], 1);
  });

  // ── Category E: Edge Cases ─────────────────────────────────────────────────

  test('E1 — zero games yields winRate 0.0', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['winRate'], 0.0);
  });

  test('E2 — null winner_player_id does not increment gamesWon', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {}, seq: 1));
    expect(engine.snapshot()['gamesPlayed'], 1);
    expect(engine.snapshot()['gamesWon'], 0);
  });

  // ── Category F: Re-initialization ─────────────────────────────────────────

  test('F1 — init twice resets all state', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.init(_makeContext());
    expect(engine.snapshot()['gamesPlayed'], 0);
    expect(engine.snapshot()['gamesWon'], 0);
  });

  // ── Category G: Descriptor Metadata ───────────────────────────────────────

  test('G1 — descriptor id is cricket.winRate', () {
    expect(engine.descriptor.id, 'cricket.winRate');
  });

  test('G2 — supports only cricket', () {
    expect(engine.descriptor.supportedGameTypes, {GameType.cricket});
  });

  test('G3 — consumes GameCompleted only', () {
    expect(engine.descriptor.consumedEventTypes, {'GameCompleted'});
  });

  // ── GS1–GS3 ───────────────────────────────────────────────────────────────

  test('GS1 — not applicable to X01', () {
    expect(engine.descriptor.supportedGameTypes, isNot(contains(GameType.x01)));
  });

  test('GS2 — applicable to cricket', () {
    expect(engine.descriptor.supportedGameTypes, contains(GameType.cricket));
  });

  test('GS3 — winRate stored as fraction (0.0–1.0), not percentage', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 2));
    // 2/2 = 1.0, not 100.0
    expect(engine.snapshot()['winRate'], 1.0);
  });
}
