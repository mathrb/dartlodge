// Stateless Around the Clock Game Engine
// Pure functional implementation of Around the Clock darts game (Standard, Reverse, DoublesOnly)
// Implements all transition tables from docs/games/around-the-clock.md

import '../models/game_config.dart';
import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessAroundTheClockEngine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => _applyDartThrownWithOutcome(state, event),
      'TurnEnded' => EngineResult(state: _applyTurnEnded(state, event)),
      'LegCompleted' => _applyLegCompleted(state, event),
      'GameCompleted' => EngineResult(
          state: _applyGameCompleted(state, event),
          outcome: LegOutcome.gameCompleted),
      _ => EngineResult(state: state),
    };
  }

  @override
  bool isValid(GameState state, GameEvent event) {
    if (state.isComplete && event.eventType != 'GameCompleted') return false;

    switch (event.eventType) {
      case 'TurnStarted':
        return !state.turnActive;
      case 'DartThrown':
        if (!state.turnActive) return false;
        if (state.dartsThrownInTurn >= 3) return false;
        if (state.competitors[state.currentTurnIndex].isComplete) return false;
        return true;
      case 'GameCompleted':
        return state.isComplete && state.winnerCompetitorId != null;
      default:
        return true;
    }
  }

  GameState _applyTurnStarted(GameState state, GameEvent event) {
    final competitorId = event.payload['competitor_id'] as String;
    final competitorIndex =
        state.competitors.indexWhere((c) => c.competitorId == competitorId);
    return state.copyWith(
      currentTurnIndex:
          competitorIndex >= 0 ? competitorIndex : state.currentTurnIndex,
      dartsThrownInTurn: 0,
      turnActive: true,
    );
  }

  EngineResult _applyDartThrownWithOutcome(GameState state, GameEvent event) {
    final (newState, outcome, winnerId) = _applyDartThrown(state, event);
    return EngineResult(
      state: newState,
      outcome: outcome,
      winnerCompetitorId: winnerId,
      isBust: false, // Around the Clock has no bust
    );
  }

  (GameState, LegOutcome, String?) _applyDartThrown(
      GameState state, GameEvent event) {
    final payload = event.payload;
    final segmentNum = payload['segment'] as int;
    final multiplier = payload['multiplier'] as int;

    // Build canonical string and record the dart throw
    final canonicalString =
        Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final currentCompetitor = updatedCompetitors[state.currentTurnIndex];
    updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
      dartThrows: [...currentCompetitor.dartThrows, canonicalString],
    );

    var newState = state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
    );

    // Table B note / Ambiguity 3: Bull (25) or Miss (0) — no game effect
    if (segmentNum == 0 || segmentNum == 25) {
      return (_checkTurnEnd(newState), LegOutcome.none, null);
    }

    final variant = state.aroundTheClockVariant;
    final currentTarget =
        newState.competitors[newState.currentTurnIndex].currentTarget;

    // Table D — Hit validation
    if (!_isHit(segmentNum, multiplier, currentTarget, variant)) {
      return (_checkTurnEnd(newState), LegOutcome.none, null);
    }

    // Table E — Advance target
    final (stateAfterAdvance, isCompleted) = _advanceTarget(newState, variant);
    newState = stateAfterAdvance;

    if (!isCompleted) {
      return (_checkTurnEnd(newState), LegOutcome.none, null);
    }

    // Table F — Win check: player completed the sequence
    final (stateAfterWin, outcome, winnerId) = _evaluateWin(newState);
    return (stateAfterWin, outcome, winnerId);
  }

  // Table D — Hit validation
  bool _isHit(int segment, int multiplier, int? currentTarget, String variant) {
    if (currentTarget == null) return false;
    if (segment != currentTarget) return false;
    // Table D2: DoublesOnly requires exactly a double
    if (variant == 'doublesOnly' && multiplier != 2) return false;
    return true;
  }

  // Table E — Advance current target for the current competitor
  (GameState, bool) _advanceTarget(GameState state, String variant) {
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final current = updatedCompetitors[state.currentTurnIndex];
    final currentTarget = current.currentTarget ?? 1;

    CompetitorState updated;
    bool completed = false;

    if (variant == 'reverse') {
      // E2: decrement; complete when hitting 1
      if (currentTarget == 1) {
        completed = true;
        updated = current.copyWith(isComplete: true);
      } else {
        updated = current.copyWith(currentTarget: currentTarget - 1);
      }
    } else {
      // E1/E3: Standard and DoublesOnly both ascend from 1 → 20
      if (currentTarget == 20) {
        completed = true;
        updated = current.copyWith(isComplete: true);
      } else {
        updated = current.copyWith(currentTarget: currentTarget + 1);
      }
    }

    updatedCompetitors[state.currentTurnIndex] = updated;
    return (state.copyWith(competitors: updatedCompetitors), completed);
  }

  // Tables F + J + K — Evaluate win, increment legsWon, reset or complete game
  (GameState, LegOutcome, String?) _evaluateWin(GameState state) {
    final winnerIndex = state.currentTurnIndex;
    final winner = state.competitors[winnerIndex];
    final winnerId = winner.competitorId;

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    updatedCompetitors[winnerIndex] =
        winner.copyWith(legsWon: winner.legsWon + 1);

    final newLegsWon = updatedCompetitors[winnerIndex].legsWon;
    final isGameComplete = newLegsWon >= state.legsToWin;

    if (isGameComplete) {
      final completedState = state.copyWith(
        competitors: updatedCompetitors,
        isComplete: true,
        status: GameEngineStatus.completed,
        winnerCompetitorId: winnerId,
        turnActive: false,
      );
      return (completedState, LegOutcome.gameCompleted, winnerId);
    } else {
      final stateBeforeReset = state.copyWith(
        competitors: updatedCompetitors,
        currentLegIndex: state.currentLegIndex + 1,
        turnActive: false,
        winnerCompetitorId: winnerId,
      );
      final resetState = _resetLeg(stateBeforeReset);
      return (resetState, LegOutcome.legCompleted, winnerId);
    }
  }

  // Table H — End turn if 3 darts thrown
  GameState _checkTurnEnd(GameState state) {
    if (state.dartsThrownInTurn >= 3) {
      return state.copyWith(turnActive: false);
    }
    return state;
  }

  // Table I — TurnEnded: advance to next competitor
  GameState _applyTurnEnded(GameState state, GameEvent event) {
    final nextIndex = (state.currentTurnIndex + 1) % state.competitors.length;
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final current = updatedCompetitors[state.currentTurnIndex];
    updatedCompetitors[state.currentTurnIndex] =
        current.copyWith(practiceRound: current.practiceRound + 1);
    return state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: 0,
      turnActive: false,
      currentTurnIndex: nextIndex,
    );
  }

  // LegCompleted event replay (for event log reconstruction)
  EngineResult _applyLegCompleted(GameState state, GameEvent event) {
    final legWinnerId = event.payload['winner_competitor_id'] as String;

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final winnerIndex =
        updatedCompetitors.indexWhere((c) => c.competitorId == legWinnerId);

    if (winnerIndex >= 0) {
      final winner = updatedCompetitors[winnerIndex];
      updatedCompetitors[winnerIndex] =
          winner.copyWith(legsWon: winner.legsWon + 1);
    }

    final winner =
        updatedCompetitors.firstWhere((c) => c.competitorId == legWinnerId);
    if (winner.legsWon >= state.legsToWin) {
      final newState = state.copyWith(
        competitors: updatedCompetitors,
        isComplete: true,
        status: GameEngineStatus.completed,
        turnActive: false,
        winnerCompetitorId: legWinnerId,
      );
      return EngineResult(
          state: newState,
          outcome: LegOutcome.gameCompleted,
          winnerCompetitorId: legWinnerId);
    } else {
      final newState = _resetLeg(state.copyWith(
        competitors: updatedCompetitors,
        currentLegIndex: state.currentLegIndex + 1,
        turnActive: false,
      ));
      return EngineResult(state: newState);
    }
  }

  // Table K — Reset per-leg state for each competitor
  GameState _resetLeg(GameState state) {
    final variant = state.aroundTheClockVariant;
    final initialTarget = variant == 'reverse' ? 20 : 1;

    final resetCompetitors = state.competitors.map((competitor) {
      return competitor.copyWith(
        isComplete: false,
        dartThrows: const [],
        currentTarget: initialTarget,
      );
    }).toList();

    return state.copyWith(
      competitors: resetCompetitors,
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      turnActive: false,
      winnerCompetitorId: null,
    );
  }

  // Table L — GameCompleted event
  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_id'] as String?,
      turnActive: false,
    );
  }

}
