// Stateless X01 Game Engine
// Pure functional implementation of X01 darts game using event sourcing

import '../models/game_state.dart';
import '../models/game_config.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessX01Engine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    return switch (event.eventType) {
      'GameCreated' => EngineResult(state: _applyGameCreated(state, event)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => _applyDartThrownWithOutcome(state, event),
      'TurnEnded' => EngineResult(state: _applyTurnEnded(state, event)),
      'LegCompleted' => _applyLegCompleted(state, event),
      'GameCompleted' => EngineResult(
          state: _applyGameCompleted(state, event),
          outcome: LegOutcome.gameCompleted
        ),
      _ => EngineResult(state: state),
    };
  }
  
  /// Helper method that returns both state and outcome for DartThrown events
  EngineResult _applyDartThrownWithOutcome(GameState state, GameEvent event) {
    final (newState, outcome, winnerId) = _applyDartThrown(state, event);
    return EngineResult(
      state: newState,
      outcome: outcome,
      winnerCompetitorId: winnerId
    );
  }

  @override
  bool isValid(GameState state, GameEvent event) {
    // Reject all gameplay events after game is complete, EXCEPT GameCompleted itself
    if (state.isComplete && event.eventType != 'GameCompleted') return false;

    switch (event.eventType) {
      case 'TurnStarted':
        final competitorId = event.payload['competitor_id'];
        return !state.isComplete && state.competitors.any((c) => c.competitorId == competitorId);
      case 'DartThrown':
        final competitorId = event.payload['competitor_id'];
        final currentCompetitor = state.competitors[state.currentTurnIndex];
        final segment = event.payload['segment'] as int;
        final multiplier = event.payload['multiplier'] as int;
        
        // Validate segment and multiplier
        if (segment == 0 && multiplier != 1) return false; // invalid miss
        if (segment == 25 && multiplier == 3) return false; // no triple bull
        if (segment < 0 || segment > 25) return false;     // out of range
        if (multiplier < 1 || multiplier > 3) return false; // invalid multiplier
        
        return !state.isComplete && 
               currentCompetitor.competitorId == competitorId &&
               state.dartsThrownInTurn < 3 &&
               state.turnActive; // Turn must be active (Table B)
      case 'GameCompleted':
        // Only valid once _applyLegCompleted has set isComplete = true
        return state.isComplete && state.winnerCompetitorId != null;
      default:
        return true;
    }
  }

  GameState _applyGameCreated(GameState state, GameEvent event) {
    return state.copyWith(status: GameEngineStatus.inProgress);
  }

  /// Helper method to increment dart count
  GameState incrementDartCount(GameState state) {
    return state.copyWith(
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
    );
  }

  /// Helper method to check if turn should end
  GameState checkTurnEnd(GameState state) {
    if (state.dartsThrownInTurn >= 3) {
      return state.copyWith(turnActive: false);
    }
    return state;
  }

  GameState _applyTurnStarted(GameState state, GameEvent event) {
    final competitorId = event.payload['competitor_id'];
    final competitorIndex = state.competitors.indexWhere((c) => c.competitorId == competitorId);
    
    // Update competitors to set turnStartScore and reset isIn if needed
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final currentCompetitor = updatedCompetitors[competitorIndex];
    
    // Set turnStartScore to current score (for bust recovery)
    // For straight-in strategy, player is always in
    // For other strategies, player starts not in
    final isIn = state.inStrategy == 'straight' || currentCompetitor.isIn;
    
    updatedCompetitors[competitorIndex] = currentCompetitor.copyWith(
      turnStartScore: currentCompetitor.score,
      isIn: isIn,
    );
    
    return state.copyWith(
      currentTurnIndex: competitorIndex,
      dartsThrownInTurn: 0,
      turnActive: true,
      competitors: updatedCompetitors,
    );
  }

  (GameState, LegOutcome, String?) _applyDartThrown(GameState state, GameEvent event) {
    if (!state.turnActive) {
      // Turn not active, reject dart (Table B)
      return (state, LegOutcome.none, null);
    }
    
    if (state.dartsThrownInTurn >= 3) {
      // Already thrown 3 darts, reject (Table B)
      return (state, LegOutcome.none, null);
    }
    
    final payload = event.payload;
    final segment = payload['segment'].toString();
    final multiplier = payload['multiplier'] as int;
    
    final parsedSegment = Segment.parse(multiplier == 1 ? (segment == 'bull' ? 'SB' : segment) : (multiplier == 2 ? (segment == 'bull' ? 'DB' : 'D$segment') : (segment == 'bull' ? 'TB' : 'T$segment')));
    
    // Miss guard (Table 5 - Note 5)
    if (parsedSegment.isMiss) {
      // Table G only — increment dart count, check turn end
      final newState = state.copyWith(
        dartsThrownInTurn: state.dartsThrownInTurn + 1,
      );
      return (checkTurnEnd(newState), LegOutcome.none, null);
    }
    
    final scoreValue = parsedSegment.scoreValue;
    
    final currentCompetitor = state.competitors[state.currentTurnIndex];
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    
    // In Strategy Validation (Table C)
    if (!currentCompetitor.isIn) {
      // Dart counts as thrown regardless (Note 1 in spec)
      var newState = incrementDartCount(state);
      
      final satisfied = switch (state.inStrategy) {
        'straight' => true,
        'double'   => multiplier == 2 || parsedSegment is DoubleBullSegment,
        'master'   => multiplier == 2 || multiplier == 3 || parsedSegment is DoubleBullSegment,
        _ => false, // Default case
      };
      
      if (!satisfied) {
        // No score change, no bust — just dart count
        updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
          dartThrows: [...currentCompetitor.dartThrows, parsedSegment.toCanonicalString()],
        );
        
        newState = newState.copyWith(competitors: updatedCompetitors);
        return (checkTurnEnd(newState), LegOutcome.none, null);
      }
      
      // Player gets in, apply scoring
      newState = newState.copyWith(
        competitors: updatedCompetitors.map((competitor) {
          if (competitor.competitorId == currentCompetitor.competitorId) {
            return competitor.copyWith(
              isIn: true,
              dartThrows: [...competitor.dartThrows, parsedSegment.toCanonicalString()], // Add qualifying dart
            );
          }
          return competitor;
        }).toList(),
      );
      
      // Fall through to scoring with updated state
      // Note: dart count was already incremented in the in-strategy path
      state = newState;
    }
    
    // Player is already in (either was already in or just got in), apply normal scoring (Table D)
    final competitorAfterInCheck = state.competitors[state.currentTurnIndex];
    final cameThroughInStrategy = !currentCompetitor.isIn;
    final newScore = competitorAfterInCheck.score - scoreValue;
    
    // X01 Transition Table logic
    bool isBust = false;
    String? legWinnerId;
    
    if (newScore < 0 || newScore == 1) {
      isBust = true; // Bust condition
    } else if (newScore == 0) {
      // Out validation (Table E)
      bool validOut = false;
      
      switch (state.outStrategy) {
        case 'straight':
          validOut = true; // Any hit to zero is valid
          break;
        case 'double':
          validOut = multiplier == 2 || parsedSegment is DoubleBullSegment;
          break;
        case 'master':
          validOut = multiplier >= 2; // Double or triple
          break;
      }
      
      if (validOut) {
        legWinnerId = competitorAfterInCheck.competitorId; // Leg completed
      } else {
        isBust = true; // Invalid out strategy
      }
    }

    // Update the competitor with the new dart throw
    // Note: If we came through the in-strategy path, dart was already added to throws
    // If we were already in, we need to add it now
    final competitorWithDart = cameThroughInStrategy ?
      competitorAfterInCheck : // Dart already added in in-strategy path
      competitorAfterInCheck.copyWith(
        dartThrows: [...competitorAfterInCheck.dartThrows, parsedSegment.toCanonicalString()],
      );
    
    updatedCompetitors[state.currentTurnIndex] = competitorWithDart;
    
    if (isBust) {
      // Bust logic (Table F): restore to turnStartScore and end turn
      final bustRecoveryScore = competitorAfterInCheck.turnStartScore ?? competitorAfterInCheck.score;
      updatedCompetitors[state.currentTurnIndex] = updatedCompetitors[state.currentTurnIndex].copyWith(
        score: bustRecoveryScore,
      );
      
      final newState = state.copyWith(
        competitors: updatedCompetitors,
        dartsThrownInTurn: 3, // Force turn end (Table H)
      );
      return (checkTurnEnd(newState), LegOutcome.none, null);
    }
    
    // Normal scoring
    updatedCompetitors[state.currentTurnIndex] = updatedCompetitors[state.currentTurnIndex].copyWith(
      score: newScore,
      // Don't set isComplete here - that's for game completion
    );
    
    final newState = state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: cameThroughInStrategy ? state.dartsThrownInTurn : state.dartsThrownInTurn + 1,
    );
    
    // Check if leg is completed
    if (legWinnerId != null) {
      // Update competitors to increment legsWon for winner
      final updatedCompetitors = List<CompetitorState>.from(newState.competitors);
      final winnerIndex = updatedCompetitors.indexWhere((c) => c.competitorId == legWinnerId);
      if (winnerIndex >= 0) {
        final winner = updatedCompetitors[winnerIndex];
        updatedCompetitors[winnerIndex] = winner.copyWith(
          legsWon: winner.legsWon + 1,
        );
      }
      
      // Check if game is completed (single leg game)
      final winner = updatedCompetitors.firstWhere((c) => c.competitorId == legWinnerId);
      final isGameComplete = winner.legsWon >= newState.legsToWin;
      
      if (isGameComplete) {
        return (newState.copyWith(
          competitors: updatedCompetitors,
          winnerCompetitorId: legWinnerId,
          isComplete: true,
          status: GameEngineStatus.completed,
          turnActive: false,
        ), LegOutcome.gameCompleted, legWinnerId);
      } else {
        // Reset leg for next leg (Table K)
        final stateBeforeReset = newState.copyWith(
          competitors: updatedCompetitors,
          currentLegIndex: newState.currentLegIndex + 1, // Increment for next leg
          turnActive: false,
          winnerCompetitorId: legWinnerId,
        );
        final resetState = _resetLeg(stateBeforeReset);
        return (resetState, LegOutcome.legCompleted, legWinnerId);
      }
    }
    
    return (checkTurnEnd(newState), LegOutcome.none, null);
  }

  GameState _applyTurnEnded(GameState state, GameEvent event) {
    final nextIndex = (state.currentTurnIndex + 1) % state.competitors.length;
    return state.copyWith(
      dartsThrownInTurn: 0,
      turnActive: false,
      currentTurnIndex: nextIndex,
    );
  }
  
  /// Handle LegCompleted events (Table J)
  EngineResult _applyLegCompleted(GameState state, GameEvent event) {
    final legWinnerId = event.payload['winner_competitor_id'] as String;
    
    // Update competitors to increment legsWon for winner
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final winnerIndex = updatedCompetitors.indexWhere((c) => c.competitorId == legWinnerId);
    
    if (winnerIndex >= 0) {
      final winner = updatedCompetitors[winnerIndex];
      updatedCompetitors[winnerIndex] = winner.copyWith(
        legsWon: winner.legsWon + 1,
      );
    }
    
    // Check if game is completed (Table J)
    final winner = updatedCompetitors.firstWhere((c) => c.competitorId == legWinnerId);
    if (winner.legsWon >= state.legsToWin) {
      // Game completed (Table L)
      final newState = state.copyWith(
        competitors: updatedCompetitors,
        // No currentLegIndex increment - game is over
        isComplete: true,
        status: GameEngineStatus.completed,
        turnActive: false,
        winnerCompetitorId: legWinnerId,
      );
      return EngineResult(
        state: newState,
        outcome: LegOutcome.gameCompleted,
        winnerCompetitorId: legWinnerId
      );
    } else {
      // Reset leg for next leg (Table K)
      final newState = _resetLeg(state.copyWith(
        competitors: updatedCompetitors,
        currentLegIndex: state.currentLegIndex + 1, // Increment for next leg
        turnActive: false,
      ));
      return EngineResult(state: newState);
    }
  }
  
  /// Reset leg state for next leg (Table K)
  GameState _resetLeg(GameState state) {
    // Reset scores to starting score from game state
    final startingScore = state.startingScore;
    
    final resetCompetitors = state.competitors.map((competitor) {
      return competitor.copyWith(
        score: startingScore,
        isIn: false, // Reset in-state
        turnStartScore: null, // Clear turn start score
        isComplete: false,
        dartThrows: [], // Clear dart throws for new leg
      );
    }).toList();
    
    return state.copyWith(
      competitors: resetCompetitors,
      currentTurnIndex: 0, // Start with first player
      dartsThrownInTurn: 0,
      winnerCompetitorId: null, // Clear winner for new leg
    );
  }

  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_id'],
      turnActive: false,
    );
  }
}