import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';

/// Canonical bundled-model asset path (#377 §2). The TFLite/CoreML model is
/// produced from the probe's `.pt` by `deep-darts-probe`'s
/// `dart-train/export_mobile.py` and bundled here (see
/// `docs/AUTO_SCORER_ENABLEMENT.md`).
const String kAutoScorerModelAsset = 'assets/models/dart_auto_scorer.tflite';

/// Stem of the bundled model's source `.pt`, recorded as `model_version` on
/// every training capture so the probe can attribute each sample to the model
/// that produced its predictions. Matches the probe's `pre_annotate` stem
/// convention — bump this in lock-step with [kAutoScorerModelAsset].
const String kAutoScorerModelVersion = 'dart_round25_withcal';

/// The over-the-air (#715) model **compatibility contract** the app understands.
/// A downloaded model is accepted only when its manifest declares the exact same
/// contract number (strict `==`), so an app can never load a model whose I/O or
/// scoring semantics it wasn't built for.
///
/// **Bump this whenever any of these change** (they alter how the app feeds or
/// interprets the model, so an old app must NOT use a new-contract model):
///  - the class set / count (`{0:dart, 1:cal1..4}`),
///  - the input size (currently 800×800),
///  - the preprocessing (letterbox scale-to-fit + grey-114 padding),
///  - the confidence/IoU threshold semantics.
///
/// A bump auto-invalidates any already-staged model (its persisted contract no
/// longer matches → the resolver falls back to the bundled asset and the stale
/// file is quarantined), and forces a real Play release for those users.
const int kAutoScorerModelContract = 1;

/// Runs the on-device detector and returns a [DetectionFrame] (cal points +
/// dart candidates) for the tracker. Implementations preprocess the raw frame
/// to 800×800 exactly as the training data (#377 §2) before inference.
///
/// Platform-backed (ultralytics_yolo) on mobile; stubbed on web behind a
/// `kIsWeb`/conditional-import guard so `flutter run -d chrome` still builds.
abstract class DartDetector {
  /// False on the web stub — callers must not start detection when so.
  bool get isSupported;

  /// Load the model. Returns true on success.
  Future<bool> load();

  /// Detect from a raw camera frame (any size, encoded image bytes).
  ///
  /// [skipPreprocess] is the default serve path (raw-capture brief; also a
  /// diagnostics A/B, #377 §3): when true the implementation passes the raw
  /// bytes to the model instead of our 800×800 preprocess. Detections then map
  /// to the raw frame, so the session stores the raw frame (not the 800×800
  /// image) with raw-space coords when capturing under this flag.
  ///
  /// [calConfidence] / [dartConfidence] are the per-class acceptance thresholds
  /// (user-configurable): a cal point / dart counts only at or above its value.
  /// Inference still runs at a low floor so the HUD can show sub-threshold cal
  /// confidences for tuning.
  Future<DetectionFrame> detect(
    Uint8List frameBytes, {
    bool skipPreprocess = false,
    double calConfidence = 0.25,
    double dartConfidence = 0.25,
  });

  /// Release native resources.
  Future<void> dispose();
}
