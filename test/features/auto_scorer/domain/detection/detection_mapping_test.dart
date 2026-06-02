import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_result_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseYoloDetections', () {
    Map<String, dynamic> box(int cls, double conf, double l, double t, double r, double b) =>
        {
          'classIndex': cls,
          'confidence': conf,
          'normalizedBox': {'left': l, 'top': t, 'right': r, 'bottom': b},
        };

    test('reads class, confidence, and box centre', () {
      final dets = parseYoloDetections({
        'boxes': [box(0, 0.9, 0.4, 0.4, 0.6, 0.6)]
      });
      expect(dets, hasLength(1));
      expect(dets.single.classIndex, 0);
      expect(dets.single.conf, 0.9);
      expect(dets.single.x, closeTo(0.5, 1e-9));
      expect(dets.single.y, closeTo(0.5, 1e-9));
    });

    test('tolerates missing / malformed entries', () {
      expect(parseYoloDetections(const {}), isEmpty);
      expect(parseYoloDetections({'boxes': 'nope'}), isEmpty);
      expect(parseYoloDetections({'boxes': [42, {}, {'classIndex': 1}]}), isEmpty);
    });
  });

  group('buildDetectionFrame', () {
    RawDetection det(int cls, double x, double y, double conf) =>
        RawDetection(classIndex: cls, x: x, y: y, conf: conf);

    test('full cal set + darts → calibrated frame', () {
      final frame = buildDetectionFrame([
        det(1, 0.5, 0.2, 0.9), // cal1
        det(2, 0.5, 0.8, 0.9), // cal2
        det(3, 0.2, 0.5, 0.9), // cal3
        det(4, 0.8, 0.5, 0.9), // cal4
        det(0, 0.55, 0.45, 0.8), // dart
        det(0, 0.60, 0.50, 0.8), // dart
      ]);
      expect(frame.hasCalibration, isTrue);
      expect(frame.calPoints, hasLength(4));
      expect(frame.calPoints.first, (x: 0.5, y: 0.2)); // cal order preserved
      expect(frame.dartCandidates, hasLength(2));
    });

    test('a missing cal point yields no calibration (occlusion-tolerant)', () {
      final frame = buildDetectionFrame([
        det(1, 0.5, 0.2, 0.9),
        det(2, 0.5, 0.8, 0.9),
        det(3, 0.2, 0.5, 0.9),
        // cal4 absent
        det(0, 0.55, 0.45, 0.8),
      ]);
      expect(frame.hasCalibration, isFalse);
      expect(frame.calPoints, isEmpty);
      expect(frame.dartCandidates, hasLength(1));
    });

    test('duplicate cal detections resolve to the highest confidence', () {
      final frame = buildDetectionFrame([
        det(1, 0.40, 0.20, 0.6),
        det(1, 0.50, 0.20, 0.95), // higher conf → wins
        det(2, 0.5, 0.8, 0.9),
        det(3, 0.2, 0.5, 0.9),
        det(4, 0.8, 0.5, 0.9),
      ]);
      expect(frame.calPoints.first, (x: 0.50, y: 0.20));
    });

    test('minConfidence filters weak darts and cals', () {
      final frame = buildDetectionFrame([
        det(1, 0.5, 0.2, 0.9),
        det(2, 0.5, 0.8, 0.9),
        det(3, 0.2, 0.5, 0.9),
        det(4, 0.8, 0.5, 0.9),
        det(0, 0.5, 0.5, 0.10), // below threshold → dropped
        det(0, 0.6, 0.6, 0.40),
      ], minConfidence: 0.25);
      expect(frame.dartCandidates, hasLength(1));
      expect(frame.dartCandidates.single, (x: 0.6, y: 0.6));
    });
  });
}
