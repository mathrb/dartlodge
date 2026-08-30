/// How the fullscreen aim step ended (#741).
///
/// It used to pop a bare `bool`, which collapsed the two ways of proceeding
/// into one value: "Done aiming" (four markers found) and "Continue without
/// auto-scoring" (markers never resolved) both popped `true`. The overlay needs
/// to tell them apart — the second one starts the game in learning mode, where
/// a missing calibration is the expected state and not an alert.
///
/// Pure enum in `domain/` so the web-safe overlay shell can name it without
/// importing the mobile-only aim view.
enum AimOutcome {
  /// Cancelled / backed out — do not start the camera.
  cancelled,

  /// Confirmed with the four calibration markers present.
  calibrated,

  /// Confirmed WITHOUT calibration: the player chose to play and score by hand.
  uncalibrated,
}
