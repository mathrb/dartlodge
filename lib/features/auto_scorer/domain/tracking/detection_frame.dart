import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// One inference result handed to the [DartTracker]: the four calibration
/// points and the candidate dart-tip positions the model found in this frame.
///
/// Coordinates are image-space, normalised 0–1 in the detection frame
/// (#377 §6). [calPoints], when present, must be in DeepDarts order
/// (cal1=5/20 wire, cal2=3/17, cal3=8/11, cal4=13/6); an incomplete set (the
/// board is occluded or out of view) is reported via [hasCalibration].
class DetectionFrame {
  final List<BoardPoint> calPoints;
  final List<BoardPoint> dartCandidates;

  const DetectionFrame({
    required this.calPoints,
    required this.dartCandidates,
  });

  /// True when all four calibration points were detected this frame — required
  /// to derive or hold the rectification homography.
  bool get hasCalibration => calPoints.length == 4;

  /// True when no dart candidates were detected (an empty-board observation —
  /// not yet a re-baseline; the tracker counts consecutive empties).
  bool get isEmpty => dartCandidates.isEmpty;
}
