import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_result_parser.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// On-device [DartDetector] backed by the first-party `ultralytics_yolo` plugin
/// (#378). Mobile/desktop only — conditionally imported in place of the web
/// stub so `flutter run -d chrome` never pulls in the plugin.
///
/// Inference runs on the **raw** camera frame: the plugin letterboxes it to the
/// model input natively. On-device profiling (#377 §3) showed our previous
/// pure-Dart 800×800 decode/resize cost ~1.1s per frame (det 1253ms → 155ms
/// once dropped), so it was removed — the phone/model were never the bottleneck,
/// our preprocessing was. Detections come back normalised to the raw frame; the
/// pure [parseYoloDetections] + [buildDetectionFrame] map them for the tracker.
class UltralyticsDartDetector implements DartDetector {
  UltralyticsDartDetector({
    String modelPath = kAutoScorerModelAsset,
    double minConfidence = 0.25,
  })  : _yolo = YOLO(modelPath: modelPath, task: YOLOTask.detect),
        _minConfidence = minConfidence;

  final YOLO _yolo;
  final double _minConfidence;

  @override
  bool get isSupported => true;

  @override
  Future<bool> load() => _yolo.loadModel();

  @override
  Future<DetectionFrame> detect(Uint8List frameBytes) async {
    final result = await _yolo.predict(frameBytes);
    return buildDetectionFrame(
      parseYoloDetections(result),
      minConfidence: _minConfidence,
    );
  }

  @override
  Future<void> dispose() => _yolo.dispose();
}

Future<DartDetector> openDartDetector() async => UltralyticsDartDetector();
