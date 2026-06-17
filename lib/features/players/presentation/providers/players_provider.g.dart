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
    r'2850562bcbdffe87805f9709260f3beb278fa5c4';

abstract class _$EditPlayerNotifier extends $Notifier<PlayerFormState> {
  PlayerFormState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlayerFormState, PlayerFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerFormState, PlayerFormState>,
              PlayerFormState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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
    r'be619545cdaae5137910acd0008fad925a53e022';

abstract class _$CreatePlayerNotifier extends $Notifier<PlayerFormState> {
  PlayerFormState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlayerFormState, PlayerFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerFormState, PlayerFormState>,
              PlayerFormState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
