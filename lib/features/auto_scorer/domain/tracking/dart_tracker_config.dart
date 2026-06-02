/// Tunable knobs for the [DartTracker]. Defaults are reasonable starting
/// points; the real values are tuned on captured data (#377 §11), not designed
/// here. All distance thresholds are in **canonical** units where the board's
/// double-ring radius is 1.0 (so they read as fractions of the board radius).
class DartTrackerConfig {
  /// Max canonical distance between a detection and a known dart for them to be
  /// considered the *same* dart. Too tight → one dart emitted twice; too loose
  /// → two nearby darts merge into one (#377 §3.3).
  final double matchTolerance;

  /// Number of frames a new candidate must persist (within its TTL window)
  /// before it is confirmed and emitted — the confirm-before-emit guard that
  /// rejects single-frame jitter phantoms (#377 §3.4).
  final int confirmFrames;

  /// How many consecutive frames a pending candidate may go unseen before it is
  /// discarded as noise.
  final int pendingMissTolerance;

  /// Consecutive empty-board frames before an auto re-baseline (K, #377 §3).
  final int emptyFramesToRebaseline;

  /// Mean per-cal-point image-space displacement (normalised 0–1) above which a
  /// frame is treated as a phone bump → re-baseline + "camera moved" (#377 §3).
  final double calShiftThreshold;

  /// Darts a single turn may hold before the cap blocks emission (#377 §3.6).
  final int maxDartsPerTurn;

  const DartTrackerConfig({
    this.matchTolerance = 0.06,
    this.confirmFrames = 2,
    this.pendingMissTolerance = 2,
    this.emptyFramesToRebaseline = 3,
    this.calShiftThreshold = 0.08,
    this.maxDartsPerTurn = 3,
  });
}
