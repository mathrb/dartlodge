// Stateless Catch 40 Game Engine
// Pure functional implementation of the Catch 40 practice drill.
// 8 rounds (configurable). Each round: throw 3 darts, sum raw score.
// If total >= round target, add target value to running score; otherwise no change.
// Drill ends after all rounds with no winner.

import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessCatch40Engine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => _applyDartThrownWithOutcome(state, event),
      'TurnEnded' => EngineResult(state: _applyTurnEnded(state, event)),
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
        return true;
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
      isBust: false,
    );
  }

  (GameState, LegOutcome, String?) _applyDartThrown(
      GameState state, GameEvent event) {
    final payload = event.payload;
    final segmentNum = payload['segment'] as int;
    final multiplier = payload['multiplier'] as int;

    // Build canonical string and record the dart throw
    final canonicalString = _toCanonicalString(segmentNum, multiplier);
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final currentCompetitor = updatedCompetitors[state.currentTurnIndex];
    updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
      dartThrows: [...currentCompetitor.dartThrows, canonicalString],
    );

    var newState = state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
    );

    // Only evaluate scoring on the 3rd dart
    if (newState.dartsThrownInTurn < 3) {
      return (newState, LegOutcome.none, null);
    }

    // 3rd dart: evaluate the round
    final competitor = newState.competitors[newState.currentTurnIndex];
    final dartThrows = competitor.dartThrows;
    final turnThrows = dartThrows.sublist(dartThrows.length - 3);
    final turnTotal =
        turnThrows.map(_dartScoreValue).reduce((a, b) => a + b);

    // Check against this round's target (practiceRound is 1-based)
    final roundIndex = competitor.practiceRound - 1;
    final roundTarget = state.catch40RoundTargets[roundIndex];
    final newScore =
        turnTotal >= roundTarget ? competitor.score + roundTarget : competitor.score;
    final newRound = competitor.practiceRound + 1;

    final updatedCompetitors2 = List<CompetitorState>.from(newState.competitors);
    updatedCompetitors2[newState.currentTurnIndex] = competitor.copyWith(
      score: newScore,
      practiceRound: newRound,
      practiceAttempts: competitor.practiceAttempts + 1,
      practiceSuccesses:
          competitor.practiceSuccesses + (turnTotal >= roundTarget ? 1 : 0),
    );

    newState = newState.copyWith(
      competitors: updatedCompetitors2,
      turnActive: false,
    );

    // End condition: all rounds complete
    if (newRound > state.catch40TotalRounds) {
      newState = newState.copyWith(
        isComplete: true,
        status: GameEngineStatus.completed,
        winnerCompetitorId: null,
        turnActive: false,
      );
      return (newState, LegOutcome.gameCompleted, null);
    }

    return (newState, LegOutcome.none, null);
  }

  GameState _applyTurnEnded(GameState state, GameEvent event) {
    final nextIndex = (state.currentTurnIndex + 1) % state.competitors.length;
    return state.copyWith(
      dartsThrownInTurn: 0,
      turnActive: false,
      currentTurnIndex: nextIndex,
    );
  }

  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_id'] as String?,
      turnActive: false,
    );
  }

  String _toCanonicalString(int segment, int multiplier) {
    if (segment == 0) return 'MISS';
    if (segment == 25) {
      return multiplier == 2 ? 'DB' : 'SB';
    }
    return switch (multiplier) {
      1 => '$segment',
      2 => 'D$segment',
      3 => 'T$segment',
      _ => '$segment',
    };
  }

  int _dartScoreValue(String canonical) {
    if (canonical == 'MISS') return 0;
    if (canonical == 'DB') return 50;
    if (canonical == 'SB') return 25;
    if (canonical.startsWith('D')) return int.parse(canonical.substring(1)) * 2;
    if (canonical.startsWith('T')) return int.parse(canonical.substring(1)) * 3;
    return int.parse(canonical);
  }
}
