import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/data/preprocessing/image_frame_preprocessor.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_result_parser.dart';
import 'package:dart_lodge/features/auto_scorer/domain/preprocessing/frame_preprocessor.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

/// On-device [DartDetector] backed by the first-party `ultralytics_yolo` plugin
/// (#378). Mobile/desktop only — conditionally imported in place of the web
/// stub so `flutter run -d chrome` never pulls in the plugin.
///
/// Each frame is letterboxed to 800×800 (training parity, #377 §2) before
/// inference; the plugin's detections are mapped to the tracker's
/// [DetectionFrame] via the pure [parseYoloDetections] + [buildDetectionFrame].
class UltralyticsDartDetector implements DartDetector {
  UltralyticsDartDetector({
    String modelPath = kAutoScorerModelAsset,
    FramePreprocessor preprocessor = const ImageFramePreprocessor(),
  })  : _yolo = YOLO(modelPath: modelPath, task: YOLOTask.detect),
        _preprocessor = preprocessor;

  final YOLO _yolo;
  final FramePreprocessor _preprocessor;

  /// Lower bound on the confidence we ask the plugin to return, so a cal point
  /// sitting just below the user's threshold is still surfaced to the HUD for
  /// tuning. Per-class acceptance is applied in [buildDetectionFrame].
  ///
  /// Safe only because the standard NMS detect path keeps the top
  /// `numItemsThreshold` (30) detections **by confidence**, so a 0.05 floor's
  /// noise can't crowd out the high-confidence cals. A future NMS-free /
  /// end-to-end model export would cap in emission order instead and could drop
  /// a real cal — raise this floor (or keep NMS in the export) if that changes.
  static const double _hudFloor = 0.05;

  @override
  bool get isSupported => true;

  @override
  Future<bool> load() => _yolo.loadModel();

  @override
  Future<DetectionFrame> detect(
    Uint8List frameBytes, {
    bool skipPreprocess = false,
    double calConfidence = 0.25,
    double dartConfidence = 0.25,
  }) async {
    final Uint8List input;
    if (skipPreprocess) {
      // Diagnostics A/B (#377 §3): hand the raw bytes to the plugin, which
      // letterboxes to the model input itself, skipping our 800×800 step.
      // Detections then map to the raw frame — coordinate-consistent for the
      // tracker (cals + tips share that frame) but NOT aligned with a stored
      // 800×800 capture, so the caller suppresses capture while skipping.
      input = frameBytes;
    } else {
      final square = _preprocessor.preprocessEncoded(frameBytes);
      if (square == null) {
        return const DetectionFrame(calPoints: [], dartCandidates: []);
      }
      input = square;
    }
    // Run NMS at a floor below both thresholds so sub-threshold cals still come
    // back (the HUD shows them); the per-class thresholds gate actual detection.
    final floor =
        math.min(_hudFloor, math.min(calConfidence, dartConfidence));
    final result = await _yolo.predict(input, confidenceThreshold: floor);
    return buildDetectionFrame(
      parseYoloDetections(result),
      calMinConfidence: calConfidence,
      dartMinConfidence: dartConfidence,
    );
  }

  @override
  Future<void> dispose() => _yolo.dispose();
}

Future<DartDetector> openDartDetector() async => UltralyticsDartDetector();
