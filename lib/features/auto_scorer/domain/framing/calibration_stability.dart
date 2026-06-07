import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';

/// Outcome of feeding one frame to a [CalibrationStabilityGate]: how many
/// consecutive stable calibrated frames have been seen, and whether that has
/// reached the "ready" bar.
typedef CalibrationStability = ({int stableFrames, bool isReady});

/// Presentation-fed readiness gate for the aim view (#393 setup flow): it only
/// reports "ready" once the four calibration points have held *stably* across
/// several frames, so the user doesn't commit on a single lucky frame whose cals
/// would drift away the moment scoring starts.
///
/// Pure domain logic — no Flutter, no tracker mutation. The aim view feeds each
/// [DetectionFrame] in and reads the result; this does NOT change the temporal
/// [DartTracker] (explicitly out of scope). The "stable" test reuses the
/// tracker's own cal-shift semantics ([DartTrackerConfig.calShiftThreshold],
/// mean per-cal image-space displacement) so the two stay aligned.
class CalibrationStabilityGate {
  CalibrationStabilityGate({
    this.requiredStableFrames = 3,
    double? calShiftThreshold,
  }) : calShiftThreshold =
            calShiftThreshold ?? const DartTrackerConfig().calShiftThreshold;

  /// Consecutive stable calibrated frames required before [CalibrationStability.isReady].
  final int requiredStableFrames;

  /// Mean per-cal image-space displacement (normalised 0–1) at or below which a
  /// frame counts as "held steady" relative to the previous calibrated frame.
  final double calShiftThreshold;

  List<BoardPoint>? _lastCals;
  int _stableFrames = 0;

  /// Feed one inference result. Resets to zero on any frame without full
  /// calibration; resets the counter to 1 (this frame becomes the new baseline)
  /// when the cals jump beyond [calShiftThreshold]; otherwise increments.
  CalibrationStability update(DetectionFrame frame) {
    if (!frame.hasCalibration) {
      _stableFrames = 0;
      _lastCals = null;
      return (stableFrames: 0, isReady: false);
    }
    final last = _lastCals;
    if (last == null || _meanShift(last, frame.calPoints) > calShiftThreshold) {
      _stableFrames = 1;
    } else {
      _stableFrames += 1;
    }
    _lastCals = frame.calPoints;
    return (
      stableFrames: _stableFrames,
      isReady: _stableFrames >= requiredStableFrames,
    );
  }

  double _meanShift(List<BoardPoint> a, List<BoardPoint> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final dx = a[i].x - b[i].x;
      final dy = a[i].y - b[i].y;
      sum += math.sqrt(dx * dx + dy * dy);
    }
    return sum / a.length;
  }
}
