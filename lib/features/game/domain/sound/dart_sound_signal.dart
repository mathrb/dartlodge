import '../models/game_state.dart';

/// The canonical segment ('T20', 'MISS', 'SB', …) of the dart just thrown
/// between [prev] and [next], or null if this state change isn't a single new
/// dart.
///
/// The only robust, game-agnostic signal is `dartsThrownInTurn` incrementing by
/// exactly one on the same competitor. Everything else has a delta != +1 and is
/// (correctly) ignored:
/// - **bust** jumps `dartsThrownInTurn` straight to 3 and pads `dartThrows` with
///   MISS (bust is handled separately, via the `showBust` transition);
/// - **turn end / leg reset** resets the counter to 0;
/// - **checkout-practice turn-end padding** writes sentinel slots, not a +1 dart;
/// - **undo** decreases the counter.
///
/// On a genuine new dart the thrown segment is the active competitor's most
/// recently appended throw.
String? newestDartSegment(GameState? prev, GameState? next) {
  if (prev == null || next == null) return null;
  if (next.currentTurnIndex != prev.currentTurnIndex) return null;
  if (next.dartsThrownInTurn != prev.dartsThrownInTurn + 1) return null;
  final darts = next.competitors[next.currentTurnIndex].dartThrows;
  return darts.isEmpty ? null : darts.last;
}
