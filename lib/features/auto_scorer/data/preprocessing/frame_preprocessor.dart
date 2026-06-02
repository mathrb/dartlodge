import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/preprocessing/square_crop.dart';
import 'package:image/image.dart' as img;

/// Preprocesses a camera frame to the model's input exactly as the probe's
/// training pipeline did (#377 §2 — the single most important correctness
/// item): center-crop the longer axis to a square, resize to 800×800 with
/// area resampling (the INTER_AREA equivalent), and **no EXIF rotation**.
///
/// Lives in `data/` because it depends on the `image` codec package; the
/// exact-match crop geometry is the pure [SquareCrop] from `domain/`.
class FramePreprocessor {
  static const int targetSize = 800;

  const FramePreprocessor();

  /// Center-crop + resize an already-decoded image to 800×800.
  img.Image preprocess(img.Image source) {
    final crop = SquareCrop.center(source.width, source.height);
    final square = img.copyCrop(
      source,
      x: crop.x0,
      y: crop.y0,
      width: crop.size,
      height: crop.size,
    );
    return img.copyResize(
      square,
      width: targetSize,
      height: targetSize,
      // INTER_AREA equivalent for the downscale the camera frame always needs.
      interpolation: img.Interpolation.average,
    );
  }

  /// Decode raw [bytes], preprocess, and re-encode as PNG for the detector.
  ///
  /// `decodeImage` does **not** bake EXIF orientation (we never call
  /// `bakeOrientation`), matching the probe's `cv2.imread`, which ignores EXIF.
  /// Returns null when the bytes can't be decoded.
  Uint8List? preprocessEncoded(Uint8List bytes) {
    // decodeImage can throw (not just return null) on malformed input; a corrupt
    // frame must degrade to "no detection", never crash the capture loop.
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
    if (decoded == null) return null;
    return img.encodePng(preprocess(decoded));
  }
}
