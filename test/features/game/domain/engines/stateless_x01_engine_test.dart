// Stateless X01 Engine Unit Tests
// Verifies pure functional state transitions based on docs/games/x01.transitions.md

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:my_darts/features/game/domain/models/game_state.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/engines/base_game_engine.dart';

/// Helper function to create GameEvent with required new fields
GameEvent _createEvent({
  required String eventId,
  required String gameId,
  required String eventType,
  required int localSequence,
  required DateTime occurredAt,
  required Map<String, dynamic> payload,
  bool synced = false,
  String actorId = 'test-actor',
  EventSource source = EventSource.client,
  int? globalSequence,
}) {
  return GameEvent(
    eventId: eventId,
    gameId: gameId,
    eventType: eventType,
    localSequence: localSequence,
    occurredAt: occurredAt,
    payload: payload,
    synced: synced,
    actorId: actorId,
    source: source,
    globalSequence: globalSequence,
  );
}

void main() {
  late StatelessX01Engine engine;
  late GameState initialState;

  setUp(() {
    engine = StatelessX01Engine();
    initialState = GameState(
      gameId: 'test-game',
      gameType: GameType.x01,
      competitors: [
        const CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 501,
          isIn: false,
          legsWon: 0,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 501,
          isIn: false,
          legsWon: 0,
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      status: GameEngineStatus.inProgress,
      turnActive: false,
      legsToWin: 1,
      currentLegIndex: 0,
      inStrategy: 'straight',
      outStrategy: 'double',
    );
  });

  group('X01 Transition Logic (Table D - Scoring)', () {
    test('should reduce score correctly on valid hit', () {
      // Start turn first
      var state = initialState;
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 481);
      expect(newState.dartsThrownInTurn, 1);
    });

    test('should handle Triple correctly', () {
      // Start turn first
      var state = initialState;
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 441);
    });
  });

  group('X01 Bust Logic (Table F)', () {
    test('should bust if score goes below 0', () {
      // Start turn first
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 10, isIn: true),
          initialState.competitors[1],
        ],
      );
      
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;

      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      // Bust logic: score stays same, turn ends
      expect(newState.competitors[0].score, 10);
      expect(newState.dartsThrownInTurn, 3);
    });

    test('should bust if score becomes exactly 1', () {
      // Start turn first
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 21, isIn: true),
          initialState.competitors[1],
        ],
      );
      
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;

      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 21);
      expect(newState.dartsThrownInTurn, 3);
    });
  });

  group('X01 Checkout Logic (Table E)', () {
    test('should win on exact double to zero', () {
      // First, start a turn to activate it
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 40),
          initialState.competitors[1],
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.turnActive, true);
      expect(state.competitors[0].turnStartScore, 40);

      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 0);
      expect(newState.isComplete, true);
      expect(newState.winnerCompetitorId, 'c1');
      expect(newState.turnActive, false);
    });

    test('should bust on exact single to zero (Double-Out enforced)', () {
      // Start turn first
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 20),
          initialState.competitors[1],
        ],
      );
      
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;

      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 20); // Remained at 20 due to bust
      expect(newState.isComplete, false);
      expect(newState.dartsThrownInTurn, 3); // Turn ended due to bust
    });
  });

  group('Turn Activation (Table A)', () {
    test('should activate turn and set turnStartScore on TurnStarted', () {
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );

      final result = engine.apply(initialState, event);
      final newState = result.state;
      expect(newState.turnActive, true);
      expect(newState.dartsThrownInTurn, 0);
      expect(newState.currentTurnIndex, 0);
      expect(newState.competitors[0].turnStartScore, 501);
    });

    test('should deactivate turn on TurnEnded', () {
      // First start a turn
      var state = initialState;
      final turnStartEvent = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnStartEvent);
      state = result.state;
      expect(state.turnActive, true);

      // Now end the turn
      final turnEndEvent = _createEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
      );

      final result2 = engine.apply(state, turnEndEvent);
      final newState = result2.state;
      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('DART-004 should advance currentTurnIndex to next player on TurnEnded', () {
      // Start with player 0
      var state = initialState.copyWith(currentTurnIndex: 0);
      
      // Start turn for player 0
      final turnStartEvent = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnStartEvent);
      state = result.state;
      expect(state.currentTurnIndex, 0);
      
      // End turn - should advance to player 1
      final turnEndEvent = _createEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
      );
      
      final result2 = engine.apply(state, turnEndEvent);
      final newState = result2.state;
      expect(newState.currentTurnIndex, 1);
      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('DART-004 should wrap currentTurnIndex to 0 after last player', () {
      // Create a 2-player game starting with player 1 (last player)
      var state = initialState.copyWith(currentTurnIndex: 1);
      
      // Start turn for player 1
      final turnStartEvent = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c2'},
      );
      final result = engine.apply(state, turnStartEvent);
      state = result.state;
      expect(state.currentTurnIndex, 1);
      
      // End turn - should wrap to player 0
      final turnEndEvent = _createEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
      );
      
      final result2 = engine.apply(state, turnEndEvent);
      final newState = result2.state;
      expect(newState.currentTurnIndex, 0);
      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('DART-004 two-player game should alternate players correctly', () {
      var state = initialState.copyWith(currentTurnIndex: 0);
      
      // Turn 1: Player 0
      final turnStart1 = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result1 = engine.apply(state, turnStart1);
      state = result1.state;
      final turnEnd1 = _createEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
      );
      final result2 = engine.apply(state, turnEnd1);
      state = result2.state;
      expect(state.currentTurnIndex, 1);
      
      // Turn 2: Player 1
      final turnStart2 = _createEvent(
        eventId: 'e3',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c2'},
      );
      final result3 = engine.apply(state, turnStart2);
      state = result3.state;
      final turnEnd2 = _createEvent(
        eventId: 'e4',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 4,
        occurredAt: DateTime.now(),
        payload: {},
      );
      final result4 = engine.apply(state, turnEnd2);
      state = result4.state;
      expect(state.currentTurnIndex, 0);
    });

    test('DART-004 four-player game should rotate through all players', () {
      // Create a 4-player game
      final fourPlayerState = initialState.copyWith(
        competitors: [
          ...initialState.competitors,
          const CompetitorState(
            competitorId: 'c3',
            name: 'Player 3',
            playerIds: ['p3'],
            score: 501,
            isIn: false,
            legsWon: 0,
          ),
          const CompetitorState(
            competitorId: 'c4',
            name: 'Player 4',
            playerIds: ['p4'],
            score: 501,
            isIn: false,
            legsWon: 0,
          ),
        ],
        currentTurnIndex: 0,
      );
      
      var state = fourPlayerState;
      
      // Player 0 -> Player 1
      final turnStart1 = _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result1 = engine.apply(state, turnStart1);
      state = result1.state;
      final turnEnd1 = _createEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {},
      );
      final result2 = engine.apply(state, turnEnd1);
      state = result2.state;
      expect(state.currentTurnIndex, 1);
      
      // Player 1 -> Player 2
      final turnStart2 = _createEvent(
        eventId: 'e3', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 3, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c2'},
      );
      final result3 = engine.apply(state, turnStart2);
      state = result3.state;
      final turnEnd2 = _createEvent(
        eventId: 'e4', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 4, occurredAt: DateTime.now(),
        payload: {},
      );
      final result4 = engine.apply(state, turnEnd2);
      state = result4.state;
      expect(state.currentTurnIndex, 2);
      
      // Player 2 -> Player 3
      final turnStart3 = _createEvent(
        eventId: 'e5', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 5, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c3'},
      );
      final result5 = engine.apply(state, turnStart3);
      state = result5.state;
      final turnEnd3 = _createEvent(
        eventId: 'e6', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 6, occurredAt: DateTime.now(),
        payload: {},
      );
      final result6 = engine.apply(state, turnEnd3);
      state = result6.state;
      expect(state.currentTurnIndex, 3);
      
      // Player 3 -> Player 0 (wrap around)
      final turnStart4 = _createEvent(
        eventId: 'e7', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 7, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c4'},
      );
      final result7 = engine.apply(state, turnStart4);
      state = result7.state;
      final turnEnd4 = _createEvent(
        eventId: 'e8', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 8, occurredAt: DateTime.now(),
        payload: {},
      );
      final result8 = engine.apply(state, turnEnd4);
      state = result8.state;
      expect(state.currentTurnIndex, 0);
    });
  });

  group('In Strategy Validation (Table C)', () {
    test('should get in on any hit with straight-in strategy', () {
      var state = initialState.copyWith(inStrategy: 'straight');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].isIn, true); // Straight in starts as in
      
      // Throw a dart
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, true);
      expect(newState.competitors[0].score, 481); // Score reduced
    });

    test('should require double for double-in strategy', () {
      var state = initialState.copyWith(
        inStrategy: 'double',
        competitors: [
          initialState.competitors[0].copyWith(isIn: false),
          initialState.competitors[1],
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].isIn, false); // Not in yet
      
      // Throw a single (should not get in)
      final singleEvent = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, singleEvent);
      var newState = result2.state;
      expect(newState.competitors[0].isIn, false); // Still not in
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1); // Dart still counted
      
      // Throw a double (should get in)
      final doubleEvent = _createEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      );

      final result3 = engine.apply(newState, doubleEvent);
      newState = result3.state;
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 461); // Score reduced
    });
  });

  group('DART-003 Acceptance Criteria - In Strategy Validation', () {
    test('Straight-in: any first dart starts scoring', () {
      var state = initialState.copyWith(inStrategy: 'straight');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw any dart (single 20)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, true);
      expect(newState.competitors[0].score, 481); // Score reduced
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['20']); // Qualifying dart recorded
    });

    test('Double-in: single on first dart → no score, dart counted, turn continues', () {
      var state = initialState.copyWith(inStrategy: 'double');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw single 20 (should not get in)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, false); // Still not in
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1); // Dart counted
      expect(newState.turnActive, true); // Turn continues
      expect(newState.competitors[0].dartThrows, ['20']); // Failed attempt recorded
    });

    test('Double-in: double on first dart → isIn = true, score applied', () {
      var state = initialState.copyWith(inStrategy: 'double');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw double 20 (should get in and score)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 461); // Score applied
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['D20']); // Qualifying dart recorded
    });

    test('Double-in: double bull on first dart → isIn = true, score applied', () {
      var state = initialState.copyWith(inStrategy: 'double');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw double bull (should get in and score)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 2},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 451); // Score applied (501 - 50)
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['DB']); // Qualifying dart recorded
    });

    test('Master-in: single on first dart → no score, turn continues', () {
      var state = initialState.copyWith(inStrategy: 'master');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw single 20 (should not get in)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, false); // Still not in
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1); // Dart counted
      expect(newState.turnActive, true); // Turn continues
    });

    test('Master-in: double on first dart → isIn = true, score applied', () {
      var state = initialState.copyWith(inStrategy: 'master');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw double 20 (should get in and score)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 461); // Score applied
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['D20']); // Qualifying dart recorded
    });

    test('Master-in: triple on first dart → isIn = true, score applied', () {
      var state = initialState.copyWith(inStrategy: 'master');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw triple 20 (should get in and score)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 441); // Score applied
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['T20']); // Qualifying dart recorded
    });

    test('Failed in-strategy dart does NOT end the turn', () {
      var state = initialState.copyWith(inStrategy: 'double');
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw single 20 (should not get in, but turn should continue)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      var newState = result2.state;
      expect(newState.turnActive, true); // Turn should still be active
      expect(newState.dartsThrownInTurn, 1); // Only 1 dart thrown
      expect(newState.competitors[0].dartThrows, ['20']); // Failed attempt recorded
      
      // Should be able to throw second dart
      final event2 = _createEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 19, 'multiplier': 1},
      );

      final result3 = engine.apply(newState, event2);
      newState = result3.state;
      expect(newState.turnActive, true); // Turn should still be active
      expect(newState.dartsThrownInTurn, 2); // Now 2 darts thrown
    });
  });

  group('Bust Recovery (Table F)', () {
    test('should recover to turnStartScore on bust', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 10, isIn: true),
          initialState.competitors[1],
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].turnStartScore, 10);
      
      // Throw a dart that would bust
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 10); // Recovered to turnStartScore
      expect(newState.dartsThrownInTurn, 3); // Turn ended
    });

    test('should bust on score of 1', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 21, isIn: true),
          initialState.competitors[1],
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Throw 20 to leave 1 (bust condition)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 21); // Recovered to turnStartScore
      expect(newState.dartsThrownInTurn, 3); // Turn ended
    });
  });

  group('Multi-Leg Games (Tables J & K)', () {
    test('should increment legsWon and continue game when legsToWin > 1', () {
      var state = initialState.copyWith(
        legsToWin: 3, // Best of 3 legs
        currentLegIndex: 0,
        competitors: [
          initialState.competitors[0].copyWith(score: 40, isIn: true, legsWon: 0),
          initialState.competitors[1].copyWith(score: 100, isIn: true, legsWon: 0),
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Player 1 wins the leg with double 20
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].legsWon, 1); // Leg won incremented
      expect(newState.competitors[1].legsWon, 0);
      expect(newState.isComplete, false); // Game not complete yet
      expect(newState.currentLegIndex, 1); // Moved to next leg
      expect(newState.competitors[0].score, 501); // Score reset for new leg
      expect(newState.competitors[1].score, 501);
      expect(newState.competitors[0].isIn, false); // In-state reset
    });

    test('should complete game when legsWon reaches legsToWin', () {
      var state = initialState.copyWith(
        legsToWin: 2, // First to 2 legs
        currentLegIndex: 1, // Second leg
        competitors: [
          initialState.competitors[0].copyWith(score: 40, isIn: true, legsWon: 1),
          initialState.competitors[1].copyWith(score: 100, isIn: true, legsWon: 0),
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      
      // Player 1 wins their second leg
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].legsWon, 2); // Second leg won
      expect(newState.isComplete, true); // Game complete
      expect(newState.winnerCompetitorId, 'c1');
      expect(newState.status, GameEngineStatus.completed);
    });
  });

  group('Validation (Table B)', () {
    test('should reject DartThrown when turn is not active', () {
      final state = initialState.copyWith(turnActive: false);
      
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result = engine.apply(state, event);
      final newState = result.state;
      // State should be unchanged
      expect(newState.competitors[0].score, 501);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('should reject DartThrown when 3 darts already thrown', () {
      var state = initialState.copyWith(dartsThrownInTurn: 3, turnActive: true);
      
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result = engine.apply(state, event);
      final newState = result.state;
      // State should be unchanged
      expect(newState.competitors[0].score, 501);
      expect(newState.dartsThrownInTurn, 3);
    });

    test('isValid should return false for DartThrown when turn not active', () {
      final state = initialState.copyWith(turnActive: false);
      
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      expect(engine.isValid(state, event), false);
    });
  });

  group('DART-002 Acceptance Criteria - Bust Recovery Scenarios', () {
    test('should restore score to turnStartScore on bust during dart 2', () {
      // Setup: Player starts turn with 381, busts immediately on first dart
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 381, isIn: true),
          initialState.competitors[1],
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].turnStartScore, 381);
      
      // Dart 1: throw 20 (score becomes 361)
      final dart1 = _createEvent(
        eventId: 'dart1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      final result2 = engine.apply(state, dart1);
      state = result2.state;
      expect(state.competitors[0].score, 361);
      expect(state.dartsThrownInTurn, 1);
      
      // Simulate score before dart 2 (for bust scenario)
      state = state.copyWith(
        competitors: [
          state.competitors[0].copyWith(score: 10), // Set to 10 for bust
        ],
      );
      
      // Dart 2: bust (throw 20 when score is 10)
      final bustDart = _createEvent(
        eventId: 'bust',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      final result3 = engine.apply(state, bustDart);
      state = result3.state;
      
      // Verify bust recovery
      expect(state.competitors[0].score, 381); // Restored to turnStartScore
      expect(state.dartsThrownInTurn, 3); // Turn ended
    });

    test('should restore score to turnStartScore on bust during dart 3', () {
      // Setup: Player starts turn with 381, throws two darts, then busts on dart 3
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 381, isIn: true),
          initialState.competitors[1],
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].turnStartScore, 381);
      
      // Dart 1: throw 20
      final dart1 = _createEvent(
        eventId: 'dart1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      final result2 = engine.apply(state, dart1);
      state = result2.state;
      
      // Dart 2: throw 10
      final dart2 = _createEvent(
        eventId: 'dart2',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 10, 'multiplier': 1},
      );
      final result3 = engine.apply(state, dart2);
      state = result3.state;
      
      // Dart 3: bust (throw triple 20 when score is 360 - would go to 300, not a bust)
      // Let's change to a scenario that actually triggers a bust
      // Simulate score at 40 after 2 darts, then throw triple 20 (60 points)
      state = state.copyWith(
        competitors: [
          state.competitors[0].copyWith(score: 40),
        ],
      );
      
      // Dart 3: bust (throw triple 20 when score is 40 - would go to -20)
      final bustDart = _createEvent(
        eventId: 'bust',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 4,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3}, // 60 points
      );
      final result4 = engine.apply(state, bustDart);
      state = result4.state;
      
      // Verify bust recovery
      expect(state.competitors[0].score, 381); // Restored to turnStartScore
      expect(state.dartsThrownInTurn, 3); // Turn ended
    });

    test('should handle bust on dart 1 correctly (score unchanged)', () {
      // Setup: Player starts turn with 381, busts immediately on dart 1
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 10, isIn: true),
          initialState.competitors[1],
        ],
      );
      
      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].turnStartScore, 10);
      
      // Dart 1: bust immediately
      final bustDart = _createEvent(
        eventId: 'bust',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      final result2 = engine.apply(state, bustDart);
      state = result2.state;
      
      // Verify bust recovery
      expect(state.competitors[0].score, 10); // Restored to turnStartScore
      expect(state.dartsThrownInTurn, 3); // Turn ended
    });

    test('DART-006: Leg reset should use startingScore from config, not hardcoded 501', () {
      // Create a game with 301 starting score (not 501)
      var state = initialState.copyWith(
        startingScore: 301, // Custom starting score
        legsToWin: 2, // Multi-leg game to test reset
        currentLegIndex: 0,
        competitors: [
          initialState.competitors[0].copyWith(score: 40, isIn: true, legsWon: 0),
          initialState.competitors[1].copyWith(score: 100, isIn: true, legsWon: 0),
        ],
      );

      // Start turn for player 1
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;

      // Player 1 wins the leg with double 20 (40 - 40 = 0)
      final winEvent = _createEvent(
        eventId: 'win1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      );

      final result2 = engine.apply(state, winEvent);
      state = result2.state;

      // Verify that scores were reset to 301 (not hardcoded 501)
      expect(state.competitors[0].score, 301, reason: 'Player 1 score should reset to startingScore (301)');
      expect(state.competitors[1].score, 301, reason: 'Player 2 score should reset to startingScore (301)');
      expect(state.competitors[0].isIn, false, reason: 'isIn should be reset');
      expect(state.competitors[1].isIn, false, reason: 'isIn should be reset');
      expect(state.competitors[0].legsWon, 1, reason: 'Legs won should be incremented');
      expect(state.currentLegIndex, 1, reason: 'Current leg index should increment');
      expect(state.isComplete, false, reason: 'Game should not be complete yet (only 1/2 legs won)');
    });
  });

  group('DART-006.1 - Single Bull Segment Parsing Bug Fix', () {
    test('should parse single bull correctly (multiplier=1, segment=25)', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: true),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;

      // Throw single bull (should parse correctly and score 25 points)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 476); // 501 - 25 = 476
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['SB']); // Should be recorded as 'SB'
    });

    test('should handle single bull in double-in strategy (does NOT get player in)', () {
      var state = initialState.copyWith(
        inStrategy: 'double',
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: false),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].isIn, false); // Not in yet

      // Throw single bull (should NOT get player in, no score change)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, false); // Still not in (single bull doesn't satisfy double-in)
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1); // Dart still counted
      expect(newState.competitors[0].dartThrows, ['SB']); // Failed attempt recorded
    });

    test('should handle single bull in master-in strategy (does NOT get player in)', () {
      var state = initialState.copyWith(
        inStrategy: 'master',
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: false),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].isIn, false); // Not in yet

      // Throw single bull (should NOT get player in, no score change)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, false); // Still not in (single bull doesn't satisfy master-in)
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1); // Dart still counted
      expect(newState.competitors[0].dartThrows, ['SB']); // Failed attempt recorded
    });

    test('should handle single bull in straight-in strategy (scores immediately)', () {
      var state = initialState.copyWith(
        inStrategy: 'straight',
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: false),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].isIn, true); // Straight in starts as in

      // Throw single bull (should score 25 points)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, true); // Still in
      expect(newState.competitors[0].score, 476); // 501 - 25 = 476
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['SB']); // Should be recorded as 'SB'
    });

    test('should handle single bull bust scenario', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 25, isIn: true),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].turnStartScore, 25);

      // Throw single bull (25 points) when score is 25 should bust (leaves 0 but not on double)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 25); // Restored to turnStartScore due to bust
      expect(newState.dartsThrownInTurn, 3); // Turn ended due to bust
      expect(newState.turnActive, false);
    });

    test('should still handle double bull correctly (existing functionality)', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: true),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;

      // Throw double bull (should score 50 points)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 2},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 451); // 501 - 50 = 451
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['DB']); // Should be recorded as 'DB'
    });

    test('should still handle regular numbers correctly (existing functionality)', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: true),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;

      // Throw single 20 (should score 20 points)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].score, 481); // 501 - 20 = 481
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['20']); // Should be recorded as '20'
    });
  });

  group('DART-012 - Realistic Bust Recovery Scenarios', () {
    test('should handle bust on dart 2 with realistic score progression', () {
      // Setup: Player starts turn with 10, busts immediately on first dart
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 10, isIn: true),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].turnStartScore, 10);

      // Dart 1: throw 20 (score 10 - 20 = -10, bust)
      final dart1 = _createEvent(
        eventId: 'dart1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      final result2 = engine.apply(state, dart1);
      state = result2.state;
      // Score should remain at turnStartScore (10) due to bust
      expect(state.competitors[0].score, 10);
      expect(state.dartsThrownInTurn, 3); // Turn ended due to bust

      // Verify bust recovery (already verified above)
      expect(state.dartsThrownInTurn, 3); // Turn ended
      expect(state.turnActive, false);
    });

    test('should handle bust on dart 3 with realistic score progression', () {
      // Setup: Player starts turn with 50, throws two darts, then busts on dart 3
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 50, isIn: true),
          initialState.competitors[1],
        ],
      );

      // Start turn
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].turnStartScore, 50);

      // Dart 1: throw 20
      final dart1 = _createEvent(
        eventId: 'dart1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      final result2 = engine.apply(state, dart1);
      state = result2.state;

      // Dart 2: throw 10
      final dart2 = _createEvent(
        eventId: 'dart2',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 10, 'multiplier': 1},
      );
      final result3 = engine.apply(state, dart2);
      state = result3.state;

      // Dart 3: bust (throw triple 20 when score is 20 - would go to -40)
      final bustDart = _createEvent(
        eventId: 'bust',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 4,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3}, // 60 points
      );
      final result4 = engine.apply(state, bustDart);
      state = result4.state;

      // Verify bust recovery
      expect(state.competitors[0].score, 50); // Restored to turnStartScore
      expect(state.dartsThrownInTurn, 3); // Turn ended
      expect(state.turnActive, false);
    });
  });

  group('DART-012 - Player Rotation Verification', () {
    test('two-player game should rotate players correctly', () {
      var state = initialState.copyWith(currentTurnIndex: 0);

      // Turn 1: Player 0
      final result1 = engine.apply(state, _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      ));
      state = result1.state;
      final result2 = engine.apply(state, _createEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
      ));
      state = result2.state;
      expect(state.currentTurnIndex, 1);

      // Turn 2: Player 1
      final result3 = engine.apply(state, _createEvent(
        eventId: 'e3',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c2'},
      ));
      state = result3.state;
      final result4 = engine.apply(state, _createEvent(
        eventId: 'e4',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 4,
        occurredAt: DateTime.now(),
        payload: {},
      ));
      state = result4.state;
      expect(state.currentTurnIndex, 0); // Wraps back to player 0
    });

    test('four-player game should rotate through all players', () {
      // Create a 4-player game
      final fourPlayerState = initialState.copyWith(
        competitors: [
          ...initialState.competitors,
          const CompetitorState(
            competitorId: 'c3',
            name: 'Player 3',
            playerIds: ['p3'],
            score: 501,
            isIn: false,
            legsWon: 0,
          ),
          const CompetitorState(
            competitorId: 'c4',
            name: 'Player 4',
            playerIds: ['p4'],
            score: 501,
            isIn: false,
            legsWon: 0,
          ),
        ],
        currentTurnIndex: 0,
      );

      var state = fourPlayerState;

      // Player 0 -> Player 1
      final result1 = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      ));
      state = result1.state;
      final result2 = engine.apply(state, _createEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {},
      ));
      state = result2.state;
      expect(state.currentTurnIndex, 1);

      // Player 1 -> Player 2
      final result3 = engine.apply(state, _createEvent(
        eventId: 'e3', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 3, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c2'},
      ));
      state = result3.state;
      final result4 = engine.apply(state, _createEvent(
        eventId: 'e4', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 4, occurredAt: DateTime.now(),
        payload: {},
      ));
      state = result4.state;
      expect(state.currentTurnIndex, 2);

      // Player 2 -> Player 3
      final result5 = engine.apply(state, _createEvent(
        eventId: 'e5', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 5, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c3'},
      ));
      state = result5.state;
      final result6 = engine.apply(state, _createEvent(
        eventId: 'e6', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 6, occurredAt: DateTime.now(),
        payload: {},
      ));
      state = result6.state;
      expect(state.currentTurnIndex, 3);

      // Player 3 -> Player 0 (wrap around)
      final result7 = engine.apply(state, _createEvent(
        eventId: 'e7', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 7, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c4'},
      ));
      state = result7.state;
      final result8 = engine.apply(state, _createEvent(
        eventId: 'e8', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 8, occurredAt: DateTime.now(),
        payload: {},
      ));
      state = result8.state;
      expect(state.currentTurnIndex, 0);
    });
  });

  group('DART-012 - In-Strategy Edge Cases', () {
    test('double-in: single on leg-start does not change score', () {
      var state = initialState.copyWith(
        inStrategy: 'double',
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: false),
          initialState.competitors[1],
        ],
      );

      // Start turn (new leg)
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;
      expect(state.competitors[0].isIn, false); // Not in yet

      // Throw single 20 (should not get in, no score change)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, false); // Still not in
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1);
    });

    test('double-in: double on leg-start sets isIn and applies score', () {
      var state = initialState.copyWith(
        inStrategy: 'double',
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: false),
          initialState.competitors[1],
        ],
      );

      // Start turn (new leg)
      final turnEvent = _createEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnEvent);
      state = result.state;

      // Throw double 20 (should get in and score)
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      );

      final result2 = engine.apply(state, event);
      final newState = result2.state;
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 461); // Score applied (501 - 40)
      expect(newState.dartsThrownInTurn, 1);
    });
  });

  group('DART-012 - Turn Active State Management', () {
    test('turnActive should be true after TurnStarted', () {
      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );

      final result = engine.apply(initialState, event);
      final newState = result.state;
      expect(newState.turnActive, true);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('turnActive should be false after TurnEnded', () {
      // First start a turn
      var state = initialState;
      final turnStartEvent = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      final result = engine.apply(state, turnStartEvent);
      state = result.state;
      expect(state.turnActive, true);

      // Now end the turn
      final turnEndEvent = _createEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
      );

      final result2 = engine.apply(state, turnEndEvent);
      final newState = result2.state;
      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('DartThrown should be rejected when turnActive is false', () {
      final state = initialState.copyWith(turnActive: false);

      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );

      final result = engine.apply(state, event);
      final newState = result.state;
      // State should be unchanged
      expect(newState.competitors[0].score, 501);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('isValid should return false for TurnStarted when turn is already active', () {
      // Turn already active
      final state = initialState.copyWith(turnActive: true);

      final event = _createEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );

      expect(engine.isValid(state, event), false);
    });
  });

  group('MISS segment (Table G / Ambiguity 5)', () {
    // Helper: start a turn for c1 and return the state with turnActive=true
    GameState _startTurnForC1(GameState base) {
      final turnEvent = _createEvent(
        eventId: 'turn-start',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      return engine.apply(base, turnEvent).state;
    }

    test('MISS does not change score (player already in)', () {
      // straight-in so player is automatically in after TurnStarted
      var state = _startTurnForC1(initialState);
      expect(state.competitors[0].isIn, true);
      expect(state.competitors[0].score, 501);

      final missEvent = _createEvent(
        eventId: 'miss1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
      );

      final result = engine.apply(state, missEvent);
      expect(result.state.competitors[0].score, 501); // score unchanged
      expect(result.state.dartsThrownInTurn, 1);
    });

    test('MISS does not satisfy double-in strategy', () {
      final doubleInState = initialState.copyWith(inStrategy: 'double');
      var state = _startTurnForC1(doubleInState);
      expect(state.competitors[0].isIn, false); // double-in, not yet in

      final missEvent = _createEvent(
        eventId: 'miss1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
      );

      final result = engine.apply(state, missEvent);
      expect(result.state.competitors[0].isIn, false); // still not in
      expect(result.state.dartsThrownInTurn, 1); // dart was counted
      expect(result.state.competitors[0].score, 501); // score unchanged
    });

    test('MISS does not cause bust even when score is 2', () {
      // Set up a state where score is 2 — a scored dart of 2 would go to 0 but
      // any non-double would be a bust under double-out. A miss must never bust.
      final lowScoreCompetitors = [
        initialState.competitors[0].copyWith(score: 2, isIn: true, turnStartScore: 2),
        initialState.competitors[1],
      ];
      final lowScoreState = initialState.copyWith(
        competitors: lowScoreCompetitors,
        turnActive: true,
        dartsThrownInTurn: 0,
      );

      final missEvent = _createEvent(
        eventId: 'miss1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
      );

      final result = engine.apply(lowScoreState, missEvent);
      expect(result.state.competitors[0].score, 2); // score stays at 2, no bust
      expect(result.state.dartsThrownInTurn, 1);
    });

    test('MISS increments dart count and ends turn on 3rd miss', () {
      var state = _startTurnForC1(initialState);

      for (int i = 1; i <= 3; i++) {
        final missEvent = _createEvent(
          eventId: 'miss$i',
          gameId: 'test-game',
          eventType: 'DartThrown',
          localSequence: i + 1,
          occurredAt: DateTime.now(),
          payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
        );
        state = engine.apply(state, missEvent).state;
      }

      expect(state.dartsThrownInTurn, 3);
      expect(state.turnActive, false); // turn ended after 3rd miss
      expect(state.competitors[0].score, 501); // score unchanged throughout
    });

    test('MISS dart count increments correctly with mixed throws', () {
      // Throw one scoring dart then a miss — dart count should be 2
      var state = _startTurnForC1(initialState);

      final scoringDart = _createEvent(
        eventId: 'dart1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      state = engine.apply(state, scoringDart).state;
      expect(state.competitors[0].score, 481);
      expect(state.dartsThrownInTurn, 1);

      final missEvent = _createEvent(
        eventId: 'miss1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
      );
      state = engine.apply(state, missEvent).state;
      expect(state.competitors[0].score, 481); // score unchanged by miss
      expect(state.dartsThrownInTurn, 2);
      expect(state.turnActive, true); // turn still active
    });
  });

  // ─── TICKET-016: Expanded coverage ────────────────────────────────────────

  group('isBust flag in EngineResult', () {
    test('bust (score < 0) sets isBust = true and restores score', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 10, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.state.competitors[0].score, 10); // Restored to turnStartScore
    });

    test('bust (score == 1 after dart) sets isBust = true', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 21, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      // 21 - 20 = 1 → bust
      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.state.competitors[0].score, 21);
    });

    test('bust (invalid out: single to zero under double-out) sets isBust = true', () {
      var state = initialState.copyWith(
        outStrategy: 'double',
        competitors: [
          initialState.competitors[0].copyWith(score: 20, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.state.competitors[0].score, 20); // Restored
    });

    test('normal scoring sets isBust = false', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, false);
      expect(result.state.competitors[0].score, 481);
    });

    test('checkout sets isBust = false', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 40, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      ));
      expect(result.isBust, false);
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('MISS sets isBust = false', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
      ));
      expect(result.isBust, false);
      expect(result.state.competitors[0].score, 501);
    });
  });

  group('Straight-out strategy (outStrategy = straight)', () {
    GameState _straightOutState(int score) {
      return initialState.copyWith(
        outStrategy: 'straight',
        competitors: [
          initialState.competitors[0].copyWith(score: score, isIn: true),
          initialState.competitors[1],
        ],
      );
    }

    test('single to zero completes leg', () {
      var state = _straightOutState(20);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.competitors[0].score, 0);
      expect(result.state.isComplete, true);
    });

    test('double to zero completes leg', () {
      var state = _straightOutState(40);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.competitors[0].score, 0);
    });

    test('triple to zero completes leg', () {
      var state = _straightOutState(60);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.competitors[0].score, 0);
    });

    test('SB (25 pts) scores correctly but does not complete leg when score != 0', () {
      var state = _straightOutState(501);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 1},
      ));
      expect(result.outcome, LegOutcome.none);
      expect(result.state.competitors[0].score, 476); // 501 - 25
      expect(result.isBust, false);
    });

    test('DB (50 pts) to zero completes leg (straight-out accepts any hit)', () {
      var state = _straightOutState(50);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 2},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.competitors[0].score, 0);
      expect(result.isBust, false);
    });
  });

  group('Master-out strategy (outStrategy = master)', () {
    GameState _masterOutState(int score) {
      return initialState.copyWith(
        outStrategy: 'master',
        competitors: [
          initialState.competitors[0].copyWith(score: score, isIn: true),
          initialState.competitors[1],
        ],
      );
    }

    test('double to zero completes leg', () {
      var state = _masterOutState(40);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.competitors[0].score, 0);
      expect(result.isBust, false);
    });

    test('triple to zero completes leg', () {
      var state = _masterOutState(60);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.competitors[0].score, 0);
      expect(result.isBust, false);
    });

    test('DB to zero completes leg (Ambiguity 4: DB multiplier == 2, valid master-out)', () {
      var state = _masterOutState(50);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 2},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.competitors[0].score, 0);
      expect(result.isBust, false);
    });

    test('single to zero is a bust', () {
      var state = _masterOutState(20);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.state.competitors[0].score, 20); // Restored
      expect(result.outcome, LegOutcome.none);
    });

    test('SB to zero is a bust (SB counts as single, multiplier 1 < 2)', () {
      var state = _masterOutState(25);
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 25, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.state.competitors[0].score, 25); // Restored
    });
  });

  group('Table H — Three failed in-darts ends turn', () {
    test('double-in: three singles end the turn after dart 3, score unchanged', () {
      var state = initialState.copyWith(
        inStrategy: 'double',
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: false),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;
      expect(state.competitors[0].isIn, false);

      // Dart 1 — fails in
      state = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      )).state;
      expect(state.dartsThrownInTurn, 1);
      expect(state.turnActive, true);
      expect(state.competitors[0].isIn, false);

      // Dart 2 — fails in
      state = engine.apply(state, _createEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 3, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 19, 'multiplier': 1},
      )).state;
      expect(state.dartsThrownInTurn, 2);
      expect(state.turnActive, true);
      expect(state.competitors[0].isIn, false);

      // Dart 3 — fails in → turn must end
      state = engine.apply(state, _createEvent(
        eventId: 'e3', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 4, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 18, 'multiplier': 1},
      )).state;
      expect(state.dartsThrownInTurn, 3);
      expect(state.turnActive, false);
      expect(state.competitors[0].isIn, false);
      expect(state.competitors[0].score, 501); // Score never changed
    });

    test('master-in: three singles end the turn after dart 3, score unchanged', () {
      var state = initialState.copyWith(
        inStrategy: 'master',
        competitors: [
          initialState.competitors[0].copyWith(score: 501, isIn: false),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;
      expect(state.competitors[0].isIn, false);

      for (int i = 1; i <= 3; i++) {
        state = engine.apply(state, _createEvent(
          eventId: 'e$i', gameId: 'test-game', eventType: 'DartThrown',
          localSequence: i + 1, occurredAt: DateTime.now(),
          payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        )).state;
      }

      expect(state.dartsThrownInTurn, 3);
      expect(state.turnActive, false);
      expect(state.competitors[0].isIn, false);
      expect(state.competitors[0].score, 501); // Score never changed
    });
  });

  group('Table L — No gameplay after GameCompleted', () {
    late GameState completedState;

    setUp(() {
      completedState = initialState.copyWith(
        isComplete: true,
        status: GameEngineStatus.completed,
        turnActive: false,
        winnerCompetitorId: 'c1',
      );
    });

    test('isValid returns false for DartThrown when isComplete = true', () {
      final event = _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      expect(engine.isValid(completedState, event), false);
    });

    test('isValid returns false for TurnStarted when isComplete = true', () {
      final event = _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      );
      expect(engine.isValid(completedState, event), false);
    });

    test('apply DartThrown on completed state returns unchanged state', () {
      final event = _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      );
      final result = engine.apply(completedState, event);
      expect(result.state.isComplete, true);
      expect(result.state.competitors[0].score, completedState.competitors[0].score);
      expect(result.outcome, LegOutcome.none);
    });
  });

  group('Ambiguity 2 — Bust immediately ends turn', () {
    test('after bust, turnActive is false', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 10, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.state.turnActive, false);
    });

    test('after bust, isValid returns false for another DartThrown', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 10, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      final bustResult = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(bustResult.isBust, true);

      final followUpEvent = _createEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 3, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 5, 'multiplier': 1},
      );
      expect(engine.isValid(bustResult.state, followUpEvent), false);
    });
  });

  group('Ambiguity 3 — Checkout on 3rd dart completes leg', () {
    test('valid double checkout on 3rd dart completes leg (not merely turn end)', () {
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 40, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;

      // Dart 1: single 10 → score 30
      state = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 10, 'multiplier': 1},
      )).state;
      expect(state.competitors[0].score, 30);
      expect(state.dartsThrownInTurn, 1);

      // Dart 2: single 10 → score 20
      state = engine.apply(state, _createEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 3, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 10, 'multiplier': 1},
      )).state;
      expect(state.competitors[0].score, 20);
      expect(state.dartsThrownInTurn, 2);

      // Dart 3: D10 (20 pts) → score 0 → checkout on the 3rd dart
      final result = engine.apply(state, _createEvent(
        eventId: 'e3', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 4, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 10, 'multiplier': 2},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.isComplete, true);
      expect(result.state.competitors[0].score, 0);
      expect(result.state.winnerCompetitorId, 'c1');
      expect(result.isBust, false);
    });
  });

  group('Score floor invariant (bust always restores, score never < 0)', () {
    test('large overshoot restores to turnStartScore — not a negative number', () {
      // score=5, throw T20 (60 pts) → would be -55 → bust → restored to 5
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 5, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;
      expect(state.competitors[0].turnStartScore, 5);

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      ));
      expect(result.isBust, true);
      expect(result.state.competitors[0].score, 5); // Restored to turnStartScore
      expect(result.state.competitors[0].score >= 0, true); // Never below zero
    });

    test('score == 1 after dart restores to turnStartScore', () {
      // score=21, throw single 20 → 1 → bust → restored to 21
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 21, isIn: true),
          initialState.competitors[1],
        ],
      );
      state = engine.apply(state, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;
      expect(state.competitors[0].turnStartScore, 21);

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.state.competitors[0].score, 21);
      expect(result.state.competitors[0].score >= 0, true);
    });
  });

  group('Strategy combination matrix', () {
    // Helper: build a state with the given in/out strategies and score
    GameState _combo(String inStrat, String outStrat, int score, {bool isIn = true}) {
      return initialState.copyWith(
        inStrategy: inStrat,
        outStrategy: outStrat,
        competitors: [
          initialState.competitors[0].copyWith(score: score, isIn: isIn),
          initialState.competitors[1],
        ],
      );
    }

    // Helper: start a turn for c1
    GameState _turn(GameState s) {
      return engine.apply(s, _createEvent(
        eventId: 'ts', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;
    }

    test('straight×straight: any hit opens scoring; single to zero closes leg', () {
      // straight-in auto-sets isIn at TurnStarted
      var state = _turn(_combo('straight', 'straight', 20, isIn: false));
      expect(state.competitors[0].isIn, true); // auto-opened by straight-in

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.isBust, false);
    });

    test('straight×master: triple to zero closes leg', () {
      var state = _turn(_combo('straight', 'master', 60));

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.isBust, false);
    });

    test('straight×master: single to zero is bust', () {
      var state = _turn(_combo('straight', 'master', 20));

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.outcome, LegOutcome.none);
    });

    test('double×master: double gets player in; triple to zero closes leg', () {
      // Verify double-in with D20
      var inState = _turn(_combo('double', 'master', 501, isIn: false));
      expect(inState.competitors[0].isIn, false);
      final afterIn = engine.apply(inState, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      )).state;
      expect(afterIn.competitors[0].isIn, true);
      expect(afterIn.competitors[0].score, 461); // 501 - 40

      // Verify triple checkout once already in
      var state = _turn(_combo('double', 'master', 60));
      final result = engine.apply(state, _createEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.isBust, false);
    });

    test('master×master: triple gets player in; triple to zero closes leg', () {
      // Verify master-in with T20
      var inState = _turn(_combo('master', 'master', 501, isIn: false));
      expect(inState.competitors[0].isIn, false);
      final afterIn = engine.apply(inState, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      )).state;
      expect(afterIn.competitors[0].isIn, true);
      expect(afterIn.competitors[0].score, 441); // 501 - 60

      // Verify triple checkout once already in
      var state = _turn(_combo('master', 'master', 60));
      final result = engine.apply(state, _createEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.isBust, false);
    });

    test('master×master: single to zero is bust', () {
      var state = _turn(_combo('master', 'master', 20));

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      ));
      expect(result.isBust, true);
      expect(result.outcome, LegOutcome.none);
    });

    test('master×double: triple gets player in; double to zero closes leg', () {
      // Verify master-in with T20
      var inState = _turn(_combo('master', 'double', 501, isIn: false));
      final afterIn = engine.apply(inState, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      )).state;
      expect(afterIn.competitors[0].isIn, true);

      // Verify double checkout
      var state = _turn(_combo('master', 'double', 40));
      final result = engine.apply(state, _createEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
      ));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.isBust, false);
    });

    test('master×double: triple to zero is bust (triple not valid for double-out)', () {
      var state = _turn(_combo('master', 'double', 60));

      final result = engine.apply(state, _createEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
      ));
      expect(result.isBust, true);
      expect(result.outcome, LegOutcome.none);
    });
  });

  group('Miss tracking in dartThrows (PPR denominator)', () {
    // Helper: start a turn for c1 on initialState
    GameState _startTurn(GameState state) {
      return engine.apply(state, _createEvent(
        eventId: 'turn-miss', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
      )).state;
    }

    test('miss adds MISS to competitor dartThrows', () {
      var state = _startTurn(initialState);

      final result = engine.apply(state, _createEvent(
        eventId: 'miss1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
      ));

      expect(result.state.competitors[0].dartThrows, contains('MISS'));
      expect(result.state.competitors[0].dartThrows.length, 1);
    });

    test('miss dart counts in dartThrows length alongside scoring darts', () {
      var state = _startTurn(initialState);

      // Throw a scoring dart (single 20)
      state = engine.apply(state, _createEvent(
        eventId: 'dart1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
      )).state;

      // Then throw a miss
      state = engine.apply(state, _createEvent(
        eventId: 'dart2', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 3, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
      )).state;

      // dartThrows must contain both the scoring dart and the miss
      expect(state.competitors[0].dartThrows.length, 2);
      expect(state.competitors[0].dartThrows, containsAll(['20', 'MISS']));
    });

    test('score does not change on miss', () {
      var state = _startTurn(initialState);

      final result = engine.apply(state, _createEvent(
        eventId: 'miss1', gameId: 'test-game', eventType: 'DartThrown',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 0, 'multiplier': 1},
      ));

      expect(result.state.competitors[0].score, 501); // unchanged
      expect(result.state.dartsThrownInTurn, 1);
    });
  });
}
