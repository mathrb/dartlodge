// Count-Up Engine Unit Tests
// Spec: docs/games/count-up.md
//
// Covers per-dart additive scoring, turn rotation, round advancement, end-of-game
// detection on TurnEnded (last competitor of last round), and winner-selection
// rules (solo always wins, clear top wins, tie → null winner).

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_count_up_engine.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';

int _seq = 0;

GameEvent _event({
  required String type,
  required Map<String, dynamic> payload,
  String gameId = 'game-1',
}) {
  _seq++;
  return GameEvent(
    eventId: 'e$_seq',
    gameId: gameId,
    eventType: type,
    localSequence: _seq,
    occurredAt: DateTime.utc(2024, 1, 1),
    payload: payload,
    synced: false,
    actorId: 'test',
    source: EventSource.client,
  );
}

GameEvent _dartThrown({
  required String competitorId,
  required int segment,
  required int multiplier,
}) =>
    _event(
      type: 'DartThrown',
      payload: {
        'competitor_id': competitorId,
        'segment': segment,
        'multiplier': multiplier,
      },
    );

GameEvent _turnStarted(String competitorId) => _event(
      type: 'TurnStarted',
      payload: {'competitor_id': competitorId},
    );

GameEvent _turnEnded(String competitorId) => _event(
      type: 'TurnEnded',
      payload: {'competitor_id': competitorId},
    );

CompetitorState _comp(String id, {int score = 0}) => CompetitorState(
      competitorId: id,
      name: 'Player $id',
      playerIds: ['p_$id'],
      score: score,
      startingScore: score,
    );

GameState _makeState({
  int totalRounds = 8,
  int currentRoundInLeg = 1,
  int currentTurnIndex = 0,
  int dartsThrownInTurn = 0,
  bool turnActive = false,
  bool isComplete = false,
  String? winnerCompetitorId,
  List<CompetitorState>? competitors,
}) {
  final comps = competitors ?? [_comp('c1')];
  return GameState(
    gameId: 'game-1',
    gameType: GameType.countUp,
    competitors: comps,
    currentTurnIndex: currentTurnIndex,
    dartsThrownInTurn: dartsThrownInTurn,
    isComplete: isComplete,
    winnerCompetitorId: winnerCompetitorId,
    status: isComplete ? GameEngineStatus.completed : GameEngineStatus.inProgress,
    turnActive: turnActive,
    currentRoundInLeg: currentRoundInLeg,
    countUpTotalRounds: totalRounds,
  );
}

({int segment, int multiplier}) _parseCanonical(String c) {
  if (c == 'MISS') return (segment: 0, multiplier: 1);
  if (c == 'DB') return (segment: 25, multiplier: 2);
  if (c == 'SB') return (segment: 25, multiplier: 1);
  if (c.startsWith('D')) return (segment: int.parse(c.substring(1)), multiplier: 2);
  if (c.startsWith('T')) return (segment: int.parse(c.substring(1)), multiplier: 3);
  return (segment: int.parse(c), multiplier: 1);
}

/// Apply TurnStarted + 3 darts + TurnEnded for a given competitor.
({GameState state, EngineResult lastResult}) _applyTurn(
  StatelessCountUpEngine engine,
  GameState state,
  List<String> darts, {
  required String competitorId,
}) {
  var s = engine.apply(state, _turnStarted(competitorId)).state;
  for (final d in darts) {
    final p = _parseCanonical(d);
    s = engine
        .apply(
          s,
          _dartThrown(
            competitorId: competitorId,
            segment: p.segment,
            multiplier: p.multiplier,
          ),
        )
        .state;
  }
  final ended = engine.apply(s, _turnEnded(competitorId));
  return (state: ended.state, lastResult: ended);
}

void main() {
  late StatelessCountUpEngine engine;

  setUp(() {
    _seq = 0;
    engine = StatelessCountUpEngine();
  });

  // ---------------------------------------------------------------------------
  // GameCreated
  // ---------------------------------------------------------------------------
  group('GameCreated', () {
    test('sets status to inProgress', () {
      final state =
          _makeState().copyWith(status: GameEngineStatus.initialized);
      final result = engine.apply(state, _event(type: 'GameCreated', payload: {}));
      expect(result.state.status, GameEngineStatus.inProgress);
    });
  });

  // ---------------------------------------------------------------------------
  // TurnStarted
  // ---------------------------------------------------------------------------
  group('TurnStarted', () {
    test('activates turn, resets dart count, captures turnStartScore', () {
      final state = _makeState(competitors: [_comp('c1', score: 75)]);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.turnActive, isTrue);
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.competitors[0].turnStartScore, 75);
      expect(result.state.competitors[0].dartThrows, isEmpty);
    });

    test('isValid rejects when turn already active', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('isValid accepts when no active turn', () {
      final state = _makeState(turnActive: false);
      expect(engine.isValid(state, _turnStarted('c1')), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // DartThrown — scoring
  // ---------------------------------------------------------------------------
  group('DartThrown scoring', () {
    test('MISS adds 0', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 0);
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });

    test('single 20 adds 20', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 20);
    });

    test('double 20 adds 40', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2),
      );
      expect(result.state.competitors[0].score, 40);
    });

    test('triple 20 adds 60', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3),
      );
      expect(result.state.competitors[0].score, 60);
    });

    test('single bull adds 25', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 25);
      expect(result.state.competitors[0].dartThrows, contains('SB'));
    });

    test('double bull adds 50', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2),
      );
      expect(result.state.competitors[0].score, 50);
      expect(result.state.competitors[0].dartThrows, contains('DB'));
    });

    test('score accumulates across darts within a turn', () {
      var state = _makeState(turnActive: true);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      expect(state.competitors[0].score, 180);
    });

    test('dartsThrownInTurn increments with each dart', () {
      var state = _makeState(turnActive: true);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(state.dartsThrownInTurn, 1);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(state.dartsThrownInTurn, 2);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(state.dartsThrownInTurn, 3);
    });

    test('turnActive becomes false after the 3rd dart', () {
      var state = _makeState(turnActive: true);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(state.turnActive, isTrue);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(state.turnActive, isTrue);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(state.turnActive, isFalse);
    });

    test('3rd dart never signals end-of-game outcome (only TurnEnded does)', () {
      // Even on the last possible dart, DartThrown returns LegOutcome.none.
      final state = _makeState(
        totalRounds: 1,
        currentRoundInLeg: 1,
        turnActive: true,
        dartsThrownInTurn: 2,
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3),
      );
      expect(result.outcome, LegOutcome.none);
      expect(result.state.isComplete, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // TurnEnded — turn rotation and round advancement
  // ---------------------------------------------------------------------------
  group('TurnEnded rotation', () {
    test('mid-round (2P, P1 ends turn) → currentTurnIndex advances to 1', () {
      final state = _makeState(
        competitors: [_comp('c1'), _comp('c2')],
        currentTurnIndex: 0,
        dartsThrownInTurn: 3,
        turnActive: false,
      );
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.currentTurnIndex, 1);
      expect(result.state.currentRoundInLeg, 1); // round unchanged
      expect(result.outcome, LegOutcome.none);
    });

    test('end-of-round (2P, P2 ends turn) → wraps to index 0, advances round', () {
      final state = _makeState(
        totalRounds: 8,
        currentRoundInLeg: 1,
        competitors: [_comp('c1'), _comp('c2')],
        currentTurnIndex: 1,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.state.currentTurnIndex, 0);
      expect(result.state.currentRoundInLeg, 2);
      expect(result.state.isComplete, isFalse);
    });

    test('TurnEnded resets dartsThrownInTurn and clears turnActive', () {
      final state = _makeState(
        competitors: [_comp('c1'), _comp('c2')],
        currentTurnIndex: 0,
        dartsThrownInTurn: 3,
        turnActive: false,
      );
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.turnActive, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // End-of-game detection
  // ---------------------------------------------------------------------------
  group('Game end on TurnEnded (last competitor + last round)', () {
    test('solo on last round → game completes, solo player wins', () {
      final state = _makeState(
        totalRounds: 8,
        currentRoundInLeg: 8,
        competitors: [_comp('c1', score: 200)],
        currentTurnIndex: 0,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c1');
      expect(result.state.winnerCompetitorId, 'c1');
    });

    test('2P last round, clear winner', () {
      final state = _makeState(
        totalRounds: 8,
        currentRoundInLeg: 8,
        competitors: [_comp('c1', score: 250), _comp('c2', score: 300)],
        currentTurnIndex: 1,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.state.isComplete, isTrue);
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c2');
    });

    test('2P last round, tied at top → no winner', () {
      final state = _makeState(
        totalRounds: 8,
        currentRoundInLeg: 8,
        competitors: [_comp('c1', score: 312), _comp('c2', score: 312)],
        currentTurnIndex: 1,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.state.isComplete, isTrue);
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, isNull);
      expect(result.state.winnerCompetitorId, isNull);
    });

    test('3P last round, 2 tied at top → no winner', () {
      final state = _makeState(
        totalRounds: 8,
        currentRoundInLeg: 8,
        competitors: [
          _comp('c1', score: 312),
          _comp('c2', score: 312),
          _comp('c3', score: 287),
        ],
        currentTurnIndex: 2,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c3'));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, isNull);
    });

    test('3P last round, 1 leader + 2 tied below → leader wins', () {
      final state = _makeState(
        totalRounds: 8,
        currentRoundInLeg: 8,
        competitors: [
          _comp('c1', score: 200),
          _comp('c2', score: 200),
          _comp('c3', score: 350),
        ],
        currentTurnIndex: 2,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c3'));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c3');
    });

    test('not-last competitor in last round does NOT end the game', () {
      final state = _makeState(
        totalRounds: 8,
        currentRoundInLeg: 8,
        competitors: [_comp('c1', score: 100), _comp('c2', score: 100)],
        currentTurnIndex: 0, // P1 still on turn, P2 hasn't thrown
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.isComplete, isFalse);
      expect(result.outcome, LegOutcome.none);
      expect(result.state.currentTurnIndex, 1);
    });

    test('last competitor of non-last round does NOT end the game', () {
      final state = _makeState(
        totalRounds: 8,
        currentRoundInLeg: 7,
        competitors: [_comp('c1', score: 100), _comp('c2', score: 100)],
        currentTurnIndex: 1,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.state.isComplete, isFalse);
      expect(result.state.currentRoundInLeg, 8);
      expect(result.state.currentTurnIndex, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Full mini-game walkthrough (matches Example D in count-up.md)
  // ---------------------------------------------------------------------------
  group('Full mini-game walkthrough', () {
    test('2P / 2 rounds — Example D from spec ends with B winning', () {
      var state = _makeState(
        totalRounds: 2,
        currentRoundInLeg: 1,
        competitors: [_comp('A'), _comp('B')],
      );
      // Round 1 — A: T20+T20+S20 = 140
      var turn = _applyTurn(engine, state, ['T20', 'T20', '20'], competitorId: 'A');
      state = turn.state;
      expect(state.competitors[0].score, 140);
      expect(state.isComplete, isFalse);

      // Round 1 — B: T19+S19+MISS = 76
      turn = _applyTurn(engine, state, ['T19', '19', 'MISS'], competitorId: 'B');
      state = turn.state;
      expect(state.competitors[1].score, 76);
      expect(state.currentRoundInLeg, 2);
      expect(state.isComplete, isFalse);

      // Round 2 — A: DB+S20+MISS = 70 (cumulative 210)
      turn = _applyTurn(engine, state, ['DB', '20', 'MISS'], competitorId: 'A');
      state = turn.state;
      expect(state.competitors[0].score, 210);
      expect(state.isComplete, isFalse);

      // Round 2 — B: T20+T20+T20 = 180 (cumulative 256) → ends game
      turn = _applyTurn(engine, state, ['T20', 'T20', 'T20'], competitorId: 'B');
      state = turn.state;
      expect(state.competitors[1].score, 256);
      expect(state.isComplete, isTrue);
      expect(state.winnerCompetitorId, 'B');
      expect(turn.lastResult.outcome, LegOutcome.gameCompleted);
    });

    test('all-MISS round leaves scores unchanged', () {
      var state = _makeState(
        totalRounds: 1,
        currentRoundInLeg: 1,
        competitors: [_comp('c1')],
      );
      final turn = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS'], competitorId: 'c1');
      state = turn.state;
      expect(state.competitors[0].score, 0);
      expect(state.isComplete, isTrue);
      expect(state.winnerCompetitorId, 'c1');
    });

    test('handicap initialisation — competitor scores carry the handicap forward', () {
      // Engine consumes whatever starting score the GameState provides; we just
      // verify it adds on top without mutating the carry.
      final state = _makeState(
        totalRounds: 1,
        currentRoundInLeg: 1,
        competitors: [_comp('A', score: 100), _comp('B', score: 0)],
      );
      // A throws all misses, ends with their initial 100.
      var turn = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS'], competitorId: 'A');
      var s = turn.state;
      expect(s.competitors[0].score, 100);
      expect(s.isComplete, isFalse);

      // B throws T20+T20+T20 = 180.
      turn = _applyTurn(engine, s, ['T20', 'T20', 'T20'], competitorId: 'B');
      s = turn.state;
      expect(s.competitors[1].score, 180);
      expect(s.isComplete, isTrue);
      expect(s.winnerCompetitorId, 'B');
    });
  });

  // ---------------------------------------------------------------------------
  // isValid rejections
  // ---------------------------------------------------------------------------
  group('isValid rejections', () {
    test('DartThrown rejected when isComplete', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when dartsThrownInTurn >= 3', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when turn not active', () {
      final state = _makeState(turnActive: false);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown accepted in normal mid-turn state', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 1);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isTrue,
      );
    });

    test('TurnStarted rejected after game complete', () {
      final state = _makeState(isComplete: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Post-completion guard
  // ---------------------------------------------------------------------------
  group('Post-completion guard', () {
    test('events other than GameCompleted are ignored after game ends', () {
      final state = _makeState(isComplete: true, turnActive: false);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3),
      );
      expect(result.state.competitors[0].score, 0); // unchanged
      expect(result.state.isComplete, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // GameCompleted event replay
  // ---------------------------------------------------------------------------
  group('GameCompleted event replay', () {
    test('sets isComplete, status, winnerCompetitorId from payload', () {
      final state = _makeState();
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': 'c1'}),
      );
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.state.winnerCompetitorId, 'c1');
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('null winner_id replays as no winner', () {
      final state = _makeState();
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': null}),
      );
      expect(result.state.winnerCompetitorId, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Dart-count invariant — total darts emitted at game end
  // ---------------------------------------------------------------------------
  group('Total dart count invariant', () {
    test('2P × 2 rounds × 3 darts = 12 darts total', () {
      var state = _makeState(
        totalRounds: 2,
        currentRoundInLeg: 1,
        competitors: [_comp('A'), _comp('B')],
      );
      var totalDarts = 0;
      for (var round = 1; round <= 2; round++) {
        for (final id in ['A', 'B']) {
          final turn = _applyTurn(
            engine,
            state,
            ['MISS', 'MISS', 'MISS'],
            competitorId: id,
          );
          state = turn.state;
          totalDarts += 3;
        }
      }
      expect(totalDarts, 12);
      expect(state.isComplete, isTrue);
    });
  });
}
