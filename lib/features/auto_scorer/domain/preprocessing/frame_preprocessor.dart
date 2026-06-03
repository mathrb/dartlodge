import 'dart:typed_data';

/// Produces the model's input frame from a raw camera frame (#377 §2): a
/// center-cropped, resized, re-encoded square image matching the training
/// pipeline. This is the **domain contract** so orchestration (e.g.
/// `AutoScorerSession`) depends on it without importing the `image` codec; the
/// codec-bound implementation lives in `data/` (`ImageFramePreprocessor`).
abstract interface class FramePreprocessor {
  /// Decode raw [bytes], center-crop to a square, resize to the model input,
  /// and re-encode. Returns null when the bytes can't be decoded (a corrupt
  /// frame must degrade to "no detection", never crash the capture loop).
  Uint8List? preprocessEncoded(Uint8List bytes);
}
