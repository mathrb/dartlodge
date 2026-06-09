/// Web-guarded entry for the "YOLOView + zoom" lab experiment. The real screen
/// (`_io`) imports the mobile-only `ultralytics_yolo` plugin, so web resolves to
/// the no-op stub — keeping `flutter run -d chrome` building (same conditional
/// pattern as `dart_detector_provider`).
export 'yolo_zoom_experiment_stub.dart'
    if (dart.library.io) 'yolo_zoom_experiment_io.dart';
