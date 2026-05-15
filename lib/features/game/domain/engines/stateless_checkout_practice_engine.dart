// Stateless Checkout Practice Engine
// Solo X01-style drill from 170 with double-out rules.
// Score starts at 170 and decreases with each dart thrown.
// Bust (score < 0, == 1, or 0 on non-double): reverts to turn-start score, turn ends.
// Checkout (score == 0 on a double): game completes, player is winner.

import '../models/game_config.dart';
import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessCheckoutPracticeEngine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => _applyDartThrown(state, event),
      'TurnEnded' => EngineResult(state: _applyTurnEnded(state)),
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
    final idx =
        competitorIndex >= 0 ? competitorIndex : state.currentTurnIndex;
    final competitor = state.competitors[idx];
    final updatedCompetitor = competitor.copyWith(
      turnStartScore: competitor.score,
    );
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    updatedCompetitors[idx] = updatedCompetitor;
    return state.copyWith(
      currentTurnIndex: idx,
      competitors: updatedCompetitors,
      dartsThrownInTurn: 0,
      turnActive: true,
    );
  }

  EngineResult _applyDartThrown(GameState state, GameEvent event) {
    final payload = event.payload;
    final segmentNum = payload['segment'] as int;
    final multiplier = payload['multiplier'] as int;

    final competitor = state.competitors[state.currentTurnIndex];
    final dartValue = _dartValue(segmentNum, multiplier);
    final newScore = competitor.score - dartValue;

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);

    if (newScore == 0 && _isDouble(segmentNum, multiplier)) {
      final canonical =
          Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();
      updatedCompetitors[state.currentTurnIndex] = competitor.copyWith(
        dartThrows: [...competitor.dartThrows, canonical],
        score: 0,
      );
      return EngineResult(
        state: state.copyWith(
          competitors: updatedCompetitors,
          dartsThrownInTurn: state.dartsThrownInTurn + 1,
        ),
        outcome: LegOutcome.gameCompleted,
        winnerCompetitorId: competitor.competitorId,
      );
    }

    // Bust: score < 0, lands on 1, or reaches 0 on non-double.
    // dartsThrownInTurn is set to 3 so the provider treats the turn as full
    // and the NEXT ROUND button becomes available immediately. Record the
    // bust dart in dartThrows (X01 does the same — without this, replay and
    // any other consumer of CompetitorState.dartThrows would silently lose
    // the dart that caused the bust). Pad remaining slots with 'MISS' so
    // dartThrows.length stays aligned with dartsThrownInTurn = 3.
    if (newScore < 2) {
      final canonical =
          Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();
      final dartsActuallyThrown = state.dartsThrownInTurn + 1;
      final missesToPad = 3 - dartsActuallyThrown;
      final paddedDartThrows = [
        ...competitor.dartThrows,
        canonical,
        for (var i = 0; i < missesToPad; i++) 'MISS',
      ];
      updatedCompetitors[state.currentTurnIndex] = competitor.copyWith(
        score: competitor.turnStartScore ?? competitor.score,
        dartThrows: paddedDartThrows,
      );
      return EngineResult(
        state: state.copyWith(
          competitors: updatedCompetitors,
          dartsThrownInTurn: 3,
        ),
        isBust: true,
      );
    }

    // Normal: subtract dart value
    final canonical =
        Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();
    updatedCompetitors[state.currentTurnIndex] = competitor.copyWith(
      dartThrows: [...competitor.dartThrows, canonical],
      score: newScore,
    );
    return EngineResult(
      state: state.copyWith(
        competitors: updatedCompetitors,
        dartsThrownInTurn: state.dartsThrownInTurn + 1,
      ),
    );
  }

  GameState _applyTurnEnded(GameState state) {
    return state.copyWith(
      dartsThrownInTurn: 0,
      turnActive: false,
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

  int _dartValue(int segment, int multiplier) {
    if (segment == 0) return 0;
    return segment * multiplier;
  }

  bool _isDouble(int segment, int multiplier) {
    if (segment == 0) return false;
    return multiplier == 2;
  }

}
