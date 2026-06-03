import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Web-guarded: the ultralytics_yolo-backed detector is swapped for a no-op stub
// on web so `flutter run -d chrome` builds without the plugin (#377 §8).
import 'package:dart_lodge/features/auto_scorer/data/detection/yolo_detector_stub.dart'
    if (dart.library.io) 'package:dart_lodge/features/auto_scorer/data/detection/yolo_detector_io.dart';

part 'dart_detector_provider.g.dart';

/// The on-device dart detector (ultralytics_yolo on mobile, no-op on web).
/// Consumers gate on [DartDetector.isSupported] before starting detection.
/// Inference runs on the raw camera frame (the plugin letterboxes natively),
/// so there is no per-frame preprocessing to configure here (#377 §3).
@Riverpod(keepAlive: true)
Future<DartDetector> dartDetector(Ref ref) => openDartDetector();
