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
