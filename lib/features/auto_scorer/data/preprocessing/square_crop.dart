import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Center-crop the largest centred square out of an [src] image — geometry only,
/// no scaling, so nothing is distorted (a round board stays round). Used by the
/// Lab's "square crop" detection-quality probe.
img.Image squareCrop(img.Image src) {
  final side = math.min(src.width, src.height);
  final x = (src.width - side) ~/ 2;
  final y = (src.height - side) ~/ 2;
  return img.copyCrop(src, x: x, y: y, width: side, height: side);
}

/// Decode [bytes], center-square-crop, and re-encode as PNG. Returns null if the
/// bytes can't be decoded (degrade to "no detection", never crash the loop).
///
/// Hand the result to `DartDetector.detect(..., skipPreprocess: true)` so the
/// plugin's own letterbox is a no-op pad on the already-square image — the model
/// then sees the centred square crop instead of the full landscape frame, and
/// detections come back normalised to the crop. Decode does NOT bake EXIF
/// orientation, matching the rest of the pipeline.
Uint8List? squareCropEncoded(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;
  return img.encodePng(squareCrop(decoded));
}
