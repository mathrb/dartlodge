// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simplified_input_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The "Simplified scoring keypad" preference, default **OFF** — the dense full
/// grid stays the default. When on, the X01 and Count-up board pages swap their
/// manual input to a larger keypad (numbers + armed Double/Triple). Lives in
/// `core/` (not `features/settings/`) because it is read across features: the
/// game board pages select the layout on it and the Settings page toggles it —
/// a cross-feature seam belongs in `core/` (mirrors `SoundEnabled`).

@ProviderFor(SimplifiedInputEnabled)
final simplifiedInputEnabledProvider = SimplifiedInputEnabledProvider._();

/// The "Simplified scoring keypad" preference, default **OFF** — the dense full
/// grid stays the default. When on, the X01 and Count-up board pages swap their
/// manual input to a larger keypad (numbers + armed Double/Triple). Lives in
/// `core/` (not `features/settings/`) because it is read across features: the
/// game board pages select the layout on it and the Settings page toggles it —
/// a cross-feature seam belongs in `core/` (mirrors `SoundEnabled`).
final class SimplifiedInputEnabledProvider
    extends $AsyncNotifierProvider<SimplifiedInputEnabled, bool> {
  /// The "Simplified scoring keypad" preference, default **OFF** — the dense full
  /// grid stays the default. When on, the X01 and Count-up board pages swap their
  /// manual input to a larger keypad (numbers + armed Double/Triple). Lives in
  /// `core/` (not `features/settings/`) because it is read across features: the
  /// game board pages select the layout on it and the Settings page toggles it —
  /// a cross-feature seam belongs in `core/` (mirrors `SoundEnabled`).
  SimplifiedInputEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'simplifiedInputEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$simplifiedInputEnabledHash();

  @$internal
  @override
  SimplifiedInputEnabled create() => SimplifiedInputEnabled();
}

String _$simplifiedInputEnabledHash() =>
    r'067f032194c42b3f5555a5c2cb203ff033d37ab0';

/// The "Simplified scoring keypad" preference, default **OFF** — the dense full
/// grid stays the default. When on, the X01 and Count-up board pages swap their
/// manual input to a larger keypad (numbers + armed Double/Triple). Lives in
/// `core/` (not `features/settings/`) because it is read across features: the
/// game board pages select the layout on it and the Settings page toggles it —
/// a cross-feature seam belongs in `core/` (mirrors `SoundEnabled`).

abstract class _$SimplifiedInputEnabled extends $AsyncNotifier<bool> {
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
