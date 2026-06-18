import '../models/game_state.dart';

/// The canonical segment ('T20', 'MISS', 'SB', …) of the dart just thrown
/// between [prev] and [next], or null if this state change isn't a single new
/// dart. The thrown segment is the active competitor's most recently appended
/// throw.
///
/// The signal is `dartsThrownInTurn` incrementing by exactly one on the same
/// competitor. Cases with a delta != +1 are ignored here:
/// - **turn end / leg reset** resets the counter to 0. Note a dart that
///   *completes a leg* in a multi-leg game also resets in the same emission
///   (clearing `dartThrows`), so it produces no hit sound — a known v1
///   limitation (v1 intentionally has no leg/game-win cues; single-leg games and
///   the final game-winning dart are unaffected).
/// - **X01 bust on the 1st/2nd dart** jumps the counter straight to 3;
/// - **undo** decreases the counter.
///
/// Busts are NOT fully filtered out here: a 3rd-dart bust, and any Catch-40 bust
/// (which increments by a normal +1), still land on a +1 delta. The caller
/// ([wireGameSounds]) checks the `showBust` transition first and returns, so a
/// busting dart plays only the bust cue — any caller MUST apply that same
/// bust-first guard rather than rely on this filter to exclude busts.
String? newestDartSegment(GameState? prev, GameState? next) {
  if (prev == null || next == null) return null;
  if (next.currentTurnIndex != prev.currentTurnIndex) return null;
  if (next.dartsThrownInTurn != prev.dartsThrownInTurn + 1) return null;
  final darts = next.competitors[next.currentTurnIndex].dartThrows;
  return darts.isEmpty ? null : darts.last;
}
