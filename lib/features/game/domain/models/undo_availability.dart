import 'game_state.dart';

/// Whether the X01 / Cricket "undo last dart" action has a dart to remove.
///
/// True mid-turn, when any competitor holds darts in the current leg, and at
/// the start of any leg after the first: a won leg's darts are cleared by the
/// engine's leg reset, but the leg-winning dart is still the newest
/// `DartThrown` in the log, and `UndoLastDartUseCase` supersedes the
/// `TurnEnded` / `LegCompleted` / next-leg `TurnStarted` that followed it, so
/// undoing it reopens the won leg. A completed game is read-only.
bool canUndoLastDart(GameState gs) {
  if (gs.isComplete) return false;
  return gs.dartsThrownInTurn > 0 ||
      gs.currentLegIndex > 0 ||
      gs.competitors.any((c) => c.dartThrows.isNotEmpty);
}
