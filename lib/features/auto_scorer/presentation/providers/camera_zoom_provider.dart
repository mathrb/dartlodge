import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_zoom_provider.g.dart';

const _kCameraZoomKey = 'auto_scorer_camera_zoom';

/// Default zoom level — `1.0` is "no zoom" on every device that reports a zoom
/// range (the camera plugin's minimum). The aim view clamps the persisted value
/// to the device's `[minZoom, maxZoom]` before applying it, so a value saved on
/// one device degrades gracefully on another.
const double kDefaultCameraZoom = 1.0;

/// Persisted camera zoom for the auto-scorer aim preview (#393 setup flow). A
/// higher zoom enlarges the board in the letterboxed model input → finer cal /
/// tip localisation. Persisted so the user doesn't re-zoom every game; the aim
/// view writes back here via [set] on slider release. Mirrors
/// [AutoScorerCalConfidence].
@Riverpod(keepAlive: true)
class AutoScorerCameraZoom extends _$AutoScorerCameraZoom {
  @override
  Future<double> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getDouble(_kCameraZoomKey) ?? kDefaultCameraZoom;
  }

  Future<void> set(double value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble(_kCameraZoomKey, value);
    state = AsyncData(value);
  }
}
