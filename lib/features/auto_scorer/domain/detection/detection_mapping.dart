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
/// confidence). A cal point counts only at or above [calMinConfidence], and
/// calibration is reported only when **all four** are present — a missing cal
/// yields an empty `calPoints`, which the tracker reads as "no calibration this
/// frame" (occlusion-tolerant, #380). Every dart-class detection at or above
/// [dartMinConfidence] becomes a candidate; confirm-before-emit downstream
/// rejects transient false positives.
///
/// [DetectionFrame.calConfidences] records the best confidence per cal class
/// regardless of [calMinConfidence] (so the HUD can show a cal that's present
/// but below the threshold, for tuning).
DetectionFrame buildDetectionFrame(
  List<RawDetection> detections, {
  DetectorClassMap classes = const DetectorClassMap(),
  double calMinConfidence = 0.0,
  double dartMinConfidence = 0.0,
}) {
  RawDetection? bestOf(int classIndex) {
    RawDetection? best;
    for (final d in detections) {
      if (d.classIndex != classIndex) continue;
      if (best == null || d.conf > best.conf) best = d;
    }
    return best;
  }

  final calBest = [for (final c in classes.calClasses) bestOf(c)];
  // Diagnostic: best conf per cal class (or null), independent of the threshold.
  final calConfidences = [for (final b in calBest) b?.conf];
  // Diagnostic: best position per cal class (or null) — index-aligned with
  // calConfidences. Exposes partial cals (the aim overlay shows which the model
  // sees) even though calPoints stays all-or-nothing for the tracker.
  final calBestPoints = [
    for (final b in calBest) b == null ? null : (x: b.x, y: b.y)
  ];
  // Calibration uses only cals at/above the threshold; all-or-nothing.
  final accepted =
      [for (final b in calBest) (b != null && b.conf >= calMinConfidence) ? b : null];
  final calPoints = accepted.any((b) => b == null)
      ? const <BoardPoint>[]
      : [for (final b in accepted) (x: b!.x, y: b.y)];

  // Dart candidates and their confidences, built in lockstep so
  // dartConfidences[i] is the conf of dartCandidates[i].
  final darts = <BoardPoint>[];
  final dartConfidences = <double>[];
  for (final d in detections) {
    if (d.classIndex == classes.dart && d.conf >= dartMinConfidence) {
      darts.add((x: d.x, y: d.y));
      dartConfidences.add(d.conf);
    }
  }

  return DetectionFrame(
    calPoints: calPoints,
    dartCandidates: darts,
    calConfidences: calConfidences,
    calBestPoints: calBestPoints,
    dartConfidences: dartConfidences,
  );
}
