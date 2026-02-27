// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'players_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AllPlayers)
final allPlayersProvider = AllPlayersProvider._();

final class AllPlayersProvider
    extends $StreamNotifierProvider<AllPlayers, List<Player>> {
  AllPlayersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPlayersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPlayersHash();

  @$internal
  @override
  AllPlayers create() => AllPlayers();
}

String _$allPlayersHash() => r'05ded208b052fd06281e115d9ff2f0134dfb1793';

abstract class _$AllPlayers extends $StreamNotifier<List<Player>> {
  Stream<List<Player>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Player>>, List<Player>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Player>>, List<Player>>,
              AsyncValue<List<Player>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(player)
final playerProvider = PlayerFamily._();

final class PlayerProvider
    extends $FunctionalProvider<AsyncValue<Player?>, Player?, FutureOr<Player?>>
    with $FutureModifier<Player?>, $FutureProvider<Player?> {
  PlayerProvider._({
    required PlayerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerHash();

  @override
  String toString() {
    return r'playerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Player?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Player?> create(Ref ref) {
    final argument = this.argument as String;
    return player(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerHash() => r'd4b80e65d609cbf04d24e19998729d7f4d4cda34';

final class PlayerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Player?>, String> {
  PlayerFamily._()
    : super(
        retry: null,
        name: r'playerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerProvider call(String id) => PlayerProvider._(argument: id, from: this);

  @override
  String toString() => r'playerProvider';
}

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
    r'b6658bc22302830288ebfd156bf8cf7244cdfee3';

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
    r'5cfea4c41b7d961658e35a0591697fd78bcdcb40';

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
