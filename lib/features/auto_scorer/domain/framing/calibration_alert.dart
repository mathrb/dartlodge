import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';

/// How the presentation layer should read the tracker's "no calibration" phases
/// (#741, design S2.2).
///
/// [TrackerPhase.needsCalibration] conflates two unrelated situations that were
/// shown identically as a red alert:
///
///   * the camera **never** recognised the board in this camera session — a
///     valid way to play, where the player simply scores by hand;
///   * the camera **had** the board and lost it — a real problem to act on.
///
/// Showing the first as a permanent red alarm for a whole game reads as "the
/// app is broken". Splitting them is presentation-only: the tracker's phases
/// are untouched.
enum CalibrationAlert {
  /// Nothing to say about calibration — the chip renders its phase normally.
  none,

  /// Never calibrated in this camera session. Calm, named as a mode.
  learningMode,

  /// Was calibrated, then lost it. The existing red alert, which is legitimate.
  lost,
}

/// True when [phase], **as reported for a processed frame**, can only be
/// reached once the board has been calibrated.
///
/// `DartTracker.processFrame` reaches these phases from its calibrated branch,
/// or (for `tracking`/`turnFull`) through the held-homography continuation,
/// which needs a transform derived from an earlier calibrated frame (#485). So
/// a frame reporting any of them is proof this camera session saw the board at
/// least once.
///
/// Feed it frame statuses only. `DartTracker.removeDarts()` also returns
/// `rebaselined`, and that one is a button press — it proves nothing about
/// calibration. The overlay keeps them apart: the manual path publishes its
/// status directly and never reaches this latch.
bool phaseImpliesCalibration(TrackerPhase phase) {
  switch (phase) {
    case TrackerPhase.noCalibration:
    case TrackerPhase.needsCalibration:
      return false;
    case TrackerPhase.idle:
    case TrackerPhase.tracking:
    case TrackerPhase.turnFull:
    case TrackerPhase.cameraMoved:
    case TrackerPhase.rebaselined:
      return true;
  }
}

/// Classify [phase] given whether this camera session has ever been calibrated.
///
/// [everCalibrated] is the session-scoped memory the caller keeps: seeded by an
/// aim step that ended with the four markers, and set by any status whose phase
/// [phaseImpliesCalibration]. Only the sustained-loss phase is classified — the
/// single-frame [TrackerPhase.noCalibration] is transient and never alarms.
CalibrationAlert calibrationAlertOf({
  required TrackerPhase phase,
  required bool everCalibrated,
}) {
  if (phase != TrackerPhase.needsCalibration) return CalibrationAlert.none;
  return everCalibrated ? CalibrationAlert.lost : CalibrationAlert.learningMode;
}
