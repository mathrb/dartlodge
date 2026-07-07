import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/model_update_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake service: `checkAndStage` "stages" by flipping to updateReady and making
/// `resolve` return a staged model. Tracks whether it was invoked.
class _FakeService implements ModelUpdateService {
  _FakeService({this.supported = true});
  final bool supported;
  bool staged = false;
  int checkCalls = 0;

  @override
  bool get isSupported => supported;

  @override
  ModelUpdateStatus get status =>
      staged ? ModelUpdateStatus.updateReady : ModelUpdateStatus.upToDate;

  @override
  Future<ResolvedModel> resolve() async => staged
      ? const ResolvedModel(
          path: '/staged/model.tflite',
          version: 'dart_round26_withcal',
          origin: ModelOrigin.staged,
        )
      : const ResolvedModel(
          path: kAutoScorerModelAsset,
          version: kAutoScorerModelVersion,
          origin: ModelOrigin.bundled,
        );

  @override
  Future<void> checkAndStage() async {
    checkCalls++;
    if (supported) staged = true;
  }

  @override
  Future<void> quarantine(String version) async {}
}

void main() {
  ProviderContainer containerFor(_FakeService service) {
    return ProviderContainer(overrides: [
      modelUpdateServiceProvider.overrideWith((ref) async => service),
    ]);
  }

  test('checkNow stages, updates status, and refreshes the resolved model',
      () async {
    final service = _FakeService();
    final container = containerFor(service);
    addTearDown(container.dispose);

    // Initially bundled + up to date.
    expect((await container.read(resolvedModelProvider.future)).origin,
        ModelOrigin.bundled);
    expect(await container.read(modelUpdateControllerProvider.future),
        ModelUpdateStatus.upToDate);

    await container.read(modelUpdateControllerProvider.notifier).checkNow();

    expect(service.checkCalls, 1);
    expect(container.read(modelUpdateControllerProvider).value,
        ModelUpdateStatus.updateReady);
    // resolvedModel was invalidated → now resolves to the staged model.
    expect((await container.read(resolvedModelProvider.future)).origin,
        ModelOrigin.staged);
  });

  test('checkNow is a no-op when the service is unsupported', () async {
    final service = _FakeService(supported: false);
    final container = containerFor(service);
    addTearDown(container.dispose);

    await container.read(modelUpdateControllerProvider.future);
    await container.read(modelUpdateControllerProvider.notifier).checkNow();

    expect(service.checkCalls, 0);
    expect(container.read(modelUpdateControllerProvider).value,
        ModelUpdateStatus.upToDate);
  });
}
