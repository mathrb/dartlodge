import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// One inference result handed to the [DartTracker]: the four calibration
/// points and the candidate dart-tip positions the model found in this frame.
///
/// Coordinates are image-space, normalised 0–1 in the 800×800 detection frame
/// (#377 §6). [calPoints], when present, must be in DeepDarts order
/// (cal1=5/20 wire, cal2=3/17, cal3=8/11, cal4=13/6); an incomplete set (the
/// board is occluded or out of view) is reported via [hasCalibration].
class DetectionFrame {
  final List<BoardPoint> calPoints;
  final List<BoardPoint> dartCandidates;

  /// Best confidence the model gave for each cal class `[cal1, cal2, cal3,
  /// cal4]`, or null where that class wasn't detected this frame. **Diagnostic
  /// only** (surfaced in the HUD to tune the calibration threshold) — the
  /// tracker reads [calPoints]/[hasCalibration], not this. Defaults to all-null
  /// so non-detector constructors (tests) need not supply it.
  final List<double?> calConfidences;

  const DetectionFrame({
    required this.calPoints,
    required this.dartCandidates,
    this.calConfidences = const [null, null, null, null],
  });

  /// True when all four calibration points were detected this frame — required
  /// to derive or hold the rectification homography.
  bool get hasCalibration => calPoints.length == 4;

  /// True when no dart candidates were detected (an empty-board observation —
  /// not yet a re-baseline; the tracker counts consecutive empties).
  bool get isEmpty => dartCandidates.isEmpty;
}
