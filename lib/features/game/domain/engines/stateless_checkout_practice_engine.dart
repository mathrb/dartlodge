// Stateless Checkout Practice Engine
// Solo X01-style drill from 170 with double-out rules.
// Score starts at 170 and decreases with each dart thrown.
// Bust (score < 0, == 1, or 0 on non-double): reverts to turn-start score, turn ends.
// Checkout (score == 0 on a double): increments `practiceSuccesses`. The drill
// only ends once the count reaches `checkoutTargetSuccesses`; when that field
// is `null` (∞ in the config picker) the drill continues until the user taps
// End Drill. Completion is decided at TurnEnded time so the event log carries
// a tidy `DartThrown → TurnEnded(reason='checkout') → GameCompleted` sequence
// — projection counts the final attempt + success correctly (#254).

import '../models/game_config.dart';
import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

/// Slot value the engine writes into `dartThrows` when a turn ends
/// with fewer than 3 real darts thrown (bust / checkout). Display
/// widgets filter on this to render a "dart not thrown" placeholder
/// instead of a phantom MISS chip (#261). Public so consumers can
/// reference it by name rather than re-typing the literal.
const String emptyDartSlotSentinel = '';

class StatelessCheckoutPracticeEngine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => _applyDartThrown(state, event),
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
    final idx =
        competitorIndex >= 0 ? competitorIndex : state.currentTurnIndex;
    final competitor = state.competitors[idx];
    // After a successful checkout (multi-success mode), `_applyDartThrown`
    // leaves `score = 0` so the projection's `_turnEndedReason` can detect
    // the checkout from state. The next TurnStarted resets score back to
    // `startingScore` (170) — otherwise `turnStartScore` would lock in 0
    // and any bust on the new attempt would revert score to 0, blocking
    // future checkouts.
    final freshScore =
        competitor.score == 0 ? competitor.startingScore : competitor.score;
    final updatedCompetitor = competitor.copyWith(
      score: freshScore,
      turnStartScore: freshScore,
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
      // Pad up to 3 darts with the empty-slot sentinel so
      // `dartThrows.length == dartsThrownInTurn (3)` — many downstream
      // consumers (round counter formula, leg snapshots) depend on that
      // invariant. The empty string is a sentinel: status badges and
      // dart-count displays filter it out so the user doesn't see
      // phantom MISSes that they never threw (#261).
      final dartsActuallyThrown = state.dartsThrownInTurn + 1;
      final padsToAdd = 3 - dartsActuallyThrown;
      final paddedDartThrows = [
        ...competitor.dartThrows,
        canonical,
        for (var i = 0; i < padsToAdd; i++) emptyDartSlotSentinel,
      ];
      updatedCompetitors[state.currentTurnIndex] = competitor.copyWith(
        dartThrows: paddedDartThrows,
        score: 0,
        practiceSuccesses: competitor.practiceSuccesses + 1,
      );
      // Do NOT return `gameCompleted` here — completion is decided in
      // `_applyTurnEndedWithOutcome` so the event stream is always
      // `DartThrown → TurnEnded(reason='checkout') → GameCompleted` when
      // the drill ends. Without that ordering the projection misses the
      // attempt + success that ended the drill (#254). When
      // `checkoutTargetSuccesses` is null (∞), the engine never reaches
      // completion via TurnEnded — the drill ends only via End Drill.
      return EngineResult(
        state: state.copyWith(
          competitors: updatedCompetitors,
          dartsThrownInTurn: 3,
        ),
      );
    }

    // Bust: score < 0, lands on 1, or reaches 0 on non-double.
    // dartsThrownInTurn is set to 3 so the provider treats the turn as
    // full and the NEXT ROUND button becomes available immediately.
    // Record the bust dart (X01 does the same — without it replay would
    // silently lose the throw that caused the bust). Pad remaining
    // slots with the empty-slot sentinel so display widgets render
    // them as "dart not thrown" instead of phantom MISSes (#261).
    if (newScore < 2) {
      final canonical =
          Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();
      final dartsActuallyThrown = state.dartsThrownInTurn + 1;
      final padsToAdd = 3 - dartsActuallyThrown;
      final paddedDartThrows = [
        ...competitor.dartThrows,
        canonical,
        for (var i = 0; i < padsToAdd; i++) emptyDartSlotSentinel,
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

  /// Decides drill completion at TurnEnded time: when the running count of
  /// successful checkouts on the current competitor matches the configured
  /// `checkoutTargetSuccesses` quota, surface `gameCompleted` so the
  /// provider's `_advanceTurn` emits a single GameCompleted alongside the
  /// closing TurnEnded. When the quota is `null` (∞), this returns a plain
  /// `EngineResult` and the drill continues until the user taps End Drill.
  EngineResult _applyTurnEndedWithOutcome(GameState state, GameEvent event) {
    final newState = _applyTurnEnded(state);
    final target = state.checkoutTargetSuccesses;
    if (target == null || state.isComplete) {
      return EngineResult(state: newState);
    }
    final comp = newState.competitors[newState.currentTurnIndex];
    if (comp.practiceSuccesses >= target) {
      return EngineResult(
        state: newState.copyWith(
          isComplete: true,
          status: GameEngineStatus.completed,
          winnerCompetitorId: comp.competitorId,
        ),
        outcome: LegOutcome.gameCompleted,
        winnerCompetitorId: comp.competitorId,
      );
    }
    return EngineResult(state: newState);
  }

  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_competitor_id'] as String? ?? event.payload['winner_id'] as String?,
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
