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
    bool skipPreprocess = false,
  })  : _yolo = YOLO(modelPath: modelPath, task: YOLOTask.detect),
        _preprocessor = preprocessor,
        _minConfidence = minConfidence,
        _skipPreprocess = skipPreprocess;

  final YOLO _yolo;
  final FramePreprocessor _preprocessor;
  final double _minConfidence;

  /// Diagnostics A/B (#377 §3 lag investigation): when set, pass the raw camera
  /// bytes straight to the plugin (which letterboxes to the model input itself)
  /// instead of our pure-Dart 800×800 preprocess. Flipping this and watching the
  /// `detect` timing in the HUD isolates our preprocess cost from native
  /// inference. NOTE: detections then map to the *raw* frame, so captured
  /// sidecar coords won't align with the stored 800×800 image — for perf
  /// measurement only; keep "Collect training data" off while comparing.
  final bool _skipPreprocess;

  @override
  bool get isSupported => true;

  @override
  Future<bool> load() => _yolo.loadModel();

  @override
  Future<DetectionFrame> detect(Uint8List frameBytes) async {
    final Uint8List input;
    if (_skipPreprocess) {
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

Future<DartDetector> openDartDetector({bool skipPreprocess = false}) async =>
    UltralyticsDartDetector(skipPreprocess: skipPreprocess);
