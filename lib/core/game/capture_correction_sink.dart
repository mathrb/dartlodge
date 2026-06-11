/// A feature-agnostic port for propagating a user's dart correction into the
/// auto-scorer's training capture for the *current* turn. The auto-scorer
/// (auto_scorer feature) registers an implementation — it owns the capture
/// store and the live turn ordinal; the game's correction flow (game feature)
/// calls through it. Neither feature imports the other; the bridge lives in
/// `core/` (CLAUDE.md: cross-feature communication via `core/` only). This is
/// the inverse direction of [DartInputSink] (auto-scorer binds, game calls).
abstract interface class CaptureCorrectionSink {
  /// The user corrected dart [dartInTurnOrdinal] (1-based, within the active
  /// turn) to [segment] (canonical: '20','D20','T20','SB','DB','MISS'); flip
  /// the matching capture's `was_corrected` and record the corrected segment.
  /// Corrections only ever target the current turn, so the implementation
  /// supplies the turn ordinal + game id from its own context. Best-effort
  /// metadata enrichment — it must never block or affect game state, and is a
  /// no-op when no capture exists for the dart.
  void correctDart({required int dartInTurnOrdinal, required String segment});
}
