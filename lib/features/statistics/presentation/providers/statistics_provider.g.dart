// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playerStats)
final playerStatsProvider = PlayerStatsFamily._();

final class PlayerStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerStats>,
          PlayerStats,
          Stream<PlayerStats>
        >
    with $FutureModifier<PlayerStats>, $StreamProvider<PlayerStats> {
  PlayerStatsProvider._({
    required PlayerStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerStatsHash();

  @override
  String toString() {
    return r'playerStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<PlayerStats> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PlayerStats> create(Ref ref) {
    final argument = this.argument as String;
    return playerStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerStatsHash() => r'6880daff4c73362af64f0dfc5e369bd9c3f07bd1';

final class PlayerStatsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<PlayerStats>, String> {
  PlayerStatsFamily._()
    : super(
        retry: null,
        name: r'playerStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerStatsProvider call(String playerId) =>
      PlayerStatsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerStatsProvider';
}

@ProviderFor(liveGameStats)
final liveGameStatsProvider = LiveGameStatsFamily._();

final class LiveGameStatsProvider
    extends
        $FunctionalProvider<AsyncValue<GameStats>, GameStats, Stream<GameStats>>
    with $FutureModifier<GameStats>, $StreamProvider<GameStats> {
  LiveGameStatsProvider._({
    required LiveGameStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'liveGameStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveGameStatsHash();

  @override
  String toString() {
    return r'liveGameStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<GameStats> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<GameStats> create(Ref ref) {
    final argument = this.argument as String;
    return liveGameStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveGameStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveGameStatsHash() => r'121ff3f9e648472bbb6920be2f167f48f3601a35';

final class LiveGameStatsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<GameStats>, String> {
  LiveGameStatsFamily._()
    : super(
        retry: null,
        name: r'liveGameStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LiveGameStatsProvider call(String gameId) =>
      LiveGameStatsProvider._(argument: gameId, from: this);

  @override
  String toString() => r'liveGameStatsProvider';
}

@ProviderFor(Leaderboard)
final leaderboardProvider = LeaderboardProvider._();

final class LeaderboardProvider
    extends $AsyncNotifierProvider<Leaderboard, List<PlayerStats>> {
  LeaderboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaderboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaderboardHash();

  @$internal
  @override
  Leaderboard create() => Leaderboard();
}

String _$leaderboardHash() => r'7b6f55eccbfe5f25a03e6785a2985f33ce5a6b46';

abstract class _$Leaderboard extends $AsyncNotifier<List<PlayerStats>> {
  FutureOr<List<PlayerStats>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PlayerStats>>, List<PlayerStats>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PlayerStats>>, List<PlayerStats>>,
              AsyncValue<List<PlayerStats>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(PlayerStatsPage)
final playerStatsPageProvider = PlayerStatsPageFamily._();

final class PlayerStatsPageProvider
    extends $NotifierProvider<PlayerStatsPage, PlayerStatsPageState> {
  PlayerStatsPageProvider._({
    required PlayerStatsPageFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerStatsPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerStatsPageHash();

  @override
  String toString() {
    return r'playerStatsPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlayerStatsPage create() => PlayerStatsPage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerStatsPageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerStatsPageState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerStatsPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerStatsPageHash() => r'5dabb9461cc305ef2dc0e1bfd3628b2b43f789a2';

final class PlayerStatsPageFamily extends $Family
    with
        $ClassFamilyOverride<
          PlayerStatsPage,
          PlayerStatsPageState,
          PlayerStatsPageState,
          PlayerStatsPageState,
          String
        > {
  PlayerStatsPageFamily._()
    : super(
        retry: null,
        name: r'playerStatsPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerStatsPageProvider call(String playerId) =>
      PlayerStatsPageProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerStatsPageProvider';
}

abstract class _$PlayerStatsPage extends $Notifier<PlayerStatsPageState> {
  late final _$args = ref.$arg as String;
  String get playerId => _$args;

  PlayerStatsPageState build(String playerId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayerStatsPageState, PlayerStatsPageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerStatsPageState, PlayerStatsPageState>,
              PlayerStatsPageState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(playerX01StartingScores)
final playerX01StartingScoresProvider = PlayerX01StartingScoresFamily._();

final class PlayerX01StartingScoresProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<int>>,
          List<int>,
          FutureOr<List<int>>
        >
    with $FutureModifier<List<int>>, $FutureProvider<List<int>> {
  PlayerX01StartingScoresProvider._({
    required PlayerX01StartingScoresFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerX01StartingScoresProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerX01StartingScoresHash();

  @override
  String toString() {
    return r'playerX01StartingScoresProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<int>> create(Ref ref) {
    final argument = this.argument as String;
    return playerX01StartingScores(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerX01StartingScoresProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerX01StartingScoresHash() =>
    r'310468c6b6c7317b55002e9b95fda28c50758983';

final class PlayerX01StartingScoresFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<int>>, String> {
  PlayerX01StartingScoresFamily._()
    : super(
        retry: null,
        name: r'playerX01StartingScoresProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerX01StartingScoresProvider call(String playerId) =>
      PlayerX01StartingScoresProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerX01StartingScoresProvider';
}

@ProviderFor(filteredPlayerStats)
final filteredPlayerStatsProvider = FilteredPlayerStatsFamily._();

final class FilteredPlayerStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerStats>,
          PlayerStats,
          FutureOr<PlayerStats>
        >
    with $FutureModifier<PlayerStats>, $FutureProvider<PlayerStats> {
  FilteredPlayerStatsProvider._({
    required FilteredPlayerStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'filteredPlayerStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredPlayerStatsHash();

  @override
  String toString() {
    return r'filteredPlayerStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlayerStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlayerStats> create(Ref ref) {
    final argument = this.argument as String;
    return filteredPlayerStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredPlayerStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredPlayerStatsHash() =>
    r'63ed687e8d03894e1b37eedd4527c9c6edac5af4';

final class FilteredPlayerStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlayerStats>, String> {
  FilteredPlayerStatsFamily._()
    : super(
        retry: null,
        name: r'filteredPlayerStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredPlayerStatsProvider call(String playerId) =>
      FilteredPlayerStatsProvider._(argument: playerId, from: this);

  @override
  String toString() => r'filteredPlayerStatsProvider';
}

@ProviderFor(playerLegHistory)
final playerLegHistoryProvider = PlayerLegHistoryFamily._();

final class PlayerLegHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayerLegSnapshot>>,
          List<PlayerLegSnapshot>,
          FutureOr<List<PlayerLegSnapshot>>
        >
    with
        $FutureModifier<List<PlayerLegSnapshot>>,
        $FutureProvider<List<PlayerLegSnapshot>> {
  PlayerLegHistoryProvider._({
    required PlayerLegHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerLegHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerLegHistoryHash();

  @override
  String toString() {
    return r'playerLegHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlayerLegSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlayerLegSnapshot>> create(Ref ref) {
    final argument = this.argument as String;
    return playerLegHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerLegHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerLegHistoryHash() => r'567fb41c5b65f121c1de79e342d1af06353c97e6';

final class PlayerLegHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlayerLegSnapshot>>, String> {
  PlayerLegHistoryFamily._()
    : super(
        retry: null,
        name: r'playerLegHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerLegHistoryProvider call(String playerId) =>
      PlayerLegHistoryProvider._(argument: playerId, from: this);

  @override
  String toString() => r'playerLegHistoryProvider';
}
