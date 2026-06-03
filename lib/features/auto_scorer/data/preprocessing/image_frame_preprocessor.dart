import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/preprocessing/frame_preprocessor.dart';
import 'package:dart_lodge/features/auto_scorer/domain/preprocessing/square_crop.dart';
import 'package:image/image.dart' as img;

/// `image`-codec implementation of [FramePreprocessor], matching the probe's
/// training pipeline (#377 §2 — the single most important correctness item):
/// center-crop the longer axis to a square, resize to 800×800 with area
/// resampling, and **no EXIF rotation**.
///
/// Parity scope: the **crop geometry** is byte-for-byte exact (pure [SquareCrop]
/// from `domain/` — the same integer math as the probe). The **resize** uses
/// the `image` package's area interpolation, which approximates — but is not
/// bit-identical to — OpenCV's `cv2.INTER_AREA`; the two differ by sub-DN
/// rounding. Functional equivalence is validated by the on-device recall gate
/// (§2), not pixel equality. Lives in `data/` for the `image` codec dependency.
class ImageFramePreprocessor implements FramePreprocessor {
  static const int targetSize = 800;

  const ImageFramePreprocessor();

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
  @override
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
