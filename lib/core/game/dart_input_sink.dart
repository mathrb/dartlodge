/// A feature-agnostic port for feeding darts into whatever game is currently
/// active. The game board (game feature) registers an implementation; the
/// auto-scorer (auto_scorer feature) emits through it — neither feature imports
/// the other, the bridge lives in `core/` (CLAUDE.md: cross-feature
/// communication via `core/` only).
abstract interface class DartInputSink {
  /// Emit one detected dart, as a canonical segment string ('20','D20','T20',
  /// 'SB','DB','MISS') — routed to the active game's manual dart-entry path.
  void submitDart(String segment);

  /// Advance to the next turn (the manual next-turn action of the active game).
  void advanceTurn();
}
