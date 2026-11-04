// Leg rotation — who throws first in each leg of a multi-leg match, and the
// round bookkeeping that depends on it. Shared by the X01 and Cricket engines.

import '../models/game_state.dart';

/// The competitor index that throws first in leg [legIndex] (0-based).
///
/// The throw alternates leg by leg, because throwing first is an advantage:
/// with two players the first player starts legs 1, 3, 5… and the second
/// player starts legs 2, 4, 6…, regardless of who won the previous leg. With
/// three or more players the start rotates round-robin, keeping the turn
/// order within each leg.
int legStarterIndexFor(int legIndex, int competitorCount) =>
    competitorCount <= 0 ? 0 : legIndex % competitorCount;

/// Leg starter and round number after a `TurnStarted` for [competitorIndex].
///
/// The first `TurnStarted` of a leg (no competitor has thrown in it yet) fixes
/// the leg starter, so a stream recorded before starters rotated replays with
/// the starter it was actually played with. A new round begins each time the
/// turn comes back to the leg starter after they have thrown.
({int legStarterIndex, int round}) roundAfterTurnStarted(
  GameState state,
  int competitorIndex,
) {
  final legNotStarted = state.competitors.every((c) => c.dartThrows.isEmpty);
  if (legNotStarted) {
    return (legStarterIndex: competitorIndex, round: state.currentRoundInLeg);
  }
  final starter = state.legStarterIndex;
  final backToStarter = competitorIndex == starter &&
      state.competitors[starter].dartThrows.isNotEmpty;
  return (
    legStarterIndex: starter,
    round: backToStarter ? state.currentRoundInLeg + 1 : state.currentRoundInLeg,
  );
}

/// Whether the active turn is the last one of the current round, i.e. the
/// competitor just before the leg starter in turn order.
bool isLastTurnOfRound(GameState state) {
  final count = state.competitors.length;
  return state.currentTurnIndex == (state.legStarterIndex + count - 1) % count;
}
