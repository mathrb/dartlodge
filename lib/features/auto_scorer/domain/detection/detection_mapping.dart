import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';

/// Maps the model's class indices to the unified-net classes (#377 §2). The
/// production model emits `{0: dart, 1: cal1, 2: cal2, 3: cal3, 4: cal4}`.
class DetectorClassMap {
  final int dart;
  final int cal1;
  final int cal2;
  final int cal3;
  final int cal4;

  const DetectorClassMap({
    this.dart = 0,
    this.cal1 = 1,
    this.cal2 = 2,
    this.cal3 = 3,
    this.cal4 = 4,
  });

  List<int> get calClasses => [cal1, cal2, cal3, cal4];
}

/// Turn raw model detections into a [DetectionFrame] for the tracker.
///
/// Each calibration point is the highest-confidence detection of its class
/// (the detector should emit one of each, but duplicates are resolved by
/// confidence). Calibration is reported only when **all four** cal points are
/// present — a missing cal point yields an empty `calPoints`, which the tracker
/// reads as "no calibration this frame" (occlusion-tolerant, #380). Every
/// dart-class detection at or above [minConfidence] becomes a candidate; the
/// confirm-before-emit logic downstream rejects transient false positives.
DetectionFrame buildDetectionFrame(
  List<RawDetection> detections, {
  DetectorClassMap classes = const DetectorClassMap(),
  double minConfidence = 0.0,
}) {
  BoardPoint? bestOf(int classIndex) {
    RawDetection? best;
    for (final d in detections) {
      if (d.classIndex != classIndex || d.conf < minConfidence) continue;
      if (best == null || d.conf > best.conf) best = d;
    }
    return best == null ? null : (x: best.x, y: best.y);
  }

  final cals = [for (final c in classes.calClasses) bestOf(c)];
  final calPoints =
      cals.any((c) => c == null) ? const <BoardPoint>[] : [for (final c in cals) c!];

  final darts = <BoardPoint>[
    for (final d in detections)
      if (d.classIndex == classes.dart && d.conf >= minConfidence)
        (x: d.x, y: d.y),
  ];

  return DetectionFrame(calPoints: calPoints, dartCandidates: darts);
}
