// Stateless Count-Up Game Engine
// Pure functional implementation of the count-up game.
// See `docs/games/count-up.md` for the authoritative spec.
//
// Each dart adds `segment * multiplier` to the current competitor's score.
// No bust, no upper bound. The game runs for exactly `countUpTotalRounds`
// full rounds (each round = one rotation through all competitors). Winner is
// the competitor with the highest score after the final TurnEnded; tie → no
// winner. Solo games always award the single competitor the win.

import '../models/game_config.dart';
import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessCountUpEngine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    if (state.isComplete && event.eventType != 'GameCompleted') {
      return EngineResult(state: state);
    }

    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => EngineResult(state: _applyDartThrown(state, event)),
      'TurnEnded' => _applyTurnEnded(state),
      'LegCompleted' => EngineResult(
          state: state,
          outcome: LegOutcome.legCompleted,
          winnerCompetitorId: state.winnerCompetitorId),
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
      case 'TurnEnded':
        // Allowed when 3 darts thrown OR turn has been programmatically ended.
        return true;
      default:
        return true;
    }
  }

  GameState _applyTurnStarted(GameState state, GameEvent event) {
    final competitorId = event.payload['competitor_id'] as String?;
    final resolvedIndex = competitorId != null
        ? state.competitors.indexWhere((c) => c.competitorId == competitorId)
        : -1;
    final turnIndex = resolvedIndex >= 0 ? resolvedIndex : state.currentTurnIndex;

    final updated = List<CompetitorState>.from(state.competitors);
    final cur = updated[turnIndex];
    updated[turnIndex] = cur.copyWith(
      turnStartScore: cur.score,
      dartThrows: const [],
    );

    return state.copyWith(
      competitors: updated,
      currentTurnIndex: turnIndex,
      dartsThrownInTurn: 0,
      turnActive: true,
    );
  }

  GameState _applyDartThrown(GameState state, GameEvent event) {
    final payload = event.payload;
    final segmentNum = payload['segment'] as int;
    final multiplier = payload['multiplier'] as int;
    final canonicalString =
        Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();

    // Score formula: segment * multiplier (covers MISS=0*1=0, SB=25*1, DB=25*2,
    // singles/doubles/triples 1–20). No bust, no upper bound.
    final scoreToAdd = segmentNum * multiplier;

    final updated = List<CompetitorState>.from(state.competitors);
    final cur = updated[state.currentTurnIndex];
    updated[state.currentTurnIndex] = cur.copyWith(
      dartThrows: [...cur.dartThrows, canonicalString],
      score: cur.score + scoreToAdd,
    );

    final newDartCount = state.dartsThrownInTurn + 1;
    return state.copyWith(
      competitors: updated,
      dartsThrownInTurn: newDartCount,
      // After the 3rd dart, the turn becomes inactive — the user must tap
      // NEXT ROUND (which emits TurnEnded) before play continues.
      turnActive: newDartCount < 3,
    );
  }

  EngineResult _applyTurnEnded(GameState state) {
    final totalRounds = state.countUpTotalRounds ?? 8;
    final isLastCompetitor =
        state.currentTurnIndex >= state.competitors.length - 1;
    final isLastRound = state.currentRoundInLeg >= totalRounds;

    if (isLastCompetitor && isLastRound) {
      final winnerId = _pickWinner(state);
      return EngineResult(
        state: state.copyWith(
          dartsThrownInTurn: 0,
          turnActive: false,
          isComplete: true,
          status: GameEngineStatus.completed,
          winnerCompetitorId: winnerId,
        ),
        outcome: LegOutcome.gameCompleted,
        winnerCompetitorId: winnerId,
      );
    }

    if (isLastCompetitor) {
      // End of round, not end of game — wrap to first competitor and advance round.
      return EngineResult(
        state: state.copyWith(
          dartsThrownInTurn: 0,
          turnActive: false,
          currentTurnIndex: 0,
          currentRoundInLeg: state.currentRoundInLeg + 1,
        ),
      );
    }

    // Mid-round: rotate to the next competitor.
    return EngineResult(
      state: state.copyWith(
        dartsThrownInTurn: 0,
        turnActive: false,
        currentTurnIndex: state.currentTurnIndex + 1,
      ),
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

  /// Solo → solo player wins. ≥2 competitors → highest score wins; tie at the
  /// top resolves to no winner (`null`).
  String? _pickWinner(GameState state) {
    if (state.competitors.isEmpty) return null;
    if (state.competitors.length == 1) {
      return state.competitors.first.competitorId;
    }
    final maxScore = state.competitors
        .map((c) => c.score)
        .reduce((a, b) => a > b ? a : b);
    final leaders =
        state.competitors.where((c) => c.score == maxScore).toList();
    if (leaders.length == 1) return leaders.first.competitorId;
    return null;
  }

}
