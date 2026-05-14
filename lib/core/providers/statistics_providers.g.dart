// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cross-feature read providers exposing statistics data to callers outside
/// the statistics feature (e.g. the game player-picker AVG badge, in-game
/// live stats display, post-game summary).
///
/// Page-internal state and filter-driven derivations for the Player Stats
/// screen live in
/// `lib/features/statistics/presentation/providers/player_stats_page_provider.dart`
/// so that `features/statistics/` presentation types are not imported from
/// `core/` (which would invert the architecture's dependency direction).

@ProviderFor(playerStats)
final playerStatsProvider = PlayerStatsFamily._();

/// Cross-feature read providers exposing statistics data to callers outside
/// the statistics feature (e.g. the game player-picker AVG badge, in-game
/// live stats display, post-game summary).
///
/// Page-internal state and filter-driven derivations for the Player Stats
/// screen live in
/// `lib/features/statistics/presentation/providers/player_stats_page_provider.dart`
/// so that `features/statistics/` presentation types are not imported from
/// `core/` (which would invert the architecture's dependency direction).

final class PlayerStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerStats>,
          PlayerStats,
          Stream<PlayerStats>
        >
    with $FutureModifier<PlayerStats>, $StreamProvider<PlayerStats> {
  /// Cross-feature read providers exposing statistics data to callers outside
  /// the statistics feature (e.g. the game player-picker AVG badge, in-game
  /// live stats display, post-game summary).
  ///
  /// Page-internal state and filter-driven derivations for the Player Stats
  /// screen live in
  /// `lib/features/statistics/presentation/providers/player_stats_page_provider.dart`
  /// so that `features/statistics/` presentation types are not imported from
  /// `core/` (which would invert the architecture's dependency direction).
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

String _$playerStatsHash() => r'c2b7717ab6faabf59bd007b745ef5032d5daec3a';

/// Cross-feature read providers exposing statistics data to callers outside
/// the statistics feature (e.g. the game player-picker AVG badge, in-game
/// live stats display, post-game summary).
///
/// Page-internal state and filter-driven derivations for the Player Stats
/// screen live in
/// `lib/features/statistics/presentation/providers/player_stats_page_provider.dart`
/// so that `features/statistics/` presentation types are not imported from
/// `core/` (which would invert the architecture's dependency direction).

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

  /// Cross-feature read providers exposing statistics data to callers outside
  /// the statistics feature (e.g. the game player-picker AVG badge, in-game
  /// live stats display, post-game summary).
  ///
  /// Page-internal state and filter-driven derivations for the Player Stats
  /// screen live in
  /// `lib/features/statistics/presentation/providers/player_stats_page_provider.dart`
  /// so that `features/statistics/` presentation types are not imported from
  /// `core/` (which would invert the architecture's dependency direction).

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

@ProviderFor(gameStats)
final gameStatsProvider = GameStatsFamily._();

final class GameStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<GameStats>,
          GameStats,
          FutureOr<GameStats>
        >
    with $FutureModifier<GameStats>, $FutureProvider<GameStats> {
  GameStatsProvider._({
    required GameStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gameStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gameStatsHash();

  @override
  String toString() {
    return r'gameStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GameStats> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GameStats> create(Ref ref) {
    final argument = this.argument as String;
    return gameStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GameStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameStatsHash() => r'67c77fee5a39c46022dc6e595efdf608b5239ecf';

final class GameStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GameStats>, String> {
  GameStatsFamily._()
    : super(
        retry: null,
        name: r'gameStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GameStatsProvider call(String gameId) =>
      GameStatsProvider._(argument: gameId, from: this);

  @override
  String toString() => r'gameStatsProvider';
}
