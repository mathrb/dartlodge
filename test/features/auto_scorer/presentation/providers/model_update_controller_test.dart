import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/model_update_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake service: `checkAndStage` "stages" by flipping to updateReady and making
/// `resolve` return a staged model. Tracks whether it was invoked.
class _FakeService implements ModelUpdateService {
  _FakeService({this.supported = true, this.fails = false});
  final bool supported;

  /// Set by [quarantine], the way the io service does when a staged model is
  /// rejected at native load (#785).
  bool rejected = false;

  /// When true, `checkAndStage` completes without staging and reports a failed
  /// check, the way the io service does on a 404 or a hash mismatch (#782).
  final bool fails;
  bool staged = false;
  bool failed = false;
  int checkCalls = 0;

  @override
  bool get isSupported => supported;

  @override
  ModelUpdateStatus get status {
    if (rejected) return ModelUpdateStatus.updateRejected;
    if (failed) return ModelUpdateStatus.checkFailed;
    return staged ? ModelUpdateStatus.updateReady : ModelUpdateStatus.upToDate;
  }

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
    if (!supported) return;
    if (fails) {
      failed = true;
    } else {
      staged = true;
    }
  }

  @override
  Future<void> quarantine(String version, {bool remember = true}) async {
    staged = false;
    if (remember) rejected = true;
  }
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

  test('checkNow surfaces a failed check instead of reporting up to date',
      () async {
    final service = _FakeService(fails: true);
    final container = containerFor(service);
    addTearDown(container.dispose);

    expect(await container.read(modelUpdateControllerProvider.future),
        ModelUpdateStatus.upToDate);

    await container.read(modelUpdateControllerProvider.notifier).checkNow();

    expect(service.checkCalls, 1);
    expect(container.read(modelUpdateControllerProvider).value,
        ModelUpdateStatus.checkFailed);
    // The active model is untouched by a failed check.
    expect((await container.read(resolvedModelProvider.future)).origin,
        ModelOrigin.bundled);
  });

  // The board overlay quarantines a model that would not load, then
  // invalidates this controller so the row stops promising the update it had
  // announced (#785).
  test('a quarantine surfaces as update-rejected after invalidation', () async {
    final service = _FakeService();
    final container = containerFor(service);
    addTearDown(container.dispose);

    await container.read(modelUpdateControllerProvider.notifier).checkNow();
    expect(container.read(modelUpdateControllerProvider).value,
        ModelUpdateStatus.updateReady);

    await service.quarantine('dart_round26_withcal');
    container.invalidate(modelUpdateControllerProvider);

    expect(await container.read(modelUpdateControllerProvider.future),
        ModelUpdateStatus.updateRejected);
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
