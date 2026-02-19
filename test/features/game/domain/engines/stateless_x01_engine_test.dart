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
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 501,
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      status: GameEngineStatus.inProgress,
    );
  });

  group('X01 Transition Logic (Table D - Scoring)', () {
    test('should reduce score correctly on valid hit', () {
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(initialState, event);
      expect(newState.competitors[0].score, 481);
      expect(newState.dartsThrownInTurn, 1);
    });

    test('should handle Triple correctly', () {
      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 3},
        synced: false,
      );

      final newState = engine.apply(initialState, event);
      expect(newState.competitors[0].score, 441);
    });
  });

  group('X01 Bust Logic (Table F)', () {
    test('should bust if score goes below 0', () {
      final lowScoreState = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 10),
          initialState.competitors[1],
        ],
      );

      final event = GameEvent(
        eventId: 'e1',
        gameId: 'test-game',
        eventType: 'DartThrown',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': 'c1', 'segment': 20, 'multiplier': 1},
        synced: false,
      );

      final newState = engine.apply(lowScoreState, event);
      // Bust logic: score stays same, turn ends
      expect(newState.competitors[0].score, 10);
      expect(newState.dartsThrownInTurn, 3);
    });

    test('should bust if score becomes exactly 1', () {
      final state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 21),
          initialState.competitors[1],
        ],
      );

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
      final state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 40),
          initialState.competitors[1],
        ],
      );

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
    });

    test('should bust on exact single to zero (Double-Out enforced)', () {
      final state = initialState.copyWith(
        competitors: [
          initialState.competitors[0].copyWith(score: 20),
          initialState.competitors[1],
        ],
      );

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
    });
  });
}
