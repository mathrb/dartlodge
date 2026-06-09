/// Web-guarded entry for the "Square crop → predict" lab experiment. The real
/// screen (`_io`) uses the mobile-only `camera` plugin + the YOLO detector, so
/// web resolves to the no-op stub.
export 'square_crop_experiment_stub.dart'
    if (dart.library.io) 'square_crop_experiment_io.dart';
