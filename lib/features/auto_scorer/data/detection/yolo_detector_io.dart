import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/data/preprocessing/frame_preprocessor.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_result_parser.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// On-device [DartDetector] backed by the first-party `ultralytics_yolo` plugin
/// (#378). Mobile/desktop only — conditionally imported in place of the web
/// stub so `flutter run -d chrome` never pulls in the plugin.
///
/// Each frame is preprocessed to 800×800 (training parity, #377 §2) before
/// inference; the plugin's detections are mapped to the tracker's
/// [DetectionFrame] via the pure [parseYoloDetections] + [buildDetectionFrame].
class UltralyticsDartDetector implements DartDetector {
  UltralyticsDartDetector({
    String modelPath = kAutoScorerModelAsset,
    FramePreprocessor preprocessor = const FramePreprocessor(),
    double minConfidence = 0.25,
  })  : _yolo = YOLO(modelPath: modelPath, task: YOLOTask.detect),
        _preprocessor = preprocessor,
        _minConfidence = minConfidence;

  final YOLO _yolo;
  final FramePreprocessor _preprocessor;
  final double _minConfidence;

  @override
  bool get isSupported => true;

  @override
  Future<bool> load() => _yolo.loadModel();

  @override
  Future<DetectionFrame> detect(Uint8List frameBytes,
      {bool skipPreprocess = false}) async {
    final Uint8List input;
    if (skipPreprocess) {
      // Diagnostics A/B (#377 §3): hand the raw bytes to the plugin, which
      // letterboxes to the model input itself, skipping our pure-Dart 800×800
      // resize. Detections then map to the raw frame — coordinate-consistent
      // for the tracker (cals + tips share that frame) but NOT aligned with a
      // stored 800×800 capture, so the caller suppresses capture while skipping.
      input = frameBytes;
    } else {
      final square = _preprocessor.preprocessEncoded(frameBytes);
      if (square == null) {
        return const DetectionFrame(calPoints: [], dartCandidates: []);
      }
      input = square;
    }
    final result = await _yolo.predict(input);
    return buildDetectionFrame(
      parseYoloDetections(result),
      minConfidence: _minConfidence,
    );
  }

  @override
  Future<void> dispose() => _yolo.dispose();
}

Future<DartDetector> openDartDetector() async => UltralyticsDartDetector();
