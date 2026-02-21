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
               state.dartsThrownInTurn < 3 &&
               state.turnActive; // Turn must be active (Table B)
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
    
    // Update competitors to set turnStartScore and reset isIn if needed
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final currentCompetitor = updatedCompetitors[competitorIndex];
    
    // Set turnStartScore to current score (for bust recovery)
    updatedCompetitors[competitorIndex] = currentCompetitor.copyWith(
      turnStartScore: currentCompetitor.score,
      // Reset isIn only if we're not already in (for new legs)
      isIn: currentCompetitor.isIn || state.inStrategy == 'straight',
    );
    
    return state.copyWith(
      currentTurnIndex: competitorIndex,
      dartsThrownInTurn: 0,
      turnActive: true,
      competitors: updatedCompetitors,
    );
  }

  GameState _applyDartThrown(GameState state, GameEvent event) {
    if (!state.turnActive) {
      // Turn not active, reject dart (Table B)
      return state;
    }
    
    if (state.dartsThrownInTurn >= 3) {
      // Already thrown 3 darts, reject (Table B)
      return state;
    }
    
    final payload = event.payload;
    final segment = payload['segment'].toString();
    final multiplier = payload['multiplier'] as int;
    
    final parsedSegment = Segment.parse(multiplier == 1 ? segment : (multiplier == 2 ? 'D$segment' : 'T$segment'));
    final scoreValue = parsedSegment.scoreValue;
    
    final currentCompetitor = state.competitors[state.currentTurnIndex];
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    
    // In Strategy Validation (Table C)
    if (!currentCompetitor.isIn) {
      // Apply in-strategy rules
      bool becomesIn = false;
      
      switch (state.inStrategy) {
        case 'straight':
          becomesIn = true; // Any hit gets you in
          break;
        case 'double':
          becomesIn = multiplier == 2 || parsedSegment is DoubleBullSegment;
          break;
        case 'master':
          becomesIn = multiplier >= 2; // Double or triple
          break;
      }
      
      if (becomesIn) {
        // Player gets in, apply scoring
        final newScore = currentCompetitor.score - scoreValue;
        updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
          score: newScore,
          isIn: true,
          dartThrows: [...currentCompetitor.dartThrows, parsedSegment.toCanonicalString()],
        );
      } else {
        // Failed to get in, no score change but dart still counts
        updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
          dartThrows: [...currentCompetitor.dartThrows, parsedSegment.toCanonicalString()],
        );
      }
      
      return state.copyWith(
        competitors: updatedCompetitors,
        dartsThrownInTurn: state.dartsThrownInTurn + 1,
      );
    }
    
    // Player is already in, apply normal scoring (Table D)
    final newScore = currentCompetitor.score - scoreValue;
    
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
        legWinnerId = currentCompetitor.competitorId; // Leg completed
      } else {
        isBust = true; // Invalid out strategy
      }
    }

    if (isBust) {
      // Bust logic (Table F): restore to turnStartScore and end turn
      final bustRecoveryScore = currentCompetitor.turnStartScore ?? currentCompetitor.score;
      updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
        score: bustRecoveryScore,
        dartThrows: [...currentCompetitor.dartThrows, parsedSegment.toCanonicalString()],
      );
      
      return state.copyWith(
        competitors: updatedCompetitors,
        dartsThrownInTurn: 3, // Force turn end (Table H)
      );
    }
    
    // Normal scoring
    updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
      score: newScore,
      dartThrows: [...currentCompetitor.dartThrows, parsedSegment.toCanonicalString()],
      isComplete: legWinnerId != null,
    );
    
    // Check if leg is completed
    if (legWinnerId != null) {
      return _applyLegCompleted(state.copyWith(
        competitors: updatedCompetitors,
        dartsThrownInTurn: state.dartsThrownInTurn + 1,
        winnerCompetitorId: legWinnerId,
      ), legWinnerId);
    }
    
    return state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
    );
  }

  GameState _applyTurnEnded(GameState state, GameEvent event) {
    return state.copyWith(
      dartsThrownInTurn: 0,
      turnActive: false,
    );
  }

  GameState _applyLegCompleted(GameState state, String legWinnerId) {
    // Find the winning competitor and increment their legsWon count
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final winnerIndex = updatedCompetitors.indexWhere((c) => c.competitorId == legWinnerId);
    
    if (winnerIndex >= 0) {
      final winner = updatedCompetitors[winnerIndex];
      updatedCompetitors[winnerIndex] = winner.copyWith(
        legsWon: winner.legsWon + 1,
      );
    }
    
    // Check if this leg completion wins the game (Table J)
    final winner = updatedCompetitors.firstWhere((c) => c.competitorId == legWinnerId);
    if (winner.legsWon >= state.legsToWin) {
      // Game completed
      return state.copyWith(
        competitors: updatedCompetitors,
        isComplete: true,
        status: GameEngineStatus.completed,
        turnActive: false,
      );
    } else {
      // Reset leg for next leg (Table K)
      return _resetLeg(state.copyWith(
        competitors: updatedCompetitors,
        currentLegIndex: state.currentLegIndex + 1,
        turnActive: false,
      ));
    }
  }
  
  GameState _resetLeg(GameState state) {
    // Reset scores to starting score (assuming 501 for now)
    // TODO: Get actual starting score from game config
    const startingScore = 501;
    
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