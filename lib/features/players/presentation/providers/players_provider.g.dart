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
    r'8cb715958e62add6e67ca593f09e29b56e102f1f';

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
    r'8e791952297da5d1b0c025e81b0fab7b99aa2ba9';

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
