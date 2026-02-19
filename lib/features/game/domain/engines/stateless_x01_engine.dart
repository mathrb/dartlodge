// Stateless X01 Game Engine
// Pure functional implementation of X01 darts game using event sourcing

import '../models/game_state.dart';
import '../models/game_config.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessX01Engine implements GameEngine {
  @override
  GameState apply(GameState state, GameEvent event) {
    switch (event.eventType) {
      case 'GameCreated':
        return _applyGameCreated(state, event);
      case 'TurnStarted':
        return _applyTurnStarted(state, event);
      case 'DartThrown':
        return _applyDartThrown(state, event);
      case 'TurnEnded':
        return _applyTurnEnded(state, event);
      case 'GameCompleted':
        return _applyGameCompleted(state, event);
      default:
        return state;
    }
  }

  @override
  bool isValid(GameState state, GameEvent event) {
    if (state.isComplete && event.eventType != 'GameCompleted') return false;

    switch (event.eventType) {
      case 'TurnStarted':
        final competitorId = event.payload['competitor_id'];
        return !state.isComplete && state.competitors.any((c) => c.competitorId == competitorId);
      case 'DartThrown':
        final competitorId = event.payload['competitor_id'];
        final currentCompetitor = state.competitors[state.currentTurnIndex];
        return !state.isComplete && 
               currentCompetitor.competitorId == competitorId &&
               state.dartsThrownInTurn < 3;
      default:
        return true;
    }
  }

  GameState _applyGameCreated(GameState state, GameEvent event) {
    return state.copyWith(status: GameEngineStatus.inProgress);
  }

  GameState _applyTurnStarted(GameState state, GameEvent event) {
    final competitorId = event.payload['competitor_id'];
    final competitorIndex = state.competitors.indexWhere((c) => c.competitorId == competitorId);
    
    return state.copyWith(
      currentTurnIndex: competitorIndex,
      dartsThrownInTurn: 0,
    );
  }

  GameState _applyDartThrown(GameState state, GameEvent event) {
    final payload = event.payload;
    final segment = payload['segment'].toString();
    final multiplier = payload['multiplier'] as int;
    
    final parsedSegment = Segment.parse(multiplier == 1 ? segment : (multiplier == 2 ? 'D$segment' : 'T$segment'));
    final scoreValue = parsedSegment.scoreValue;
    
    final currentCompetitor = state.competitors[state.currentTurnIndex];
    final newScore = currentCompetitor.score - scoreValue;
    
    // X01 Transition Table logic
    bool isBust = false;
    if (newScore < 0 || newScore == 1) {
      isBust = true;
    } else if (newScore == 0) {
      // Out validation (Table E)
      // TODO: Check out strategy from config
      // For now, assume double out if not specified
      if (multiplier != 2 && parsedSegment is! DoubleBullSegment) {
        isBust = true;
      }
    }

    if (isBust) {
      // Bust logic (Table F)
      return state.copyWith(
        dartsThrownInTurn: 3, // Force turn end
      );
    }

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
      score: newScore,
      dartThrows: [...currentCompetitor.dartThrows, parsedSegment.toCanonicalString()],
      isComplete: newScore == 0,
    );

    return state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
      isComplete: newScore == 0,
      winnerCompetitorId: newScore == 0 ? currentCompetitor.competitorId : null,
      status: newScore == 0 ? GameEngineStatus.completed : state.status,
    );
  }

  GameState _applyTurnEnded(GameState state, GameEvent event) {
    return state.copyWith(
      dartsThrownInTurn: 0,
    );
  }

  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_id'],
    );
  }
}