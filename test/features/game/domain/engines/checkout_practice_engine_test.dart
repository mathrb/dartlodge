// Checkout Practice Engine Unit Tests
// Covers X01-style scoring from 170, bust detection, checkout detection,
// turn flow, and double-out rules.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_checkout_practice_engine.dart';
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

/// Build a minimal CheckoutPractice game state.
GameState _makeState({
  int score = 170,
  int? turnStartScore,
  List<String> dartThrows = const [],
  int dartsThrownInTurn = 0,
  bool turnActive = false,
  bool isComplete = false,
  String? winnerCompetitorId,
}) {
  return GameState(
    gameId: 'game-1',
    gameType: GameType.checkoutPractice,
    competitors: [
      CompetitorState(
        competitorId: 'c1',
        name: 'Player 1',
        playerIds: ['p1'],
        score: score,
        dartThrows: dartThrows,
        turnStartScore: turnStartScore,
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

void main() {
  late StatelessCheckoutPracticeEngine engine;

  setUp(() {
    _seq = 0;
    engine = StatelessCheckoutPracticeEngine();
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
  // TurnStarted
  // -------------------------------------------------------------------------
  group('TurnStarted', () {
    test('sets turnStartScore to current score', () {
      final state = _makeState(score: 170, turnActive: false);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.competitors[0].turnStartScore, 170);
    });

    test('sets dartsThrownInTurn to 0 and turnActive to true', () {
      final state = _makeState(dartsThrownInTurn: 2, turnActive: false);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.turnActive, isTrue);
    });

    test('preserves current score', () {
      final state = _makeState(score: 110, turnActive: false);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.competitors[0].score, 110);
    });

    test('isValid returns false when turn is already active', () {
      expect(engine.isValid(_makeState(turnActive: true), _turnStarted('c1')), isFalse);
    });

    test('isValid returns true when no active turn', () {
      expect(engine.isValid(_makeState(turnActive: false), _turnStarted('c1')), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Normal dart scoring
  // -------------------------------------------------------------------------
  group('Normal dart scoring', () {
    test('T20 from 170 reduces score to 110', () {
      final state = _makeState(score: 170, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.competitors[0].score, 110);
    });

    test('T20 adds dart to dartThrows', () {
      final state = _makeState(score: 170, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.competitors[0].dartThrows, contains('T20'));
    });

    test('normal dart increments dartsThrownInTurn', () {
      final state = _makeState(score: 170, turnActive: true, dartsThrownInTurn: 0);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.dartsThrownInTurn, 1);
    });

    test('MISS does not change score', () {
      final state = _makeState(score: 110, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1));
      expect(result.state.competitors[0].score, 110);
    });

    test('MISS is added to dartThrows', () {
      final state = _makeState(score: 110, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });

    test('three normal darts fills dartsThrownInTurn to 3', () {
      var state = _makeState(score: 170, turnActive: true);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state; // T20 = 60
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state; // T20 = 60
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state; // 20
      expect(state.dartsThrownInTurn, 3);
      expect(state.competitors[0].score, 30);
    });

    test('SB recorded as SB', () {
      final state = _makeState(score: 170, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('SB'));
    });

    test('D20 recorded as D20', () {
      final state = _makeState(score: 170, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.state.competitors[0].dartThrows, contains('D20'));
    });
  });

  // -------------------------------------------------------------------------
  // Bust detection
  // -------------------------------------------------------------------------
  group('Bust detection', () {
    test('score going below 0 is a bust', () {
      // Score 20, throw T20 (60) → newScore = -40
      final state = _makeState(score: 20, turnActive: true, turnStartScore: 20);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.isBust, isTrue);
    });

    test('bust reverts score to turn-start score', () {
      final state = _makeState(score: 50, turnActive: true, turnStartScore: 170);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)); // T20=60, newScore=-10
      expect(result.state.competitors[0].score, 170);
    });

    test('bust sets dartsThrownInTurn to 3 to signal turn end', () {
      final state = _makeState(score: 20, turnActive: true, turnStartScore: 20);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.dartsThrownInTurn, 3);
    });

    test(
        'bust dart IS recorded in dartThrows + MISS padding (regression for #186)',
        () {
      // Bust on dart 1 (turn was empty going in). After:
      //   dartsThrownInTurn = 3
      //   dartThrows = [T20, MISS, MISS] — 3-aligned for the dropped turn
      // Pre-fix this assertion was reversed (dartThrows empty), which silently
      // lost the bust dart from replay history and any consumer of
      // CompetitorState.dartThrows.
      final state = _makeState(score: 20, turnActive: true, turnStartScore: 20);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.competitors[0].dartThrows, ['T20', 'MISS', 'MISS']);
    });

    test('bust on dart 2 records [prev, bust, MISS]', () {
      // Pre-state: dart 1 already in dartThrows, dart 2 busts.
      // After: dartThrows length 3, padded with one MISS.
      const state = GameState(
        gameId: 'g',
        gameType: GameType.checkoutPractice,
        competitors: [
          CompetitorState(
            competitorId: 'c1',
            name: 'Player 1',
            playerIds: ['p1'],
            score: 50,
            isIn: true,
            dartThrows: ['20'],
            turnStartScore: 70,
          ),
        ],
        currentTurnIndex: 0,
        dartsThrownInTurn: 1,
        isComplete: false,
        status: GameEngineStatus.inProgress,
        turnActive: true,
        startingScore: 170,
      );
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.isBust, isTrue);
      expect(result.state.competitors[0].dartThrows, ['20', 'T20', 'MISS']);
    });

    test('bust on dart 3 records all three darts, no padding', () {
      // Pre-state: darts 1+2 already in dartThrows, dart 3 busts.
      const state = GameState(
        gameId: 'g',
        gameType: GameType.checkoutPractice,
        competitors: [
          CompetitorState(
            competitorId: 'c1',
            name: 'Player 1',
            playerIds: ['p1'],
            score: 30,
            isIn: true,
            dartThrows: ['20', '20'],
            turnStartScore: 70,
          ),
        ],
        currentTurnIndex: 0,
        dartsThrownInTurn: 2,
        isComplete: false,
        status: GameEngineStatus.inProgress,
        turnActive: true,
        startingScore: 170,
      );
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.isBust, isTrue);
      expect(result.state.competitors[0].dartThrows, ['20', '20', 'T20']);
    });

    test('score landing on 1 is a bust', () {
      // Score 21, throw 20 (single) → newScore = 1
      final state = _makeState(score: 21, turnActive: true, turnStartScore: 21);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.isBust, isTrue);
      expect(result.state.competitors[0].score, 21);
    });

    test('score reaching 0 on non-double (single) is a bust', () {
      // Score 20, throw 20 (single) → newScore = 0, not double
      final state = _makeState(score: 20, turnActive: true, turnStartScore: 20);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.isBust, isTrue);
      expect(result.state.competitors[0].score, 20);
    });

    test('score reaching 0 on triple is a bust', () {
      // Score 60, throw T20 (60) → newScore = 0, not double
      final state = _makeState(score: 60, turnActive: true, turnStartScore: 60);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.isBust, isTrue);
    });

    test('bust outcome is LegOutcome.none', () {
      final state = _makeState(score: 20, turnActive: true, turnStartScore: 20);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.outcome, LegOutcome.none);
    });
  });

  // -------------------------------------------------------------------------
  // Checkout detection
  // -------------------------------------------------------------------------
  group('Checkout detection', () {
    test('score reaching 0 on D20 is a checkout', () {
      // Score 40, throw D20 (40) → newScore = 0, double → checkout
      final state = _makeState(score: 40, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c1');
    });

    test('checkout sets score to 0', () {
      final state = _makeState(score: 40, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.state.competitors[0].score, 0);
    });

    test('checkout dart is added to dartThrows', () {
      final state = _makeState(score: 40, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.state.competitors[0].dartThrows, contains('D20'));
    });

    test('DB checkout is recognized', () {
      // Score 50, throw DB (50) → newScore = 0, double → checkout
      final state = _makeState(score: 50, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2));
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('checkout from 170: T20, T20, DB', () {
      var state = _makeState(score: 170, turnActive: true);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      expect(state.competitors[0].score, 110);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      expect(state.competitors[0].score, 50);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.competitors[0].score, 0);
      expect(result.state.competitors[0].dartThrows, ['T20', 'T20', 'DB']);
    });

    test('isBust is false on checkout', () {
      final state = _makeState(score: 40, turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.isBust, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // TurnEnded
  // -------------------------------------------------------------------------
  group('TurnEnded', () {
    test('resets dartsThrownInTurn to 0', () {
      final state = _makeState(dartsThrownInTurn: 3, turnActive: true);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.dartsThrownInTurn, 0);
    });

    test('sets turnActive to false', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.turnActive, isFalse);
    });

    test('does not change score', () {
      final state = _makeState(score: 50, turnActive: true, dartsThrownInTurn: 3);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.competitors[0].score, 50);
    });
  });

  // -------------------------------------------------------------------------
  // GameCompleted (manual end)
  // -------------------------------------------------------------------------
  group('GameCompleted', () {
    test('sets isComplete to true, status to completed, turnActive to false', () {
      final state = _makeState();
      final result = engine.apply(
          state, _event(type: 'GameCompleted', payload: {'winner_id': null}));
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.state.turnActive, isFalse);
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('manual end has no winner (winner_id null)', () {
      final state = _makeState();
      final result = engine.apply(
          state, _event(type: 'GameCompleted', payload: {'winner_id': null}));
      expect(result.state.winnerCompetitorId, isNull);
    });

    test('checkout GameCompleted sets winnerCompetitorId', () {
      final state = _makeState();
      final result = engine.apply(
          state, _event(type: 'GameCompleted', payload: {'winner_id': 'c1'}));
      expect(result.state.winnerCompetitorId, 'c1');
    });
  });

  // -------------------------------------------------------------------------
  // isValid rejections
  // -------------------------------------------------------------------------
  group('isValid rejections', () {
    test('DartThrown rejected when isComplete', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(
            state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when dartsThrownInTurn == 3', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
        engine.isValid(
            state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when turnActive is false', () {
      final state = _makeState(turnActive: false);
      expect(
        engine.isValid(
            state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown accepted in normal mid-turn state', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 1);
      expect(
        engine.isValid(
            state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isTrue,
      );
    });

    test('TurnStarted rejected when turnActive is true', () {
      expect(engine.isValid(_makeState(turnActive: true), _turnStarted('c1')), isFalse);
    });

    test('unknown event type always valid', () {
      expect(engine.isValid(_makeState(), _event(type: 'UnknownEvent', payload: {})), isTrue);
    });
  });
}
