import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
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
  late X01WinRateProjection engine;

  setUp(() {
    engine = X01WinRateProjection();
  });

  // ── Category A ─────────────────────────────────────────────────────────────

  test('A1 — init produces 0.0 winRate and zero counters', () {
    engine.init(_makeContext());
    final s = engine.snapshot();
    expect(s['winRate'], 0.0);
    expect(s['gamesWon'], 0);
    expect(s['gamesPlayed'], 0);
  });

  test('A4 — snapshot deterministic after init', () {
    engine.init(_makeContext());
    expect(engine.snapshot(), engine.snapshot());
  });

  // ── Category B ─────────────────────────────────────────────────────────────

  test('B1 — GameCompleted increments gamesPlayed', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p2'}));
    expect(engine.snapshot()['gamesPlayed'], 1);
    expect(engine.snapshot()['gamesWon'], 0);
  });

  test('B1 — GameCompleted with player winning increments gamesWon', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}));
    expect(engine.snapshot()['gamesPlayed'], 1);
    expect(engine.snapshot()['gamesWon'], 1);
  });

  test('B2 — DartThrown ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['gamesPlayed'], 0);
  });

  test('B2 — LegCompleted ignored', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('LegCompleted', {'winner_player_id': 'p1'}));
    expect(engine.snapshot()['gamesPlayed'], 0);
  });

  // ── Category C ─────────────────────────────────────────────────────────────

  test('C1 — win rate calculates correctly', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1));
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p2'}, seq: 2));
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 3));
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p2'}, seq: 4));
    // 2 won / 4 played = 0.5
    expect(engine.snapshot()['winRate'], closeTo(0.5, 0.001));
    expect(engine.snapshot()['gamesPlayed'], 4);
    expect(engine.snapshot()['gamesWon'], 2);
  });

  test('C3 — parallel engines converge', () {
    final e2 = X01WinRateProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    final events = [
      _makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1),
      _makeEvent('GameCompleted', {'winner_player_id': 'p2'}, seq: 2),
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
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}));
    engine.reset(ProjectionScope.turn);
    expect(engine.snapshot()['gamesPlayed'], 1);
    expect(engine.snapshot()['gamesWon'], 1);
  });

  test('D3 — reset(match) does not clear counters (cumulative lifetime)', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}));
    engine.reset(ProjectionScope.match);
    expect(engine.snapshot()['gamesPlayed'], 1);
    expect(engine.snapshot()['gamesWon'], 1);
  });

  // ── Category E ─────────────────────────────────────────────────────────────

  test('E1 — replay yields identical snapshot', () {
    engine.init(_makeContext());
    final events = [
      _makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 1),
      _makeEvent('GameCompleted', {'winner_player_id': 'p2'}, seq: 2),
      _makeEvent('GameCompleted', {'winner_player_id': 'p1'}, seq: 3),
    ];
    for (final e in events) engine.apply(e);
    final first = engine.snapshot();
    engine.init(_makeContext());
    for (final e in events) engine.apply(e);
    expect(engine.snapshot(), first);
  });

  // ── Category F ─────────────────────────────────────────────────────────────

  test('F1 — partial stream without GameCompleted returns 0.0 winRate', () {
    engine.init(_makeContext());
    engine.apply(_makeEvent('DartThrown', {'player_id': 'p1', 'score': 60}));
    expect(engine.snapshot()['winRate'], 0.0);
    expect(engine.snapshot()['gamesPlayed'], 0);
  });

  test('Rat1 — division by zero safe when no games played', () {
    engine.init(_makeContext());
    expect(engine.snapshot()['winRate'], 0.0);
  });

  // ── Category G ─────────────────────────────────────────────────────────────

  test('G2 — two instances do not share state', () {
    final e2 = X01WinRateProjection();
    engine.init(_makeContext());
    e2.init(_makeContext());
    engine.apply(_makeEvent('GameCompleted', {'winner_player_id': 'p1'}));
    expect(e2.snapshot()['gamesPlayed'], 0);
  });

  // ── Category H ─────────────────────────────────────────────────────────────

  test('H1 — 1000 games processed without issue', () {
    engine.init(_makeContext());
    for (int i = 0; i < 1000; i++) {
      engine.apply(_makeEvent(
          'GameCompleted',
          {'winner_player_id': i.isEven ? 'p1' : 'p2'},
          seq: i));
    }
    expect(engine.snapshot()['gamesPlayed'], 1000);
    expect(engine.snapshot()['gamesWon'], 500);
    expect(engine.snapshot()['winRate'], closeTo(0.5, 0.001));
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
