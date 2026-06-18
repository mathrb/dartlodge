/// Tunable knobs for the [DartTracker]. Defaults are reasonable starting
/// points; the real values are tuned on captured data (#377 §11), not designed
/// here. [matchTolerance] is in **canonical** units where the board's
/// double-ring radius is 1.0 (a fraction of the board radius); [calShiftThreshold]
/// is in **image** space (normalised 0–1) — see each field's doc.
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
  ///
  /// This is a **confirm-before-clear** gate symmetric to [confirmFrames]: the
  /// board must read empty for K consecutive calibrated frames before the
  /// baseline (and the confirmed darts) are cleared. Confirmed darts are
  /// retained during the streak, so a dart that reappears before K resets the
  /// count and re-matches without re-emitting.
  ///
  /// At the production inference rate (`kAutoScorerInferenceHz` = 3 Hz, see
  /// `auto_scorer_yolo_view_io.dart`), the default 9 ≈ **3 seconds** — long
  /// enough to reject a transient dart-detection flicker or a brief darts-only
  /// occlusion (~1s, cals still visible) without a false clear, while a genuine
  /// pull (board empty for several seconds as the player collects the darts)
  /// still clears normally. A too-short window (the old default of 3 ≈ 1s) made
  /// a flicker look like a pull → premature turn advance + double-counted dart
  /// (#499).
  final int emptyFramesToRebaseline;

  /// Mean per-cal-point image-space displacement (normalised 0–1) above which a
  /// frame is treated as a phone bump → re-baseline + "camera moved" (#377 §3).
  final double calShiftThreshold;

  /// Darts a single turn may hold before the cap blocks emission (#377 §3.6).
  final int maxDartsPerTurn;

  /// Consecutive frames with **no calibration and no darts** before the status
  /// escalates from the transient `noCalibration` to a sticky `needsCalibration`
  /// alert ("camera can't see the board"). Debounced so a single dropped frame
  /// (an arm briefly occluding a cal dot mid-throw) doesn't flash the warning.
  final int noCalibrationFramesToWarn;

  const DartTrackerConfig({
    this.matchTolerance = 0.06,
    this.confirmFrames = 2,
    this.pendingMissTolerance = 2,
    this.emptyFramesToRebaseline = 9,
    this.calShiftThreshold = 0.08,
    this.maxDartsPerTurn = 3,
    this.noCalibrationFramesToWarn = 3,
  });
}
