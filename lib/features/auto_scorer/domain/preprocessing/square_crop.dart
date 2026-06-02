/// Center-crop-to-square geometry — the exact integer math from the probe's
/// `preprocess_batch.center_crop_resize` (#378 §2):
///
/// ```python
/// s = min(h, w); y0 = (h - s) // 2; x0 = (w - s) // 2
/// ```
///
/// Preprocessing parity is the single most important correctness item: the
/// frame fed to the model must be cropped+resized exactly as the training data
/// was. This pure geometry is the part that must match byte-for-byte; the
/// resample step lives in the data layer (`FramePreprocessor`).
class SquareCrop {
  final int x0;
  final int y0;
  final int size;

  const SquareCrop({required this.x0, required this.y0, required this.size});

  /// Center crop of the longer axis for a [width]×[height] image.
  factory SquareCrop.center(int width, int height) {
    final s = width < height ? width : height;
    return SquareCrop(x0: (width - s) ~/ 2, y0: (height - s) ~/ 2, size: s);
  }

  @override
  String toString() => 'SquareCrop(x0:$x0, y0:$y0, size:$size)';
}
