import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/preprocessing/frame_preprocessor.dart';
import 'package:image/image.dart' as img;

/// `image`-codec implementation of [FramePreprocessor] that **letterboxes** a
/// camera frame into the model's [targetSize]×[targetSize] input (#377 §2):
/// scale the whole frame to fit (preserving aspect ratio) and pad the remainder
/// with neutral grey — nothing is cropped.
///
/// Switched from a center-crop (which clipped the board's outer calibration
/// points when the board filled the frame, so the model never saw them and the
/// tracker kept reporting "needs calibration"). Letterbox keeps every cal point
/// in the model input. Grey **114** matches the YOLO/ultralytics letterbox
/// convention and the plugin's own native resize, so the input distribution is
/// consistent across our preprocess and the "skip preprocessing" path. (The
/// probe trained at `imgsz 800`; training should letterbox to match — #393.)
/// Lives in `data/` for the `image` codec dependency.
class ImageFramePreprocessor implements FramePreprocessor {
  static const int targetSize = 800;

  /// Neutral grey padding (ultralytics letterbox default).
  static const int _pad = 114;

  const ImageFramePreprocessor();

  /// Letterbox an already-decoded image into a [targetSize]×[targetSize] square.
  img.Image preprocess(img.Image source) {
    final scale =
        math.min(targetSize / source.width, targetSize / source.height);
    final scaledW = math.max(1, (source.width * scale).round());
    final scaledH = math.max(1, (source.height * scale).round());
    final scaled = img.copyResize(
      source,
      width: scaledW,
      height: scaledH,
      // INTER_AREA-equivalent for the downscale a camera frame always needs.
      interpolation: img.Interpolation.average,
    );
    final canvas = img.Image(width: targetSize, height: targetSize);
    img.fill(canvas, color: img.ColorRgb8(_pad, _pad, _pad));
    img.compositeImage(
      canvas,
      scaled,
      dstX: (targetSize - scaledW) ~/ 2,
      dstY: (targetSize - scaledH) ~/ 2,
    );
    return canvas;
  }

  /// Decode raw [bytes], preprocess, and re-encode as PNG for the detector.
  ///
  /// `decodeImage` does **not** bake EXIF orientation (we never call
  /// `bakeOrientation`), matching the probe's `cv2.imread`, which ignores EXIF.
  /// Returns null when the bytes can't be decoded.
  @override
  Uint8List? preprocessEncoded(Uint8List bytes, {int quarterTurns = 0}) {
    // decodeImage can throw (not just return null) on malformed input; a corrupt
    // frame must degrade to "no detection", never crash the capture loop.
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
    if (decoded == null) return null;
    // Rotate (clockwise) so the board is upright before letterboxing. The model
    // is trained on upright boards; a sideways board (portrait-held phone served
    // the raw landscape buffer) detects ~nothing. quarterTurns is auto-detected
    // upstream from which rotation actually yields the cal points.
    final norm = ((quarterTurns % 4) + 4) % 4;
    if (norm != 0) decoded = img.copyRotate(decoded, angle: norm * 90);
    return img.encodePng(preprocess(decoded));
  }

  @override
  ({int width, int height})? dimensionsOf(Uint8List bytes) {
    // Decode can throw on malformed input; degrade to null like
    // [preprocessEncoded] rather than crash the (rare) capture path.
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
    if (decoded == null) return null;
    return (width: decoded.width, height: decoded.height);
  }
}
