import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';

/// Model class-name → class-index map for the unified net (#377 §2). The class
/// **name** is the reliable identity in `ultralytics_yolo`'s output (the numeric
/// index is hardcoded to 0 for the detect task in plugin 0.4.3), so we resolve
/// the index from the name here.
const Map<String, int> kDefaultClassNameToIndex = {
  'dart': 0,
  'cal1': 1,
  'cal2': 2,
  'cal3': 3,
  'cal4': 4,
};

/// Parse the `ultralytics_yolo` `predict()` result map into [RawDetection]s.
///
/// Kept pure (it only touches the documented map shape, never the plugin type)
/// so the error-prone map fiddling is unit-testable without a device. The
/// plugin's `result['boxes']` entries carry the **raw** detector keys:
/// `{'class': <name>, 'confidence': <0–1>, 'x1_norm','y1_norm','x2_norm',
/// 'y2_norm'}` (normalised box corners). We map the class name to its index via
/// [classNameToIndex], take the box centre as the detection point, and skip
/// entries whose class name isn't in the map.
List<RawDetection> parseYoloDetections(
  Map<String, dynamic> result, {
  Map<String, int> classNameToIndex = kDefaultClassNameToIndex,
}) {
  final boxes = result['boxes'];
  if (boxes is! List) return const [];

  final out = <RawDetection>[];
  for (final box in boxes) {
    if (box is! Map) continue;
    final name = box['class'];
    final conf = (box['confidence'] as num?)?.toDouble();
    if (name is! String || conf == null) continue;
    final classIndex = classNameToIndex[name];
    if (classIndex == null) continue; // class not part of this model
    final left = (box['x1_norm'] as num?)?.toDouble();
    final top = (box['y1_norm'] as num?)?.toDouble();
    final right = (box['x2_norm'] as num?)?.toDouble();
    final bottom = (box['y2_norm'] as num?)?.toDouble();
    if (left == null || top == null || right == null || bottom == null) continue;
    out.add(RawDetection(
      classIndex: classIndex,
      x: (left + right) / 2,
      y: (top + bottom) / 2,
      conf: conf,
    ));
  }
  return out;
}
