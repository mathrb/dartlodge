// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The global "Sounds" on/off preference, default **ON** — a discreet dart
/// thunk is expected. [SoundService] reads this to gate playback. The Settings
/// UI row that toggles it is added in #519 (mirrors how [DataCollectionEnabled]
/// shipped its persisted state before its Settings row); this is the persisted
/// state + the gate the sound pipeline consults.

@ProviderFor(SoundEnabled)
final soundEnabledProvider = SoundEnabledProvider._();

/// The global "Sounds" on/off preference, default **ON** — a discreet dart
/// thunk is expected. [SoundService] reads this to gate playback. The Settings
/// UI row that toggles it is added in #519 (mirrors how [DataCollectionEnabled]
/// shipped its persisted state before its Settings row); this is the persisted
/// state + the gate the sound pipeline consults.
final class SoundEnabledProvider
    extends $AsyncNotifierProvider<SoundEnabled, bool> {
  /// The global "Sounds" on/off preference, default **ON** — a discreet dart
  /// thunk is expected. [SoundService] reads this to gate playback. The Settings
  /// UI row that toggles it is added in #519 (mirrors how [DataCollectionEnabled]
  /// shipped its persisted state before its Settings row); this is the persisted
  /// state + the gate the sound pipeline consults.
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
/// thunk is expected. [SoundService] reads this to gate playback. The Settings
/// UI row that toggles it is added in #519 (mirrors how [DataCollectionEnabled]
/// shipped its persisted state before its Settings row); this is the persisted
/// state + the gate the sound pipeline consults.

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
