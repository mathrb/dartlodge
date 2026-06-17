// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'players_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reactive stream of all players. Backed by drift's `.watch()`, so any
/// mutation through `PlayerRepository` automatically refreshes consumers.
///
/// Lives in `core/providers/` because it is consumed across multiple features
/// (game player-selection, statistics tab, settings, players list). The
/// per-feature form notifiers (`CreatePlayerNotifier`, `EditPlayerNotifier`)
/// stay in `features/players/presentation/providers/`.

@ProviderFor(AllPlayers)
final allPlayersProvider = AllPlayersProvider._();

/// Reactive stream of all players. Backed by drift's `.watch()`, so any
/// mutation through `PlayerRepository` automatically refreshes consumers.
///
/// Lives in `core/providers/` because it is consumed across multiple features
/// (game player-selection, statistics tab, settings, players list). The
/// per-feature form notifiers (`CreatePlayerNotifier`, `EditPlayerNotifier`)
/// stay in `features/players/presentation/providers/`.
final class AllPlayersProvider
    extends $StreamNotifierProvider<AllPlayers, List<Player>> {
  /// Reactive stream of all players. Backed by drift's `.watch()`, so any
  /// mutation through `PlayerRepository` automatically refreshes consumers.
  ///
  /// Lives in `core/providers/` because it is consumed across multiple features
  /// (game player-selection, statistics tab, settings, players list). The
  /// per-feature form notifiers (`CreatePlayerNotifier`, `EditPlayerNotifier`)
  /// stay in `features/players/presentation/providers/`.
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

/// Reactive stream of all players. Backed by drift's `.watch()`, so any
/// mutation through `PlayerRepository` automatically refreshes consumers.
///
/// Lives in `core/providers/` because it is consumed across multiple features
/// (game player-selection, statistics tab, settings, players list). The
/// per-feature form notifiers (`CreatePlayerNotifier`, `EditPlayerNotifier`)
/// stay in `features/players/presentation/providers/`.

abstract class _$AllPlayers extends $StreamNotifier<List<Player>> {
  Stream<List<Player>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Player>>, List<Player>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Player>>, List<Player>>,
              AsyncValue<List<Player>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
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
