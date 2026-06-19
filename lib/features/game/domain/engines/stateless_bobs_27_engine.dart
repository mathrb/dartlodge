// Stateless Bob's 27 Game Engine
// Pure functional implementation of Bob's 27 darts practice drill.
// 21 rounds: rounds 1–20 target D{round}, round 21 targets the Double Bull (DB).
// A double-number hit scores round*2*hitCount; a Double Bull hit scores 50*hitCount;
// a whitewashed round deducts the same per-hit value (round*2, or 50 for the bull).
// Drill ends after the bull round (round 21) or if score drops to <= 0.
// The canonical perfect run (three doubles every round + three Double Bulls)
// totals 27 + Σ(3·2n, n=1..20) + 3·50 = 1437 — see docs/games/bobs-27.md.

import '../models/game_config.dart';
import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessBobs27Engine implements GameEngine {
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
        if (state.competitors[state.currentTurnIndex].isComplete) return false;
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

    // Only evaluate scoring on the 3rd dart
    if (newState.dartsThrownInTurn < 3) {
      return (newState, LegOutcome.none, null);
    }

    // 3rd dart: evaluate the round
    final competitor = newState.competitors[newState.currentTurnIndex];
    final roundNum = competitor.practiceRound; // 1–21
    // Rounds 1–20 target the round's double; round 21 is the Double-Bull finale.
    final isBullRound = roundNum >= 21;
    final requiredSegment = isBullRound ? 'DB' : 'D$roundNum';
    final pointsPerHit = isBullRound ? 50 : roundNum * 2;

    // Last 3 dart throws are this turn's darts
    final dartThrows = competitor.dartThrows;
    final turnThrows = dartThrows.sublist(dartThrows.length - 3);
    final hitCount =
        turnThrows.where((d) => d == requiredSegment).length;

    // Apply score delta
    int newScore = competitor.score;
    if (hitCount > 0) {
      newScore += pointsPerHit * hitCount;
    } else {
      newScore -= pointsPerHit;
    }

    // Advance practice round
    final newRound = roundNum + 1;

    final updatedCompetitors2 = List<CompetitorState>.from(newState.competitors);
    updatedCompetitors2[newState.currentTurnIndex] =
        competitor.copyWith(score: newScore, practiceRound: newRound);

    newState = newState.copyWith(
      competitors: updatedCompetitors2,
      turnActive: false,
    );

    // End condition check (priority order): bust out at <= 0, or finish the
    // Double-Bull round (round 21).
    if (newScore <= 0 || roundNum >= 21) {
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

  // TurnEnded: advance to next competitor
  GameState _applyTurnEnded(GameState state, GameEvent event) {
    final nextIndex = (state.currentTurnIndex + 1) % state.competitors.length;
    return state.copyWith(
      dartsThrownInTurn: 0,
      turnActive: false,
      currentTurnIndex: nextIndex,
    );
  }

  // GameCompleted event replay
  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_competitor_id'] as String? ?? event.payload['winner_id'] as String?,
      turnActive: false,
    );
  }

}
