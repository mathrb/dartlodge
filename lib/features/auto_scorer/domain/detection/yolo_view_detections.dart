import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_result_parser.dart'
    show kDefaultClassNameToIndex;

/// A YOLOView detection reduced to the primitives we need, decoupled from the
/// plugin's `YOLOResult` type so this mapping stays a pure, testable `domain/`
/// function (the plugin-bound `YOLOResult → ClassedDetection` step lives in the
/// mobile-only widget).
typedef ClassedDetection = ({
  String className,
  double confidence,
  double cx, // normalised box-centre x (0–1)
  double cy, // normalised box-centre y (0–1)
});

/// Map YOLOView-style classed detections to [RawDetection]s, resolving the class
/// index from the **name** (the plugin hardcodes the numeric index to 0 for the
/// detect task, so the name is the reliable identity) and dropping classes not
/// in [classNameToIndex]. Feed the result to `buildDetectionFrame`.
List<RawDetection> rawDetectionsFromClassed(
  List<ClassedDetection> detections, {
  Map<String, int> classNameToIndex = kDefaultClassNameToIndex,
}) {
  final out = <RawDetection>[];
  for (final d in detections) {
    final idx = classNameToIndex[d.className];
    if (idx == null) continue; // class not part of this model
    out.add(RawDetection(classIndex: idx, x: d.cx, y: d.cy, conf: d.confidence));
  }
  return out;
}
