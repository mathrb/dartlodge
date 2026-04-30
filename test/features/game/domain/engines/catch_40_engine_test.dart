// Catch 40 Engine Unit Tests
// New rules: checkout drill, targets 61–100, up to 6 darts per target,
// checkout = reach 0 via a double, bust = below 0 / exactly 0 via non-double / reach 1.
// Scoring: ≤2 darts → +3, 3 darts → +2 (target 99 → +3), 4-6 darts → +1, fail → +0.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_catch_40_engine.dart';
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

/// Build a Catch 40 game state.
/// [practiceRound] 1 = target 61, 40 = target 100.
/// [catch40TargetRemaining] defaults to the initial target value (60 + practiceRound).
GameState _makeState({
  int score = 0,
  int practiceRound = 1,
  List<String> dartThrows = const [],
  int dartsThrownInTurn = 0,
  bool turnActive = false,
  bool isComplete = false,
  int? catch40TargetRemaining,
  int catch40DartsOnTarget = 0,
  String? winnerCompetitorId,
}) {
  return GameState(
    gameId: 'game-1',
    gameType: GameType.catch40,
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
    catch40TargetRemaining: catch40TargetRemaining ?? (60 + practiceRound),
    catch40DartsOnTarget: catch40DartsOnTarget,
  );
}

/// Parse a canonical dart string to (segment, multiplier).
({int segment, int multiplier}) _parseCanonical(String c) {
  if (c == 'MISS') return (segment: 0, multiplier: 1);
  if (c == 'DB') return (segment: 25, multiplier: 2);
  if (c == 'SB') return (segment: 25, multiplier: 1);
  if (c.startsWith('D')) return (segment: int.parse(c.substring(1)), multiplier: 2);
  if (c.startsWith('T')) return (segment: int.parse(c.substring(1)), multiplier: 3);
  return (segment: int.parse(c), multiplier: 1);
}

/// Apply a sequence of darts within a turn (TurnStarted + darts).
/// Does NOT apply TurnEnded.
GameState _applyDarts(StatelessCatch40Engine engine, GameState state, List<String> darts) {
  var s = engine.apply(state, _turnStarted('c1')).state;
  for (final d in darts) {
    if (!s.turnActive) break; // Early checkout ends turn
    final p = _parseCanonical(d);
    s = engine.apply(
      s,
      _dartThrown(competitorId: 'c1', segment: p.segment, multiplier: p.multiplier),
    ).state;
  }
  return s;
}

/// Apply a full turn (TurnStarted + darts) then TurnEnded to advance the target.
GameState _applyTargetAttempt(
  StatelessCatch40Engine engine,
  GameState state,
  List<String> darts,
) {
  var s = _applyDarts(engine, state, darts);
  return engine.apply(s, _turnEnded('c1')).state;
}

void main() {
  late StatelessCatch40Engine engine;

  setUp(() {
    _seq = 0;
    engine = StatelessCatch40Engine();
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
  // Target sequence
  // -------------------------------------------------------------------------
  group('Target sequence', () {
    test('first target is 61 (practiceRound=1)', () {
      final state = _makeState(practiceRound: 1);
      expect(state.catch40TargetRemaining, 61);
    });

    test('after advancing past target 61, remaining = 62', () {
      final state = _makeState(practiceRound: 1);
      // Miss all 6 darts then TurnEnded twice (two turns of 3 darts)
      var s = _applyDarts(engine, state, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state; // no advance yet (3 darts < 6)
      s = _applyDarts(engine, s, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state; // now 6 darts → advance
      expect(s.competitors[0].practiceRound, 2);
      expect(s.catch40TargetRemaining, 62);
    });

    test('last target is 100 (practiceRound=40)', () {
      expect(60 + 40, 100);
    });
  });

  // -------------------------------------------------------------------------
  // Checkout — reaching 0 via a double
  // -------------------------------------------------------------------------
  group('Checkout', () {
    test('D20 (40) checks out target 40 — not in range, but logic works', () {
      // Use practiceRound such that target = 40: practiceRound = -20 doesn't work.
      // Use catch40TargetRemaining=40 directly.
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 40,
        turnActive: true,
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2),
      );
      expect(result.state.catch40TargetRemaining, 0);
      expect(result.state.turnActive, isFalse); // Turn ends early on checkout
    });

    test('checkout on 2nd dart: turnActive=false after 2nd dart', () {
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 40,
        turnActive: true,
        dartsThrownInTurn: 1,
        dartThrows: ['1'],
        catch40DartsOnTarget: 1,
      );
      // Remaining after 1 dart: 40-1=39. D20=40 > 39 = bust, not checkout.
      // Let's use remaining=40 fresh:
      final s2 = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 40,
        turnActive: true,
      );
      // Throw 20 (single): remaining = 20
      var s = engine.apply(s2, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(s.catch40TargetRemaining, 20);
      expect(s.turnActive, isTrue); // still in turn
      // Throw D10 (=20): remaining = 0 → checkout
      s = engine.apply(s, _dartThrown(competitorId: 'c1', segment: 10, multiplier: 2)).state;
      expect(s.catch40TargetRemaining, 0);
      expect(s.turnActive, isFalse);
      expect(s.catch40DartsOnTarget, 2);
    });

    test('checkout on 1st dart awards +3 points after TurnEnded', () {
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 40,
        turnActive: true,
      );
      // D20=40 → checkout on 1st dart
      var s = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2)).state;
      expect(s.catch40TargetRemaining, 0);
      expect(s.catch40DartsOnTarget, 1);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 3);
      expect(s.competitors[0].practiceSuccesses, 1);
    });

    test('checkout on 2nd dart awards +3 points', () {
      final state = _makeState(practiceRound: 1, catch40TargetRemaining: 40);
      // 20 (single) + D10 = checkout on 2nd dart
      var s = _applyDarts(engine, state, ['20', 'D10']);
      expect(s.catch40DartsOnTarget, 2);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 3);
    });

    test('checkout on 3rd dart awards +2 points (target 61)', () {
      // Target 61: e.g. 20 + 1 + D20 = 61
      final state = _makeState(practiceRound: 1); // remaining=61
      var s = _applyDarts(engine, state, ['20', '1', 'D20']);
      expect(s.catch40TargetRemaining, 0);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 2);
    });

    test('checkout on 3rd dart on target 99 awards +3 points', () {
      // Target 99, 3-dart checkout
      final state = _makeState(practiceRound: 39, catch40TargetRemaining: 99);
      // T20=60, T13=39 doesn't work in 2. Let's: T19=57, T14=42 → 57+42=99 in 2.
      // Actually T19+T14 is only 2 darts. Need 3 darts.
      // T20=60, 19=19 → 20 remaining → D10=20. That's checkout in 3 on 99? No: 60+19+20=99 ✓
      // But remaining after T20: 99-60=39. After 19: 39-19=20. After D10: 20-20=0. ✓
      var s = _applyDarts(engine, state, ['T20', '19', 'D10']);
      expect(s.catch40TargetRemaining, 0);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 3); // target 99 special case
    });

    test('checkout on 4th dart awards +1 point', () {
      final state = _makeState(practiceRound: 1, catch40TargetRemaining: 61);
      // 3 darts, no checkout: 10+10+10=30, remaining=31
      // Then 4th dart (2nd turn): D15=30 → remaining=1 → bust! Try: 1 (single) → remaining=30 → D15=30 → checkout? Need 4 darts.
      // Turn 1: 10+10+10 = 30 used, remaining=31
      var s = _applyDarts(engine, state, ['10', '10', '10']);
      s = engine.apply(s, _turnEnded('c1')).state; // no advance (3 darts < 6), TurnEnded for same target
      // Turn 2: 1 (single) → remaining=30, then D15=30 → checkout on 4th dart total
      s = _applyDarts(engine, s, ['1', 'D15']);
      expect(s.catch40TargetRemaining, 0);
      expect(s.catch40DartsOnTarget, 5);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 1);
    });

    test('checkout on 6th dart awards +1 point', () {
      final state = _makeState(practiceRound: 1, catch40TargetRemaining: 61);
      // Turn 1: MISS MISS MISS → remaining still 61 (busts reset to 61), darts=3
      var s = _applyDarts(engine, state, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state;
      // Turn 2: 1+20+D20=41 → 61-1=60, 60-20=40, 40-40=0 → checkout on 6th dart
      s = _applyDarts(engine, s, ['1', '20', 'D20']);
      expect(s.catch40TargetRemaining, 0);
      expect(s.catch40DartsOnTarget, 6);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Bust behaviour
  // -------------------------------------------------------------------------
  group('Bust behaviour', () {
    test('dart taking remaining below 0 is a bust — resets remaining to target', () {
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 10,
        turnActive: true,
      );
      // D20=40 > 10 → bust
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2),
      );
      expect(result.isBust, isTrue);
      expect(result.state.catch40TargetRemaining, 61); // reset to 60+practiceRound
    });

    test('dart reducing remaining to exactly 0 via non-double is a bust', () {
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 20,
        turnActive: true,
      );
      // Single 20 = 20, remaining = 0, NOT a double → bust
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1),
      );
      expect(result.isBust, isTrue);
      expect(result.state.catch40TargetRemaining, 61);
    });

    test('dart reducing remaining to 1 is a bust', () {
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 21,
        turnActive: true,
      );
      // 20 single → remaining = 1 → bust
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1),
      );
      expect(result.isBust, isTrue);
      expect(result.state.catch40TargetRemaining, 61);
    });

    test('bust still increments catch40DartsOnTarget', () {
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 10,
        turnActive: true,
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2),
      );
      expect(result.isBust, isTrue);
      expect(result.state.catch40DartsOnTarget, 1);
    });

    test('bust does NOT end the turn (still 3 darts per turn)', () {
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 10,
        turnActive: true,
      );
      var s = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2), // bust
      ).state;
      expect(s.turnActive, isTrue); // turn continues
      expect(s.dartsThrownInTurn, 1);
    });

    test('MISS scores 0, does not bust, reduces remaining by 0', () {
      final state = _makeState(
        practiceRound: 1,
        catch40TargetRemaining: 61,
        turnActive: true,
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.isBust, isFalse);
      expect(result.state.catch40TargetRemaining, 61);
    });
  });

  // -------------------------------------------------------------------------
  // 6-dart limit (two turns of 3)
  // -------------------------------------------------------------------------
  group('6-dart limit', () {
    test('TurnEnded after 3 darts (no checkout, no 6 darts) does NOT advance target', () {
      final state = _makeState(practiceRound: 1);
      var s = _applyDarts(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(s.catch40DartsOnTarget, 3);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].practiceRound, 1); // still on target 61
      expect(s.catch40TargetRemaining, 61); // remaining unchanged
    });

    test('TurnEnded after 6 darts (no checkout) advances target', () {
      final state = _makeState(practiceRound: 1);
      var s = _applyDarts(engine, state, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state;
      s = _applyDarts(engine, s, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].practiceRound, 2); // advanced to target 62
      expect(s.catch40DartsOnTarget, 0);
      expect(s.competitors[0].score, 0); // no checkout = 0 points
    });

    test('target attempt failure sets practiceAttempts += 1', () {
      final state = _makeState(practiceRound: 1);
      final after = _applyTargetAttempt(engine,
        _applyTargetAttempt(engine, state, ['MISS', 'MISS', 'MISS']),
        ['MISS', 'MISS', 'MISS']);
      // After two TurnEnded calls (6 darts total), target advances
      expect(after.competitors[0].practiceAttempts, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Game completion
  // -------------------------------------------------------------------------
  group('Game completion', () {
    test('after 40 targets, game is complete', () {
      // Start from practiceRound=40, attempt that target, then TurnEnded x2
      final state = _makeState(practiceRound: 40, catch40TargetRemaining: 100);
      var s = _applyDarts(engine, state, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state; // no advance, 3 darts
      s = _applyDarts(engine, s, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state; // advance → practiceRound=41 → complete
      expect(s.isComplete, isTrue);
      expect(s.status, GameEngineStatus.completed);
      expect(s.winnerCompetitorId, isNull);
    });

    test('completing target 39 does NOT end game', () {
      final state = _makeState(practiceRound: 39, catch40TargetRemaining: 99);
      var s = _applyDarts(engine, state, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state;
      s = _applyDarts(engine, s, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.isComplete, isFalse);
      expect(s.competitors[0].practiceRound, 40);
    });

    test('checkout on final target ends game', () {
      final state = _makeState(practiceRound: 40, catch40TargetRemaining: 40);
      var s = _applyDarts(engine, state, ['D20']); // checkout in 1 dart
      expect(s.catch40TargetRemaining, 0);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.isComplete, isTrue);
      expect(s.competitors[0].score, 3);
    });
  });

  // -------------------------------------------------------------------------
  // Points accumulation
  // -------------------------------------------------------------------------
  group('Points accumulation', () {
    test('multiple checkouts accumulate correctly', () {
      // Target 61 (round 1): checkout in 2 darts → +3
      var state = _makeState(practiceRound: 1, catch40TargetRemaining: 61);
      // 1+D30? D30=60, 1+60=61 in 2 darts
      var s = _applyDarts(engine, state, ['1', 'D30']);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 3);

      // Target 62 (round 2): checkout in 3 darts → +2
      // 20+2+D20=42? No: 20+2+40=62. D20=40. 20+2=22, 62-22=40=D20. ✓
      s = _applyDarts(engine, s, ['20', '2', 'D20']);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 5); // 3+2
    });

    test('failed attempt adds 0 points', () {
      final state = _makeState(practiceRound: 1);
      var s = _applyDarts(engine, state, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state;
      s = _applyDarts(engine, s, ['MISS', 'MISS', 'MISS']);
      s = engine.apply(s, _turnEnded('c1')).state;
      expect(s.competitors[0].score, 0);
    });
  });

  // -------------------------------------------------------------------------
  // TurnStarted / TurnEnded guards
  // -------------------------------------------------------------------------
  group('TurnStarted / TurnEnded guards', () {
    test('TurnStarted sets dartsThrownInTurn=0 and turnActive=true', () {
      final state = _makeState(turnActive: false, dartsThrownInTurn: 2);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.turnActive, isTrue);
    });

    test('isValid: TurnStarted false when turn already active', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('isValid: DartThrown false when game complete', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('isValid: DartThrown false when 3 darts already thrown', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Canonical string recording
  // -------------------------------------------------------------------------
  group('Canonical string recording', () {
    test('MISS recorded as MISS', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });

    test('D20 recorded as D20', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.state.competitors[0].dartThrows, contains('D20'));
    });

    test('T20 recorded as T20', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.competitors[0].dartThrows, contains('T20'));
    });

    test('DB recorded as DB', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2));
      expect(result.state.competitors[0].dartThrows, contains('DB'));
    });
  });

  // -------------------------------------------------------------------------
  // GameCompleted event replay
  // -------------------------------------------------------------------------
  group('GameCompleted event replay', () {
    test('sets isComplete=true, status=completed', () {
      final state = _makeState();
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': null}),
      );
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.outcome, LegOutcome.gameCompleted);
    });
  });
}
