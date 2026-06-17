/// A feature-agnostic port for feeding darts into whatever game is currently
/// active. The game board (game feature) registers an implementation; the
/// auto-scorer (auto_scorer feature) emits through it — neither feature imports
/// the other, the bridge lives in `core/` (CLAUDE.md: cross-feature
/// communication via `core/` only).
abstract interface class DartInputSink {
  /// Emit one detected dart, as a canonical segment string ('20','D20','T20',
  /// 'SB','DB','MISS') — routed to the active game's dart-entry path. Camera
  /// input is best-effort: a dart that lands on a full/ended turn or a
  /// completed game is silently dropped rather than processed (#538), so the
  /// tracker getting ahead of the game can never wedge the board.
  void submitDart(String segment);

  /// Advance to the next turn/player without any confirmation prompt — invoked
  /// by the auto-scorer's opt-in "auto-advance when board is cleared" feature
  /// (gated by `autoAdvanceOnClearEnabledProvider`). Mirrors the board's manual
  /// next-turn button: the implementation also bumps `activeTurnSignal` so the
  /// tracker's per-turn cap resets in lock-step. Implementations must no-op when
  /// a celebration/bust modal is pending or the game is complete, so an
  /// auto-advance never dismisses a leg/game-win modal the player hasn't seen.
  void advanceTurn();
}
