// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_collection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The training-photo capture opt-in (#381 §6) — distinct from the "Use
/// auto-scoring" switch (#382). Default **off**: we never silently hoard board
/// photos. Since #686 the single "Record for debugging & training" Settings
/// toggle drives this together with [SessionRecordingEnabled]; this is the
/// persisted state + gating the capture pipeline consults.

@ProviderFor(DataCollectionEnabled)
final dataCollectionEnabledProvider = DataCollectionEnabledProvider._();

/// The training-photo capture opt-in (#381 §6) — distinct from the "Use
/// auto-scoring" switch (#382). Default **off**: we never silently hoard board
/// photos. Since #686 the single "Record for debugging & training" Settings
/// toggle drives this together with [SessionRecordingEnabled]; this is the
/// persisted state + gating the capture pipeline consults.
final class DataCollectionEnabledProvider
    extends $AsyncNotifierProvider<DataCollectionEnabled, bool> {
  /// The training-photo capture opt-in (#381 §6) — distinct from the "Use
  /// auto-scoring" switch (#382). Default **off**: we never silently hoard board
  /// photos. Since #686 the single "Record for debugging & training" Settings
  /// toggle drives this together with [SessionRecordingEnabled]; this is the
  /// persisted state + gating the capture pipeline consults.
  DataCollectionEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataCollectionEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataCollectionEnabledHash();

  @$internal
  @override
  DataCollectionEnabled create() => DataCollectionEnabled();
}

String _$dataCollectionEnabledHash() =>
    r'81e50eed57200a7db196a979bf9a240d885e66c1';

/// The training-photo capture opt-in (#381 §6) — distinct from the "Use
/// auto-scoring" switch (#382). Default **off**: we never silently hoard board
/// photos. Since #686 the single "Record for debugging & training" Settings
/// toggle drives this together with [SessionRecordingEnabled]; this is the
/// persisted state + gating the capture pipeline consults.

abstract class _$DataCollectionEnabled extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Persisted [CaptureMode] (#457), default [CaptureMode.partial] (#686): for a
/// 1.0 user the useful contribution is the model's mistakes (corrected frames),
/// not a flood of easy/correct examples — so "Mistakes only" is the sane
/// default. Only meaningful while data collection is on.

@ProviderFor(CaptureModeSetting)
final captureModeSettingProvider = CaptureModeSettingProvider._();

/// Persisted [CaptureMode] (#457), default [CaptureMode.partial] (#686): for a
/// 1.0 user the useful contribution is the model's mistakes (corrected frames),
/// not a flood of easy/correct examples — so "Mistakes only" is the sane
/// default. Only meaningful while data collection is on.
final class CaptureModeSettingProvider
    extends $AsyncNotifierProvider<CaptureModeSetting, CaptureMode> {
  /// Persisted [CaptureMode] (#457), default [CaptureMode.partial] (#686): for a
  /// 1.0 user the useful contribution is the model's mistakes (corrected frames),
  /// not a flood of easy/correct examples — so "Mistakes only" is the sane
  /// default. Only meaningful while data collection is on.
  CaptureModeSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureModeSettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureModeSettingHash();

  @$internal
  @override
  CaptureModeSetting create() => CaptureModeSetting();
}

String _$captureModeSettingHash() =>
    r'964703e8c79a0b4aac5e42fecbee8384b171e240';

/// Persisted [CaptureMode] (#457), default [CaptureMode.partial] (#686): for a
/// 1.0 user the useful contribution is the model's mistakes (corrected frames),
/// not a flood of easy/correct examples — so "Mistakes only" is the sane
/// default. Only meaningful while data collection is on.

abstract class _$CaptureModeSetting extends $AsyncNotifier<CaptureMode> {
  FutureOr<CaptureMode> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CaptureMode>, CaptureMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CaptureMode>, CaptureMode>,
              AsyncValue<CaptureMode>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The on-device capture store (file-backed on mobile, no-op on web). Consumers
/// gate on [CaptureStore.isSupported] before offering capture/export.

@ProviderFor(captureStore)
final captureStoreProvider = CaptureStoreProvider._();

/// The on-device capture store (file-backed on mobile, no-op on web). Consumers
/// gate on [CaptureStore.isSupported] before offering capture/export.

final class CaptureStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<CaptureStore>,
          CaptureStore,
          FutureOr<CaptureStore>
        >
    with $FutureModifier<CaptureStore>, $FutureProvider<CaptureStore> {
  /// The on-device capture store (file-backed on mobile, no-op on web). Consumers
  /// gate on [CaptureStore.isSupported] before offering capture/export.
  CaptureStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureStoreHash();

  @$internal
  @override
  $FutureProviderElement<CaptureStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CaptureStore> create(Ref ref) {
    return captureStore(ref);
  }
}

String _$captureStoreHash() => r'52a46c964914f27370ff2fd32b833a6044d340d8';
