// Stateless Catch 40 Engine
// Checkout drill: targets 61–100 (40 fixed targets).
// Up to 6 darts per target across 2 engine turns of 3 darts each.
// Checked out = remaining score reaches exactly 0 via a double (D-segment).
// Bust = dart would take remaining below 0, to exactly 1, or to 0 via non-double.
// On bust: remaining resets to original target; dart count for this target continues.
// Scoring on completion:
//   Checkout in ≤2 darts → +3 pts
//   Checkout in 3 darts  → +2 pts (target 99 → +3 pts)
//   Checkout in 4–6 darts → +1 pt
//   Failed (6 darts, no checkout) → +0 pts
// competitor.score = cumulative drill points (max 120 over 40 targets).

import '../models/game_config.dart';
import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessCatch40Engine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    if (state.isComplete && event.eventType != 'GameCompleted') {
      return EngineResult(state: state);
    }

    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => _applyDartThrownWithOutcome(state, event),
      'TurnEnded' => _applyTurnEndedWithOutcome(state, event),
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
    final payload = event.payload;
    final segmentNum = payload['segment'] as int;
    final multiplier = payload['multiplier'] as int;

    final canonical =
        Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();
    final isDouble = multiplier == 2; // D1–D20 or DB
    final segValue = _dartValue(segmentNum, multiplier);

    final remaining = state.catch40TargetRemaining;
    final currentTarget =
        60 + state.competitors[state.currentTurnIndex].practiceRound;

    // Bust detection
    final newRemaining = remaining - segValue;
    final bust = newRemaining < 0 ||
        (newRemaining == 0 && !isDouble) ||
        newRemaining == 1;

    final effectiveRemaining = bust ? currentTarget : newRemaining;
    final checkout = !bust && newRemaining == 0;

    // Record dart throw
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final comp = updatedCompetitors[state.currentTurnIndex];
    updatedCompetitors[state.currentTurnIndex] = comp.copyWith(
      dartThrows: [...comp.dartThrows, canonical],
    );

    final newDartsOnTarget = state.catch40DartsOnTarget + 1;
    final newDartsInTurn = state.dartsThrownInTurn + 1;
    // Turn ends on checkout OR after 3rd dart
    final turnDone = checkout || newDartsInTurn >= 3;

    final newState = state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: newDartsInTurn,
      catch40TargetRemaining: effectiveRemaining,
      catch40DartsOnTarget: newDartsOnTarget,
      turnActive: !turnDone,
    );

    return EngineResult(state: newState, isBust: bust);
  }

  /// Wraps [_applyTurnEnded] and surfaces a `gameCompleted` outcome when the
  /// final (40th) target advances. The producer relies on this signal to emit
  /// `GameCompleted` and atomically mark the game record complete — without
  /// it, drills that play out all 40 targets would leave `is_complete = 0`
  /// and never show up in History (#253).
  EngineResult _applyTurnEndedWithOutcome(GameState state, GameEvent event) {
    final newState = _applyTurnEnded(state, event);
    if (!state.isComplete && newState.isComplete) {
      return EngineResult(
        state: newState,
        outcome: LegOutcome.gameCompleted,
        winnerCompetitorId: newState.winnerCompetitorId,
      );
    }
    return EngineResult(state: newState);
  }

  GameState _applyTurnEnded(GameState state, GameEvent event) {
    final shouldAdvanceTarget =
        state.catch40DartsOnTarget >= 6 || state.catch40TargetRemaining == 0;

    if (!shouldAdvanceTarget) {
      // Continue same target (between turn 1 and turn 2 of 6-dart allowance)
      return state.copyWith(
        dartsThrownInTurn: 0,
        turnActive: false,
      );
    }

    // Advance to next target — score and round update
    final comp = state.competitors[state.currentTurnIndex];
    final currentTarget = 60 + comp.practiceRound;
    final checkedOut = state.catch40TargetRemaining == 0;

    final points = checkedOut
        ? _computePoints(state.catch40DartsOnTarget, currentTarget)
        : 0;

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    updatedCompetitors[state.currentTurnIndex] = comp.copyWith(
      practiceRound: comp.practiceRound + 1,
      score: comp.score + points,
      practiceSuccesses: comp.practiceSuccesses + (checkedOut ? 1 : 0),
      practiceAttempts: comp.practiceAttempts + 1,
    );

    final newPracticeRound = comp.practiceRound + 1;
    final gameComplete = newPracticeRound > 40;
    final nextTarget = gameComplete ? 0 : 60 + newPracticeRound;

    return state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: 0,
      turnActive: false,
      catch40DartsOnTarget: 0,
      catch40TargetRemaining: nextTarget,
      isComplete: gameComplete,
      status: gameComplete ? GameEngineStatus.completed : state.status,
      winnerCompetitorId: gameComplete ? null : state.winnerCompetitorId,
    );
  }

  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_competitor_id'] as String? ?? event.payload['winner_id'] as String?,
      turnActive: false,
    );
  }

  int _computePoints(int dartsOnTarget, int targetValue) {
    if (dartsOnTarget <= 2) return 3;
    if (dartsOnTarget == 3) return targetValue == 99 ? 3 : 2;
    return 1; // 4–6 darts
  }


  int _dartValue(int segment, int multiplier) {
    if (segment == 0) return 0;
    return segment * multiplier;
  }
}
