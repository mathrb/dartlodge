import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Web-guarded: the ultralytics_yolo-backed detector is swapped for a no-op stub
// on web so `flutter run -d chrome` builds without the plugin (#377 §8).
import 'package:dart_lodge/features/auto_scorer/data/detection/yolo_detector_stub.dart'
    if (dart.library.io) 'package:dart_lodge/features/auto_scorer/data/detection/yolo_detector_io.dart';

part 'dart_detector_provider.g.dart';

/// The on-device dart detector (ultralytics_yolo on mobile, no-op on web).
/// Consumers gate on [DartDetector.isSupported] before starting detection.
///
/// The diagnostics "skip preprocessing" A/B (#377 §3) is a per-call argument to
/// [DartDetector.detect] (threaded from the session), NOT a property of the
/// detector — so toggling it never rebuilds this provider or churns the native
/// model; it takes effect on the next frame.
@Riverpod(keepAlive: true)
Future<DartDetector> dartDetector(Ref ref) => openDartDetector();
