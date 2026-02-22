// Stateless X01 Engine Unit Tests
// Verifies pure functional state transitions based on docs/games/x01.transitions.md

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:my_darts/features/game/domain/models/game_state.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/engines/base_game_engine.dart';

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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].score, 481);
      expect(newState.dartsThrownInTurn, 1);
    });

    test('should handle Triple correctly', () {
      // Start turn first
      var state = initialState;
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
        synced: false,
      );

      final newState = engine.apply(state, event);
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
      
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);

      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
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
      
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);

      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      expect(state.turnActive, true);
      expect(state.competitors[0].turnStartScore, 40);

      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
        synced: false,
      );

      final newState = engine.apply(state, event);
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
      
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);

      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].score, 20); // Remained at 20 due to bust
      expect(newState.isComplete, false);
      expect(newState.dartsThrownInTurn, 3); // Turn ended due to bust
    });
  });

  group('Turn Activation (Table A)', () {
    test('should activate turn and set turnStartScore on TurnStarted', () {
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );

      final newState = engine.apply(initialState, event);
      expect(newState.turnActive, true);
      expect(newState.dartsThrownInTurn, 0);
      expect(newState.currentTurnIndex, 0);
      expect(newState.competitors[0].turnStartScore, 501);
    });

    test('should deactivate turn on TurnEnded', () {
      // First start a turn
      var state = initialState;
      final turnStartEvent = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnStartEvent);
      expect(state.turnActive, true);

      // Now end the turn
      final turnEndEvent = GameEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
      );

      final newState = engine.apply(state, turnEndEvent);
      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('DART-004 should advance currentTurnIndex to next player on TurnEnded', () {
      // Start with player 0
      var state = initialState.copyWith(currentTurnIndex: 0);
      
      // Start turn for player 0
      state = engine.apply(state, GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      ));
      expect(state.currentTurnIndex, 0);
      
      // End turn - should advance to player 1
      final turnEndEvent = GameEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
      );
      
      final newState = engine.apply(state, turnEndEvent);
      expect(newState.currentTurnIndex, 1);
      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('DART-004 should wrap currentTurnIndex to 0 after last player', () {
      // Create a 2-player game starting with player 1 (last player)
      var state = initialState.copyWith(currentTurnIndex: 1);
      
      // Start turn for player 1
      state = engine.apply(state, GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c2'},
        synced: false,
      ));
      expect(state.currentTurnIndex, 1);
      
      // End turn - should wrap to player 0
      final turnEndEvent = GameEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
      );
      
      final newState = engine.apply(state, turnEndEvent);
      expect(newState.currentTurnIndex, 0);
      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('DART-004 two-player game should alternate players correctly', () {
      var state = initialState.copyWith(currentTurnIndex: 0);
      
      // Turn 1: Player 0
      state = engine.apply(state, GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      ));
      state = engine.apply(state, GameEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
      ));
      expect(state.currentTurnIndex, 1);
      
      // Turn 2: Player 1
      state = engine.apply(state, GameEvent(
        eventId: 'e3',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c2'},
        synced: false,
      ));
      state = engine.apply(state, GameEvent(
        eventId: 'e4',
        gameId: 'test-game',
        eventType: 'TurnEnded',
        localSequence: 4,
        occurredAt: DateTime.now(),
        payload: {},
        synced: false,
      ));
      expect(state.currentTurnIndex, 0);
      
      // Turn 3: Back to Player 0
      state = engine.apply(state, GameEvent(
        eventId: 'e5',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 5,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      ));
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
      state = engine.apply(state, GameEvent(
        eventId: 'e1', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 1, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'}, synced: false,
      ));
      state = engine.apply(state, GameEvent(
        eventId: 'e2', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 2, occurredAt: DateTime.now(),
        payload: {}, synced: false,
      ));
      expect(state.currentTurnIndex, 1);
      
      // Player 1 -> Player 2
      state = engine.apply(state, GameEvent(
        eventId: 'e3', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 3, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c2'}, synced: false,
      ));
      state = engine.apply(state, GameEvent(
        eventId: 'e4', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 4, occurredAt: DateTime.now(),
        payload: {}, synced: false,
      ));
      expect(state.currentTurnIndex, 2);
      
      // Player 2 -> Player 3
      state = engine.apply(state, GameEvent(
        eventId: 'e5', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 5, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c3'}, synced: false,
      ));
      state = engine.apply(state, GameEvent(
        eventId: 'e6', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 6, occurredAt: DateTime.now(),
        payload: {}, synced: false,
      ));
      expect(state.currentTurnIndex, 3);
      
      // Player 3 -> Player 0 (wrap around)
      state = engine.apply(state, GameEvent(
        eventId: 'e7', gameId: 'test-game', eventType: 'TurnStarted',
        localSequence: 7, occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c4'}, synced: false,
      ));
      state = engine.apply(state, GameEvent(
        eventId: 'e8', gameId: 'test-game', eventType: 'TurnEnded',
        localSequence: 8, occurredAt: DateTime.now(),
        payload: {}, synced: false,
      ));
      expect(state.currentTurnIndex, 0);
    });
  });

  group('In Strategy Validation (Table C)', () {
    test('should get in on any hit with straight-in strategy', () {
      var state = initialState.copyWith(inStrategy: 'straight');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      expect(state.competitors[0].isIn, true); // Straight in starts as in
      
      // Throw a dart
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      expect(state.competitors[0].isIn, false); // Not in yet
      
      // Throw a single (should not get in)
      final singleEvent = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      var newState = engine.apply(state, singleEvent);
      expect(newState.competitors[0].isIn, false); // Still not in
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1); // Dart still counted
      
      // Throw a double (should get in)
      final doubleEvent = GameEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
        synced: false,
      );

      newState = engine.apply(newState, doubleEvent);
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 461); // Score reduced
    });
  });

  group('DART-003 Acceptance Criteria - In Strategy Validation', () {
    test('Straight-in: any first dart starts scoring', () {
      var state = initialState.copyWith(inStrategy: 'straight');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw any dart (single 20)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].isIn, true);
      expect(newState.competitors[0].score, 481); // Score reduced
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['20']); // Qualifying dart recorded
    });

    test('Double-in: single on first dart → no score, dart counted, turn continues', () {
      var state = initialState.copyWith(inStrategy: 'double');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw single 20 (should not get in)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].isIn, false); // Still not in
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1); // Dart counted
      expect(newState.turnActive, true); // Turn continues
      expect(newState.competitors[0].dartThrows, ['20']); // Failed attempt recorded
    });

    test('Double-in: double on first dart → isIn = true, score applied', () {
      var state = initialState.copyWith(inStrategy: 'double');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw double 20 (should get in and score)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 461); // Score applied
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['D20']); // Qualifying dart recorded
    });

    test('Double-in: double bull on first dart → isIn = true, score applied', () {
      var state = initialState.copyWith(inStrategy: 'double');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw double bull (should get in and score)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 'bull', 'multiplier': 2},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 451); // Score applied (501 - 50)
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['DB']); // Qualifying dart recorded
    });

    test('Master-in: single on first dart → no score, turn continues', () {
      var state = initialState.copyWith(inStrategy: 'master');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw single 20 (should not get in)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].isIn, false); // Still not in
      expect(newState.competitors[0].score, 501); // No score change
      expect(newState.dartsThrownInTurn, 1); // Dart counted
      expect(newState.turnActive, true); // Turn continues
    });

    test('Master-in: double on first dart → isIn = true, score applied', () {
      var state = initialState.copyWith(inStrategy: 'master');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw double 20 (should get in and score)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 461); // Score applied
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['D20']); // Qualifying dart recorded
    });

    test('Master-in: triple on first dart → isIn = true, score applied', () {
      var state = initialState.copyWith(inStrategy: 'master');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw triple 20 (should get in and score)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].isIn, true); // Now in
      expect(newState.competitors[0].score, 441); // Score applied
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.competitors[0].dartThrows, ['T20']); // Qualifying dart recorded
    });

    test('Failed in-strategy dart does NOT end the turn', () {
      var state = initialState.copyWith(inStrategy: 'double');
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw single 20 (should not get in, but turn should continue)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      var newState = engine.apply(state, event);
      expect(newState.turnActive, true); // Turn should still be active
      expect(newState.dartsThrownInTurn, 1); // Only 1 dart thrown
      expect(newState.competitors[0].dartThrows, ['20']); // Failed attempt recorded
      
      // Should be able to throw second dart
      final event2 = GameEvent(
        eventId: 'e2',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 19, 'multiplier': 1},
        synced: false,
      );

      newState = engine.apply(newState, event2);
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      expect(state.competitors[0].turnStartScore, 10);
      
      // Throw a dart that would bust
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Throw 20 to leave 1 (bust condition)
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Player 1 wins the leg with double 20
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
        synced: false,
      );

      final newState = engine.apply(state, event);
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      
      // Player 1 wins their second leg
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
        synced: false,
      );

      final newState = engine.apply(state, event);
      expect(newState.competitors[0].legsWon, 2); // Second leg won
      expect(newState.isComplete, true); // Game complete
      expect(newState.winnerCompetitorId, 'c1');
      expect(newState.status, GameEngineStatus.completed);
    });
  });

  group('Validation (Table B)', () {
    test('should reject DartThrown when turn is not active', () {
      final state = initialState.copyWith(turnActive: false);
      
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
      // State should be unchanged
      expect(newState.competitors[0].score, 501);
      expect(newState.dartsThrownInTurn, 0);
    });

    test('should reject DartThrown when 3 darts already thrown', () {
      var state = initialState.copyWith(dartsThrownInTurn: 3, turnActive: true);
      
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(state, event);
      // State should be unchanged
      expect(newState.competitors[0].score, 501);
      expect(newState.dartsThrownInTurn, 3);
    });

    test('isValid should return false for DartThrown when turn not active', () {
      final state = initialState.copyWith(turnActive: false);
      
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      expect(engine.isValid(state, event), false);
    });
  });

  group('DART-002 Acceptance Criteria - Bust Recovery Scenarios', () {
    test('should restore score to turnStartScore on bust during dart 2', () {
      // Setup: Player starts turn with 381, throws one dart (score 361), then busts on dart 2
      var state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 381, isIn: true),
          initialState.competitors[1],
        ],
      );
      
      // Start turn
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      expect(state.competitors[0].turnStartScore, 381);
      
      // Dart 1: throw 20 (score becomes 361)
      final dart1 = GameEvent(
        eventId: 'dart1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );
      state = engine.apply(state, dart1);
      expect(state.competitors[0].score, 361);
      expect(state.dartsThrownInTurn, 1);
      
      // Simulate score before dart 2 (for bust scenario)
      state = state.copyWith(
        competitors: [
          state.competitors[0].copyWith(score: 10), // Set to 10 for bust
        ],
      );
      
      // Dart 2: bust (throw 20 when score is 10)
      final bustDart = GameEvent(
        eventId: 'bust',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );
      state = engine.apply(state, bustDart);
      
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      expect(state.competitors[0].turnStartScore, 381);
      
      // Dart 1: throw 20
      final dart1 = GameEvent(
        eventId: 'dart1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );
      state = engine.apply(state, dart1);
      
      // Dart 2: throw 10
      final dart2 = GameEvent(
        eventId: 'dart2',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 3,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 10, 'multiplier': 1},
        synced: false,
      );
      state = engine.apply(state, dart2);
      
      // Simulate score before dart 3 (for bust scenario)
      state = state.copyWith(
        competitors: [
          state.competitors[0].copyWith(score: 10), // Set to 10 for bust
        ],
      );
      
      // Dart 3: bust (throw 20 when score is 10)
      final bustDart = GameEvent(
        eventId: 'bust',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 4,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );
      state = engine.apply(state, bustDart);
      
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);
      expect(state.competitors[0].turnStartScore, 10);
      
      // Dart 1: bust immediately
      final bustDart = GameEvent(
        eventId: 'bust',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 2,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );
      state = engine.apply(state, bustDart);
      
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
      final turnEvent = GameEvent(
        eventId: 'turn1',
        gameId: 'test-game',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1'},
        synced: false,
      );
      state = engine.apply(state, turnEvent);

      // Player 1 wins the leg with double 20 (40 - 40 = 0)
      final winEvent = GameEvent(
        eventId: 'win1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 2},
        synced: false,
      );

      state = engine.apply(state, winEvent);

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
}
