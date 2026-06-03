import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';

/// Web stub for [DartDetector] (#377 §8): the auto-scorer is invisible on web,
/// so this no-op keeps `flutter run -d chrome` building without the
/// `ultralytics_yolo` plugin. [isSupported] is false; callers must not start
/// detection on web.
class _UnsupportedDartDetector implements DartDetector {
  const _UnsupportedDartDetector();

  @override
  bool get isSupported => false;

  @override
  Future<bool> load() async => false;

  @override
  Future<DetectionFrame> detect(Uint8List frameBytes,
          {bool skipPreprocess = false}) async =>
      const DetectionFrame(calPoints: [], dartCandidates: []);

  @override
  Future<void> dispose() async {}
}

Future<DartDetector> openDartDetector() async => const _UnsupportedDartDetector();
