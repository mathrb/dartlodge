import 'package:dart_lodge/features/auto_scorer/presentation/providers/camera_zoom_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to 1.0 when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(autoScorerCameraZoomProvider.future),
        kDefaultCameraZoom);
  });

  test('reads a stored zoom level', () async {
    SharedPreferences.setMockInitialValues({'auto_scorer_camera_zoom': 2.5});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(autoScorerCameraZoomProvider.future), 2.5);
  });

  test('set persists and updates state', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(autoScorerCameraZoomProvider.future);
    await container.read(autoScorerCameraZoomProvider.notifier).set(3.0);
    expect(container.read(autoScorerCameraZoomProvider).value, 3.0);

    // A fresh container reads back the persisted value.
    final reborn = ProviderContainer();
    addTearDown(reborn.dispose);
    expect(await reborn.read(autoScorerCameraZoomProvider.future), 3.0);
  });
}
