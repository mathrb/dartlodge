// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The global "Sounds" on/off preference, default **ON** — a discreet dart
/// thunk is expected. Lives in `core/` (not `features/sound/`) because it is
/// read across features: `SoundService` gates playback on it and the Settings
/// page toggles it — a cross-feature seam belongs in `core/` (mirrors
/// `AutoScoringEnabled`). The Settings "Sound" row drives [setEnabled].

@ProviderFor(SoundEnabled)
final soundEnabledProvider = SoundEnabledProvider._();

/// The global "Sounds" on/off preference, default **ON** — a discreet dart
/// thunk is expected. Lives in `core/` (not `features/sound/`) because it is
/// read across features: `SoundService` gates playback on it and the Settings
/// page toggles it — a cross-feature seam belongs in `core/` (mirrors
/// `AutoScoringEnabled`). The Settings "Sound" row drives [setEnabled].
final class SoundEnabledProvider
    extends $AsyncNotifierProvider<SoundEnabled, bool> {
  /// The global "Sounds" on/off preference, default **ON** — a discreet dart
  /// thunk is expected. Lives in `core/` (not `features/sound/`) because it is
  /// read across features: `SoundService` gates playback on it and the Settings
  /// page toggles it — a cross-feature seam belongs in `core/` (mirrors
  /// `AutoScoringEnabled`). The Settings "Sound" row drives [setEnabled].
  SoundEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soundEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soundEnabledHash();

  @$internal
  @override
  SoundEnabled create() => SoundEnabled();
}

String _$soundEnabledHash() => r'b68fc7a77e1f798473810170c000dd8ca4f76151';

/// The global "Sounds" on/off preference, default **ON** — a discreet dart
/// thunk is expected. Lives in `core/` (not `features/sound/`) because it is
/// read across features: `SoundService` gates playback on it and the Settings
/// page toggles it — a cross-feature seam belongs in `core/` (mirrors
/// `AutoScoringEnabled`). The Settings "Sound" row drives [setEnabled].

abstract class _$SoundEnabled extends $AsyncNotifier<bool> {
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
