/// Web-guarded seam for the YOLOView-backed auto-scorer views. The real
/// implementation (`_io`) imports the mobile-only `ultralytics_yolo` plugin, so
/// web resolves to a no-op stub — keeping `flutter run -d chrome` building. The
/// web-safe shell (`auto_scorer_board_overlay.dart`) imports ONLY this file, so
/// it never pulls the plugin onto the web build path (main.dart imports the
/// shell directly). Same pattern as `dart_detector_provider.dart`.
export 'auto_scorer_yolo_view_stub.dart'
    if (dart.library.io) 'auto_scorer_yolo_view_io.dart';
