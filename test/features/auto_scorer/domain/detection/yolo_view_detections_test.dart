import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_view_detections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rawDetectionsFromClassed', () {
    test('maps known classes by name and keeps box-centre + confidence', () {
      final raw = rawDetectionsFromClassed(const [
        (className: 'cal1', confidence: 0.9, cx: 0.1, cy: 0.2),
        (className: 'dart', confidence: 0.5, cx: 0.7, cy: 0.8),
      ]);

      expect(raw, hasLength(2));
      expect(raw[0].classIndex, 1); // cal1
      expect(raw[0].x, 0.1);
      expect(raw[0].y, 0.2);
      expect(raw[0].conf, 0.9);
      expect(raw[1].classIndex, 0); // dart
      expect(raw[1].conf, 0.5);
    });

    test('drops classes not in the model map', () {
      final raw = rawDetectionsFromClassed(const [
        (className: 'person', confidence: 0.99, cx: 0.5, cy: 0.5),
        (className: 'cal3', confidence: 0.4, cx: 0.3, cy: 0.6),
      ]);

      expect(raw, hasLength(1));
      expect(raw.single.classIndex, 3); // cal3
    });

    test('feeds buildDetectionFrame: four cals → calibrated, darts counted', () {
      final frame = buildDetectionFrame(
        rawDetectionsFromClassed(const [
          (className: 'cal1', confidence: 0.9, cx: 0.1, cy: 0.1),
          (className: 'cal2', confidence: 0.9, cx: 0.9, cy: 0.1),
          (className: 'cal3', confidence: 0.9, cx: 0.1, cy: 0.9),
          (className: 'cal4', confidence: 0.9, cx: 0.9, cy: 0.9),
          (className: 'dart', confidence: 0.8, cx: 0.5, cy: 0.5),
        ]),
        calMinConfidence: 0.25,
        dartMinConfidence: 0.25,
      );

      expect(frame.hasCalibration, isTrue);
      expect(frame.calPoints, hasLength(4));
      expect(frame.dartCandidates, hasLength(1));
    });

    test('a sub-threshold cal drops calibration but keeps the diagnostic conf',
        () {
      final frame = buildDetectionFrame(
        rawDetectionsFromClassed(const [
          (className: 'cal1', confidence: 0.9, cx: 0.1, cy: 0.1),
          (className: 'cal2', confidence: 0.9, cx: 0.9, cy: 0.1),
          (className: 'cal3', confidence: 0.9, cx: 0.1, cy: 0.9),
          (className: 'cal4', confidence: 0.10, cx: 0.9, cy: 0.9),
        ]),
        calMinConfidence: 0.25,
        dartMinConfidence: 0.25,
      );

      expect(frame.hasCalibration, isFalse);
      expect(frame.calConfidences[3], 0.10); // still surfaced for the readout
    });
  });
}
