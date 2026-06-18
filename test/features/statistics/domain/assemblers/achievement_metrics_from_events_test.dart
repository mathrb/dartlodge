import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';

int _seq = 0;
GameEvent _ev(String gameId, String type, Map<String, dynamic> payload) =>
    GameEvent(
      eventId: 'evt-${_seq}-$type',
      gameId: gameId,
      eventType: type,
      localSequence: ++_seq,
      occurredAt: DateTime(2024),
      payload: payload,
      synced: false,
      actorId: 'p1',
      source: EventSource.client,
    );

void main() {
  const assembler = PlayerStatsAssembler();

  setUp(() => _seq = 0);

  test('cross-type bundle aggregates the achievement metrics correctly', () {
    final events = <GameEvent>[
      // ── X01 501 game: a real 9-darter (180 + 180 + 141), p1 wins ──────────
      _ev('gx', 'TurnStarted', {'player_id': 'p1', 'starting_score': 501}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gx', 'TurnEnded', {'player_id': 'p1', 'reason': 'normal'}),
      _ev('gx', 'TurnStarted', {'player_id': 'p1', 'starting_score': 321}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gx', 'TurnEnded', {'player_id': 'p1', 'reason': 'normal'}),
      _ev('gx', 'TurnStarted', {'player_id': 'p1', 'starting_score': 141}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 19, 'multiplier': 3, 'score': 57}),
      _ev('gx', 'DartThrown', {'player_id': 'p1', 'segment': 12, 'multiplier': 2, 'score': 24}),
      _ev('gx', 'TurnEnded', {'player_id': 'p1', 'reason': 'normal'}),
      _ev('gx', 'LegCompleted', {'winner_player_id': 'p1'}),
      _ev('gx', 'GameCompleted', {'winner_player_id': 'p1'}),

      // ── Cricket game: a 180-POINT turn (contamination guard) + p1 wins ────
      _ev('gc', 'TurnStarted', {'player_id': 'p1'}),
      _ev('gc', 'DartThrown', {'player_id': 'p1', 'segment': 'T20', 'multiplier': 3, 'score': 60}),
      _ev('gc', 'DartThrown', {'player_id': 'p1', 'segment': 'T20', 'multiplier': 3, 'score': 60}),
      _ev('gc', 'DartThrown', {'player_id': 'p1', 'segment': 'T20', 'multiplier': 3, 'score': 60}),
      _ev('gc', 'TurnEnded', {'player_id': 'p1', 'reason': 'normal'}),
      _ev('gc', 'LegCompleted', {'winner_player_id': 'p1'}),
      _ev('gc', 'GameCompleted', {'winner_player_id': 'p1'}),

      // ── Count-Up game: a 180 turn + p1 wins ───────────────────────────────
      _ev('gu', 'TurnStarted', {'player_id': 'p1'}),
      _ev('gu', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gu', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gu', 'DartThrown', {'player_id': 'p1', 'segment': 20, 'multiplier': 3, 'score': 60}),
      _ev('gu', 'TurnEnded', {'player_id': 'p1', 'reason': 'normal'}),
      _ev('gu', 'GameCompleted', {'winner_player_id': 'p1'}),

      // ── Solo practice completion: null winner → not a win ─────────────────
      _ev('gp', 'GameCompleted', {'winner_player_id': null}),
    ];

    final m = assembler.achievementMetricsFromEvents(
      playerId: 'p1',
      events: events,
      totalDartsThrown: 42,
      gameTypesById: const {
        'gx': GameType.x01,
        'gc': GameType.cricket,
        'gu': GameType.countUp,
        'gp': GameType.checkoutPractice,
      },
    );

    // X01 two 180s + Count-Up one 180 = 3; the cricket 180-point turn is
    // partitioned out (NOT counted) — the contamination guard.
    expect(m.total180s, 3);
    expect(m.highestCheckout, 141); // winning X01 turn started at 141
    expect(m.totalWins, 3); // x01 + cricket + countUp; practice null winner excluded
    expect(m.totalDartsThrown, 42); // passthrough param
    expect(m.games501Played, 1);
    expect(m.hasNineDarter, isTrue);
  });

  test('a player with no history yields an all-zero bundle', () {
    final m = assembler.achievementMetricsFromEvents(
      playerId: 'p1',
      events: const [],
      totalDartsThrown: 0,
      gameTypesById: const {},
    );
    expect(m.total180s, 0);
    expect(m.highestCheckout, 0);
    expect(m.totalWins, 0);
    expect(m.totalDartsThrown, 0);
    expect(m.games501Played, 0);
    expect(m.hasNineDarter, isFalse);
  });
}
