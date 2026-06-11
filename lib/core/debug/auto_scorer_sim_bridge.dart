/// Web-only debug bridge that lets Playwright inject auto-scorer dart events
/// through the [DartInputSink] seam, so the camera-first layouts can be driven
/// in E2E without a real camera (the camera + YOLO are Android-native only).
///
/// Gated by `--dart-define=AUTOSCORER_SIM=true` at the composition root
/// (`main.dart`) — absent from the public build. Web resolves to the real
/// implementation; every other platform gets a no-op pass-through, following the
/// same conditional-import idiom as `auto_scorer_yolo_view.dart` and the drift
/// factory.
library;

export 'auto_scorer_sim_bridge_stub.dart'
    if (dart.library.html) 'auto_scorer_sim_bridge_web.dart';
