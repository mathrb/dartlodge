// Stateless Shanghai Game Engine
// Pure functional implementation of the Shanghai darts practice drill.
// Runs shanghaiTotalRounds rounds (default 7). Each round targets that round's number.
// Per-dart scoring: roundNum * multiplier if segment matches round number.
// Shanghai (single + double + triple in one turn) → bonus: increment practiceSuccesses.
// Game completes when all competitors finish the final round (via TurnEnded).
// Single-player ends with no winner; multi-player: highest score wins.

import '../models/game_config.dart';
import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessShanghaiEngine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    if (state.isComplete) return EngineResult(state: state);

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

    final canonicalString =
        Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final currentCompetitor = updatedCompetitors[state.currentTurnIndex];
    final roundNum = currentCompetitor.practiceRound;

    // Per-dart scoring: score if segment matches round number (Bull excluded)
    int scoreToAdd = 0;
    if (segmentNum == roundNum && segmentNum != 0 && segmentNum != 25) {
      scoreToAdd = roundNum * multiplier;
    }

    updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
      dartThrows: [...currentCompetitor.dartThrows, canonicalString],
      score: currentCompetitor.score + scoreToAdd,
    );

    var newState = state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
    );

    // Only evaluate end conditions on 3rd dart
    if (newState.dartsThrownInTurn < 3) {
      return (newState, LegOutcome.none, null);
    }

    // 3rd dart: check for Shanghai (single + double + triple of round number)
    final competitor = newState.competitors[newState.currentTurnIndex];
    final dartThrows = competitor.dartThrows;
    final turnThrows = dartThrows.sublist(dartThrows.length - 3).toSet();
    final isShanghai = turnThrows
        .containsAll({'$roundNum', 'D$roundNum', 'T$roundNum'});

    if (isShanghai) {
      // Shanghai = instant win. Increment successes and end the game immediately.
      final updatedWithBonus = List<CompetitorState>.from(newState.competitors);
      updatedWithBonus[newState.currentTurnIndex] = competitor.copyWith(
        practiceSuccesses: competitor.practiceSuccesses + 1,
      );
      final winnerId = newState.competitors.length > 1
          ? competitor.competitorId
          : null;
      return (
        newState.copyWith(
          competitors: updatedWithBonus,
          turnActive: false,
          isComplete: true,
          status: GameEngineStatus.completed,
          winnerCompetitorId: winnerId,
        ),
        LegOutcome.gameCompleted,
        winnerId,
      );
    }

    // Normal end of turn — caller sends TurnEnded
    return (newState.copyWith(turnActive: false), LegOutcome.none, null);
  }

  // TurnEnded: increment practiceRound for current competitor, then rotate index.
  // If all competitors have exceeded shanghaiTotalRounds, the game is complete.
  GameState _applyTurnEnded(GameState state, GameEvent event) {
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final cur = updatedCompetitors[state.currentTurnIndex];
    updatedCompetitors[state.currentTurnIndex] =
        cur.copyWith(practiceRound: cur.practiceRound + 1);

    final allDone = updatedCompetitors
        .every((c) => c.practiceRound > state.shanghaiTotalRounds);

    if (allDone) {
      String? winnerId;
      if (updatedCompetitors.length > 1) {
        // Highest score wins; first highest wins on a tie
        int maxScore = updatedCompetitors[0].score;
        winnerId = updatedCompetitors[0].competitorId;
        for (final c in updatedCompetitors.skip(1)) {
          if (c.score > maxScore) {
            maxScore = c.score;
            winnerId = c.competitorId;
          }
        }
      }
      return state.copyWith(
        competitors: updatedCompetitors,
        dartsThrownInTurn: 0,
        turnActive: false,
        isComplete: true,
        status: GameEngineStatus.completed,
        winnerCompetitorId: winnerId,
      );
    }

    final nextIndex = (state.currentTurnIndex + 1) % state.competitors.length;
    return state.copyWith(
      competitors: updatedCompetitors,
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

}
