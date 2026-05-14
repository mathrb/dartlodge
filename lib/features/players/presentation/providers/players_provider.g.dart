// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'players_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditPlayerNotifier)
final editPlayerProvider = EditPlayerNotifierProvider._();

final class EditPlayerNotifierProvider
    extends $NotifierProvider<EditPlayerNotifier, PlayerFormState> {
  EditPlayerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editPlayerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editPlayerNotifierHash();

  @$internal
  @override
  EditPlayerNotifier create() => EditPlayerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerFormState>(value),
    );
  }
}

String _$editPlayerNotifierHash() =>
    r'ae795822d2c2518c25e322f6afffb8068c475164';

abstract class _$EditPlayerNotifier extends $Notifier<PlayerFormState> {
  PlayerFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayerFormState, PlayerFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerFormState, PlayerFormState>,
              PlayerFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CreatePlayerNotifier)
final createPlayerProvider = CreatePlayerNotifierProvider._();

final class CreatePlayerNotifierProvider
    extends $NotifierProvider<CreatePlayerNotifier, PlayerFormState> {
  CreatePlayerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createPlayerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createPlayerNotifierHash();

  @$internal
  @override
  CreatePlayerNotifier create() => CreatePlayerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerFormState>(value),
    );
  }
}

String _$createPlayerNotifierHash() =>
    r'b212fa8eabfbcea0c7bb00d33a9fe3ad08935668';

abstract class _$CreatePlayerNotifier extends $Notifier<PlayerFormState> {
  PlayerFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayerFormState, PlayerFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerFormState, PlayerFormState>,
              PlayerFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
