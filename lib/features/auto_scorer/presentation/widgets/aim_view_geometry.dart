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
///
/// Geometry: an `AspectRatio(previewAspect)` laid out contained inside a screen
/// of aspect [screenAspect] fills the screen's *shorter* relative axis; to also
/// cover the longer one it must grow by `max(previewAspect/screenAspect,
/// screenAspect/previewAspect)` — the aspect ratio of the two, NOT their product.
double coverScale(double screenAspect, double previewAspect) {
  if (!screenAspect.isFinite ||
      !previewAspect.isFinite ||
      screenAspect <= 0 ||
      previewAspect <= 0) {
    return 1.0;
  }
  final ratio = previewAspect / screenAspect;
  return ratio < 1 ? 1 / ratio : ratio;
}
