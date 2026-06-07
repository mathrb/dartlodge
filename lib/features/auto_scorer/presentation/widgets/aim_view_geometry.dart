/// Scale factor that makes a camera preview of aspect [previewAspect] **cover**
/// (BoxFit.cover) a screen of aspect [screenAspect], when the preview is first
/// laid out contained (via `AspectRatio`) and then scaled at paint time with
/// `Transform.scale`. This is the canonical Flutter full-screen-camera formula.
///
/// Both aspects are width / height. The returned scale is always `>= 1` (we only
/// ever enlarge to fill, never shrink). Pure Dart — no Flutter import — so the
/// caller passes plain doubles (`MediaQuery.size.aspectRatio`,
/// `CameraController.value.aspectRatio`) and this stays unit-testable.
///
/// Returns `1.0` for non-finite or non-positive inputs (degenerate layout before
/// the camera/preview sizes are known), so the preview just shows contained
/// rather than scaling by NaN/Infinity.
double coverScale(double screenAspect, double previewAspect) {
  if (!screenAspect.isFinite ||
      !previewAspect.isFinite ||
      screenAspect <= 0 ||
      previewAspect <= 0) {
    return 1.0;
  }
  final scale = screenAspect * previewAspect;
  return scale < 1 ? 1 / scale : scale;
}
