// Bob's 27 Engine Unit Tests
// Covers scoring rules, deduction rules, turn flow, and end conditions.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_bobs_27_engine.dart';
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

/// Build a minimal Bob's 27 game state.
GameState _makeState({
  int score = 27,
  int practiceRound = 1,
  List<String> dartThrows = const [],
  int dartsThrownInTurn = 0,
  bool turnActive = false,
  bool isComplete = false,
  String? winnerCompetitorId,
}) {
  return GameState(
    gameId: 'game-1',
    gameType: GameType.bobs27,
    competitors: [
      CompetitorState(
        competitorId: 'c1',
        name: 'Player 1',
        playerIds: ['p1'],
        score: score,
        isComplete: isComplete,
        dartThrows: dartThrows,
        practiceRound: practiceRound,
      ),
    ],
    currentTurnIndex: 0,
    dartsThrownInTurn: dartsThrownInTurn,
    isComplete: isComplete,
    winnerCompetitorId: winnerCompetitorId,
    status: isComplete ? GameEngineStatus.completed : GameEngineStatus.inProgress,
    turnActive: turnActive,
  );
}

/// Parse a canonical dart string to (segment, multiplier) for _dartThrown.
({int segment, int multiplier}) _parseCanonical(String c) {
  if (c == 'MISS') return (segment: 0, multiplier: 1);
  if (c == 'DB') return (segment: 25, multiplier: 2);
  if (c == 'SB') return (segment: 25, multiplier: 1);
  if (c.startsWith('D')) return (segment: int.parse(c.substring(1)), multiplier: 2);
  if (c.startsWith('T')) return (segment: int.parse(c.substring(1)), multiplier: 3);
  return (segment: int.parse(c), multiplier: 1);
}

/// Apply TurnStarted + up to 3 darts to the given state. Does NOT apply TurnEnded.
GameState _applyTurn(StatelessBobs27Engine engine, GameState state, List<String> darts) {
  var s = engine.apply(state, _turnStarted('c1')).state;
  for (final d in darts) {
    final p = _parseCanonical(d);
    s = engine.apply(
      s,
      _dartThrown(competitorId: 'c1', segment: p.segment, multiplier: p.multiplier),
    ).state;
  }
  return s;
}

void main() {
  late StatelessBobs27Engine engine;

  setUp(() {
    _seq = 0;
    engine = StatelessBobs27Engine();
  });

  // -------------------------------------------------------------------------
  // GameCreated
  // -------------------------------------------------------------------------
  group('GameCreated', () {
    test('sets status to inProgress', () {
      final state = _makeState().copyWith(status: GameEngineStatus.initialized);
      final result = engine.apply(state, _event(type: 'GameCreated', payload: {}));
      expect(result.state.status, GameEngineStatus.inProgress);
    });
  });

  // -------------------------------------------------------------------------
  // Score increment — hitting the required double
  // -------------------------------------------------------------------------
  group('Score increment — hitting required double', () {
    test('R1: D1 once → score = 29', () {
      final state = _makeState(score: 27, practiceRound: 1);
      final after = _applyTurn(engine, state, ['D1', 'MISS', 'MISS']);
      // 27 + 1*2*1 = 29
      expect(after.competitors[0].score, 29);
    });

    test('R5: D5 twice → score = 47', () {
      final state = _makeState(score: 27, practiceRound: 5);
      final after = _applyTurn(engine, state, ['D5', 'D5', 'MISS']);
      // 27 + 5*2*2 = 47
      expect(after.competitors[0].score, 47);
    });

    test('R5: D5 three times → score = 57', () {
      final state = _makeState(score: 27, practiceRound: 5);
      final after = _applyTurn(engine, state, ['D5', 'D5', 'D5']);
      // 27 + 5*2*3 = 57
      expect(after.competitors[0].score, 57);
    });

    test('R10: D10 once → score = 47', () {
      final state = _makeState(score: 27, practiceRound: 10);
      final after = _applyTurn(engine, state, ['D10', 'MISS', 'MISS']);
      // 27 + 10*2*1 = 47
      expect(after.competitors[0].score, 47);
    });

    test('R20: D20 twice → score = 107, game continues to the bull round', () {
      final state = _makeState(score: 27, practiceRound: 20);
      final after = _applyTurn(engine, state, ['D20', 'D20', 'MISS']);
      // 27 + 20*2*2 = 107; round 20 is no longer the last round (#588).
      expect(after.competitors[0].score, 107);
      expect(after.isComplete, isFalse);
      expect(after.competitors[0].practiceRound, 21);
    });
  });

  // -------------------------------------------------------------------------
  // Score decrement — missing the required double
  // -------------------------------------------------------------------------
  group('Score decrement — missing required double', () {
    test('R1: no D1 → score = 25', () {
      final state = _makeState(score: 27, practiceRound: 1);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      // 27 - 1*2 = 25
      expect(after.competitors[0].score, 25);
    });

    test('R7: no D7 → score = 13', () {
      final state = _makeState(score: 27, practiceRound: 7);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      // 27 - 7*2 = 13
      expect(after.competitors[0].score, 13);
    });

    test('R20: no D20 → score = -13 and game ends (no winner)', () {
      final state = _makeState(score: 27, practiceRound: 20);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      // 27 - 20*2 = -13
      expect(after.competitors[0].score, -13);
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, isNull);
    });

    test('R5: 1×D5 + 2×MISS → score increments (not decrements)', () {
      final state = _makeState(score: 27, practiceRound: 5);
      final after = _applyTurn(engine, state, ['D5', 'MISS', 'MISS']);
      // 1 hit → 27 + 5*2*1 = 37; not 27 - 5*2
      expect(after.competitors[0].score, 37);
    });
  });

  // -------------------------------------------------------------------------
  // Non-target doubles don't score
  // -------------------------------------------------------------------------
  group('Non-target doubles don\'t score', () {
    test('R3: D5 (wrong double) + MISS + MISS → penalty: score -= 6', () {
      final state = _makeState(score: 27, practiceRound: 3);
      final after = _applyTurn(engine, state, ['D5', 'MISS', 'MISS']);
      // 0 hits of D3 → 27 - 3*2 = 21
      expect(after.competitors[0].score, 21);
    });

    test('R3: D3 + D5 + D5 → 1 hit → score += 6', () {
      final state = _makeState(score: 27, practiceRound: 3);
      final after = _applyTurn(engine, state, ['D3', 'D5', 'D5']);
      // 1 hit of D3 → 27 + 3*2*1 = 33
      expect(after.competitors[0].score, 33);
    });
  });

  // -------------------------------------------------------------------------
  // Non-double hits on target number don't score
  // -------------------------------------------------------------------------
  group('Non-double hits on target number don\'t score', () {
    test('R7: single 7 counts as miss → score -= 14', () {
      final state = _makeState(score: 27, practiceRound: 7);
      final after = _applyTurn(engine, state, ['7', 'MISS', 'MISS']);
      // single 7 ≠ D7 → 0 hits → 27 - 7*2 = 13
      expect(after.competitors[0].score, 13);
    });

    test('R7: triple 7 counts as miss → score -= 14', () {
      final state = _makeState(score: 27, practiceRound: 7);
      final after = _applyTurn(engine, state, ['T7', 'MISS', 'MISS']);
      // triple 7 ≠ D7 → 0 hits → 27 - 7*2 = 13
      expect(after.competitors[0].score, 13);
    });
  });

  // -------------------------------------------------------------------------
  // Turn flow — round counter advances
  // -------------------------------------------------------------------------
  group('Turn flow — round counter', () {
    test('practiceRound starts at 1', () {
      final state = _makeState();
      expect(state.competitors[0].practiceRound, 1);
    });

    test('after full turn for R1, practiceRound advances to 2', () {
      final state = _makeState(score: 27, practiceRound: 1);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.competitors[0].practiceRound, 2);
    });

    test('after full turn for R19, practiceRound advances to 20', () {
      final state = _makeState(score: 100, practiceRound: 19);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.competitors[0].practiceRound, 20);
      expect(after.isComplete, isFalse);
    });

    test('after full turn for R20 (miss), practiceRound = 21, game continues', () {
      final state = _makeState(score: 100, practiceRound: 20);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      // round was 20, after increment it's 21 (the bull round) — NOT the end.
      expect(after.competitors[0].practiceRound, 21);
      expect(after.isComplete, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Scoring evaluated only on 3rd dart
  // -------------------------------------------------------------------------
  group('Score evaluated only on 3rd dart', () {
    test('score unchanged after 1st dart', () {
      final state = _makeState(score: 27, practiceRound: 1, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2),
      );
      expect(result.state.competitors[0].score, 27);
    });

    test('score unchanged after 2nd dart', () {
      final state = _makeState(
        score: 27,
        practiceRound: 1,
        dartsThrownInTurn: 1,
        dartThrows: ['D1'],
        turnActive: true,
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2),
      );
      expect(result.state.competitors[0].score, 27);
    });

    test('turnActive remains true after 1st dart', () {
      final state = _makeState(score: 27, practiceRound: 1, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.state.turnActive, isTrue);
    });

    test('turnActive becomes false after 3rd dart', () {
      final state = _makeState(score: 27, practiceRound: 1);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.turnActive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Early end — score drops to ≤ 0
  // -------------------------------------------------------------------------
  group('Early end — score drops to ≤ 0', () {
    test('score = 2 at R1, miss D1 → score = 0, game ends, no winner', () {
      final state = _makeState(score: 2, practiceRound: 1);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      // 2 - 1*2 = 0
      expect(after.competitors[0].score, 0);
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, isNull);
      expect(after.status, GameEngineStatus.completed);
    });

    test('score = 1 at R1, miss D1 → score = -1, game ends, no winner', () {
      final state = _makeState(score: 1, practiceRound: 1);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      // 1 - 1*2 = -1
      expect(after.competitors[0].score, -1);
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, isNull);
    });

    test('score = 4 at R2, miss D2 → score = 0, game ends', () {
      final state = _makeState(score: 4, practiceRound: 2);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      // 4 - 2*2 = 0
      expect(after.competitors[0].score, 0);
      expect(after.isComplete, isTrue);
    });

    test('early-end result has outcome = gameCompleted', () {
      final state = _makeState(score: 2, practiceRound: 1, turnActive: true, dartsThrownInTurn: 2, dartThrows: ['MISS', 'MISS']);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.outcome, LegOutcome.gameCompleted);
    });
  });

  // -------------------------------------------------------------------------
  // Bull round (round 21) — the Double-Bull finale (#588)
  // -------------------------------------------------------------------------
  group('Bull round (round 21)', () {
    test('R20 hit D20 → still in progress, advances to the bull round', () {
      final state = _makeState(score: 27, practiceRound: 20);
      final after = _applyTurn(engine, state, ['D20', 'MISS', 'MISS']);
      expect(after.isComplete, isFalse);
      expect(after.competitors[0].practiceRound, 21);
    });

    test('R21 DB once → +50 and game ends, no winner', () {
      final state = _makeState(score: 100, practiceRound: 21);
      final after = _applyTurn(engine, state, ['DB', 'MISS', 'MISS']);
      expect(after.competitors[0].score, 150);
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, isNull);
    });

    test('R21 DB three times → +150 and game ends', () {
      final state = _makeState(score: 100, practiceRound: 21);
      final after = _applyTurn(engine, state, ['DB', 'DB', 'DB']);
      expect(after.competitors[0].score, 250);
      expect(after.isComplete, isTrue);
    });

    test('R21 whitewash → -50 and game ends', () {
      final state = _makeState(score: 100, practiceRound: 21);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.competitors[0].score, 50);
      expect(after.isComplete, isTrue);
    });

    test('R21 single bull (SB) does NOT count — only Double Bull scores', () {
      final state = _makeState(score: 100, practiceRound: 21);
      final after = _applyTurn(engine, state, ['SB', 'SB', 'SB']);
      // No DB hit → whitewash penalty of 50.
      expect(after.competitors[0].score, 50);
      expect(after.isComplete, isTrue);
    });

    test('R21 result has outcome = gameCompleted', () {
      final state = _makeState(
        score: 100,
        practiceRound: 21,
        turnActive: true,
        dartsThrownInTurn: 2,
        dartThrows: ['MISS', 'MISS'],
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2),
      );
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('perfect run (3 doubles every round + 3 Double Bulls) totals 1437', () {
      var state = _makeState(score: 27, practiceRound: 1);
      for (var round = 1; round <= 21; round++) {
        final dart = round >= 21 ? 'DB' : 'D$round';
        state = _applyTurn(engine, state, [dart, dart, dart]);
        if (round < 21) {
          state = engine.apply(state, _turnEnded('c1')).state;
          state = engine.apply(state, _turnStarted('c1')).state;
        }
      }
      expect(state.competitors[0].score, 1437);
      expect(state.isComplete, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // TurnStarted
  // -------------------------------------------------------------------------
  group('TurnStarted', () {
    test('sets dartsThrownInTurn=0 and turnActive=true', () {
      final state = _makeState(turnActive: false, dartsThrownInTurn: 2);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.turnActive, isTrue);
    });

    test('isValid returns false when turn is already active', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('isValid returns true when no active turn', () {
      final state = _makeState(turnActive: false);
      expect(engine.isValid(state, _turnStarted('c1')), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // TurnEnded
  // -------------------------------------------------------------------------
  group('TurnEnded', () {
    test('sets turnActive=false and resets dartsThrownInTurn', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.turnActive, isFalse);
      expect(result.state.dartsThrownInTurn, 0);
    });
  });

  // -------------------------------------------------------------------------
  // isValid rejections
  // -------------------------------------------------------------------------
  group('isValid rejections', () {
    test('DartThrown rejected when isComplete = true', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2)),
        isFalse,
      );
    });

    test('DartThrown rejected when dartsThrownInTurn = 3 (even if turnActive)', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2)),
        isFalse,
      );
    });

    test('DartThrown rejected when turn is not active', () {
      final state = _makeState(turnActive: false);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2)),
        isFalse,
      );
    });

    test('TurnStarted rejected when turnActive = true', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('DartThrown accepted in normal mid-turn state', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 1);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2)),
        isTrue,
      );
    });

    test('unknown event type always valid', () {
      final state = _makeState();
      expect(engine.isValid(state, _event(type: 'UnknownEvent', payload: {})), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // GameCompleted event replay
  // -------------------------------------------------------------------------
  group('GameCompleted event replay', () {
    test('sets isComplete=true, status=completed, turnActive=false', () {
      final state = _makeState(isComplete: true);
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': null}),
      );
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.state.turnActive, isFalse);
      expect(result.outcome, LegOutcome.gameCompleted);
    });
  });

  // -------------------------------------------------------------------------
  // Canonical string recording
  // -------------------------------------------------------------------------
  group('Canonical string recording', () {
    test('MISS recorded as MISS', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });

    test('D7 recorded as D7', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 7, multiplier: 2),
      );
      expect(result.state.competitors[0].dartThrows, contains('D7'));
    });

    test('T20 recorded as T20', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3),
      );
      expect(result.state.competitors[0].dartThrows, contains('T20'));
    });

    test('DB recorded as DB', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2),
      );
      expect(result.state.competitors[0].dartThrows, contains('DB'));
    });

    test('dart recorded even when not target', () {
      // R1 target is D1; throwing D5 still gets recorded
      final state = _makeState(practiceRound: 1, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 5, multiplier: 2),
      );
      expect(result.state.competitors[0].dartThrows, contains('D5'));
    });
  });
}
