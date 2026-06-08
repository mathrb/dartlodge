import 'dart:typed_data';

/// Produces the model's input frame from a raw camera frame (#377 §2): a
/// letterboxed, resized, re-encoded square image matching the training
/// pipeline. This is the **domain contract** so orchestration (e.g.
/// `AutoScorerSession`) depends on it without importing the `image` codec; the
/// codec-bound implementation lives in `data/` (`ImageFramePreprocessor`).
abstract interface class FramePreprocessor {
  /// Decode raw [bytes], optionally rotate by [quarterTurns] × 90° clockwise so
  /// the board is presented upright to the model (the model needs an upright
  /// board, not a specific device orientation), letterbox to a square, resize to
  /// the model input, and re-encode. Returns null when the bytes can't be decoded
  /// (a corrupt frame must degrade to "no detection", never crash the capture
  /// loop).
  Uint8List? preprocessEncoded(Uint8List bytes, {int quarterTurns = 0});

  /// Pixel dimensions of an encoded frame, or null when the bytes can't be
  /// decoded. Used by the capture path to stamp the sidecar's `frame_width` /
  /// `frame_height` so the probe knows the stored image's source dims. The
  /// codec lives in `data/`, so the orchestrator reads dims through this
  /// contract rather than importing the `image` package.
  ({int width, int height})? dimensionsOf(Uint8List bytes);
}
