import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';

/// Parse the `ultralytics_yolo` `predict()` result map into [RawDetection]s.
///
/// Kept pure (it only touches the documented map shape, never the plugin type)
/// so the error-prone map fiddling is unit-testable without a device. The
/// plugin returns `{'boxes': [ {classIndex, confidence, normalizedBox:{left,
/// top,right,bottom}}, ... ]}`; we take the box centre as the detection point.
List<RawDetection> parseYoloDetections(Map<String, dynamic> result) {
  final boxes = result['boxes'];
  if (boxes is! List) return const [];

  final out = <RawDetection>[];
  for (final box in boxes) {
    if (box is! Map) continue;
    final classIndex = (box['classIndex'] as num?)?.toInt();
    final conf = (box['confidence'] as num?)?.toDouble();
    final nb = box['normalizedBox'];
    if (classIndex == null || conf == null || nb is! Map) continue;
    final left = (nb['left'] as num?)?.toDouble();
    final top = (nb['top'] as num?)?.toDouble();
    final right = (nb['right'] as num?)?.toDouble();
    final bottom = (nb['bottom'] as num?)?.toDouble();
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
