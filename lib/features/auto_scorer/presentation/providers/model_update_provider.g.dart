// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The over-the-air model-update service (dart:io on mobile, no-op on web, #715).

@ProviderFor(modelUpdateService)
final modelUpdateServiceProvider = ModelUpdateServiceProvider._();

/// The over-the-air model-update service (dart:io on mobile, no-op on web, #715).

final class ModelUpdateServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModelUpdateService>,
          ModelUpdateService,
          FutureOr<ModelUpdateService>
        >
    with
        $FutureModifier<ModelUpdateService>,
        $FutureProvider<ModelUpdateService> {
  /// The over-the-air model-update service (dart:io on mobile, no-op on web, #715).
  ModelUpdateServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelUpdateServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelUpdateServiceHash();

  @$internal
  @override
  $FutureProviderElement<ModelUpdateService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ModelUpdateService> create(Ref ref) {
    return modelUpdateService(ref);
  }
}

String _$modelUpdateServiceHash() =>
    r'5ae52e50a906b1264eedc1bc129e3c3aec34d07a';

/// The effective model for the next session — a staged download if valid, else
/// the bundled asset. Resolved once and read as a snapshot at session start
/// (never live-watched into a running `YOLOView`, to avoid a mid-game reload).
/// Invalidate this after staging/quarantine so the next session picks it up.

@ProviderFor(resolvedModel)
final resolvedModelProvider = ResolvedModelProvider._();

/// The effective model for the next session — a staged download if valid, else
/// the bundled asset. Resolved once and read as a snapshot at session start
/// (never live-watched into a running `YOLOView`, to avoid a mid-game reload).
/// Invalidate this after staging/quarantine so the next session picks it up.

final class ResolvedModelProvider
    extends
        $FunctionalProvider<
          AsyncValue<ResolvedModel>,
          ResolvedModel,
          FutureOr<ResolvedModel>
        >
    with $FutureModifier<ResolvedModel>, $FutureProvider<ResolvedModel> {
  /// The effective model for the next session — a staged download if valid, else
  /// the bundled asset. Resolved once and read as a snapshot at session start
  /// (never live-watched into a running `YOLOView`, to avoid a mid-game reload).
  /// Invalidate this after staging/quarantine so the next session picks it up.
  ResolvedModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resolvedModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resolvedModelHash();

  @$internal
  @override
  $FutureProviderElement<ResolvedModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ResolvedModel> create(Ref ref) {
    return resolvedModel(ref);
  }
}

String _$resolvedModelHash() => r'7020cf1a6ec87d45d7742483a90336af55ce5027';

/// Drives + exposes the OTA lifecycle for the settings row and the launch host.
/// State is the current [ModelUpdateStatus]; [checkNow] runs a background check
/// (shared by the launch host and the "Check now" button) and refreshes
/// [resolvedModelProvider] so a newly staged model applies at the next session.

@ProviderFor(ModelUpdateController)
final modelUpdateControllerProvider = ModelUpdateControllerProvider._();

/// Drives + exposes the OTA lifecycle for the settings row and the launch host.
/// State is the current [ModelUpdateStatus]; [checkNow] runs a background check
/// (shared by the launch host and the "Check now" button) and refreshes
/// [resolvedModelProvider] so a newly staged model applies at the next session.
final class ModelUpdateControllerProvider
    extends $AsyncNotifierProvider<ModelUpdateController, ModelUpdateStatus> {
  /// Drives + exposes the OTA lifecycle for the settings row and the launch host.
  /// State is the current [ModelUpdateStatus]; [checkNow] runs a background check
  /// (shared by the launch host and the "Check now" button) and refreshes
  /// [resolvedModelProvider] so a newly staged model applies at the next session.
  ModelUpdateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelUpdateControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelUpdateControllerHash();

  @$internal
  @override
  ModelUpdateController create() => ModelUpdateController();
}

String _$modelUpdateControllerHash() =>
    r'98ed42e319e2d3e365364ae34c1f4e7546019350';

/// Drives + exposes the OTA lifecycle for the settings row and the launch host.
/// State is the current [ModelUpdateStatus]; [checkNow] runs a background check
/// (shared by the launch host and the "Check now" button) and refreshes
/// [resolvedModelProvider] so a newly staged model applies at the next session.

abstract class _$ModelUpdateController
    extends $AsyncNotifier<ModelUpdateStatus> {
  FutureOr<ModelUpdateStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ModelUpdateStatus>, ModelUpdateStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ModelUpdateStatus>, ModelUpdateStatus>,
              AsyncValue<ModelUpdateStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
