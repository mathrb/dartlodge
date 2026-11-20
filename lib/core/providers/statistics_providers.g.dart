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
/// A player's all-time stats for one [gameType]. The player picker reads
/// it for the lineup figure: X01 three-dart average, Cricket MPR.

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
/// A player's all-time stats for one [gameType]. The player picker reads
/// it for the lineup figure: X01 three-dart average, Cricket MPR.

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
  /// A player's all-time stats for one [gameType]. The player picker reads
  /// it for the lineup figure: X01 three-dart average, Cricket MPR.
  PlayerStatsProvider._({
    required PlayerStatsFamily super.from,
    required (String, GameType) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<PlayerStats> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<PlayerStats> create(Ref ref) {
    final argument = this.argument as (String, GameType);
    return playerStats(ref, argument.$1, argument.$2);
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

String _$playerStatsHash() => r'e384934a66af87c34adde8f732c448229dd3c166';

/// Cross-feature read providers exposing statistics data to callers outside
/// the statistics feature (e.g. the game player-picker AVG badge, in-game
/// live stats display, post-game summary).
///
/// Page-internal state and filter-driven derivations for the Player Stats
/// screen live in
/// `lib/features/statistics/presentation/providers/player_stats_page_provider.dart`
/// so that `features/statistics/` presentation types are not imported from
/// `core/` (which would invert the architecture's dependency direction).
/// A player's all-time stats for one [gameType]. The player picker reads
/// it for the lineup figure: X01 three-dart average, Cricket MPR.

final class PlayerStatsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<PlayerStats>, (String, GameType)> {
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
  /// A player's all-time stats for one [gameType]. The player picker reads
  /// it for the lineup figure: X01 three-dart average, Cricket MPR.

  PlayerStatsProvider call(String playerId, GameType gameType) =>
      PlayerStatsProvider._(argument: (playerId, gameType), from: this);

  @override
  String toString() => r'playerStatsProvider';
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

/// Replays `game_events` through the practice/Shanghai engine and returns
/// the post-game `GameResult`. Returns null for x01/cricket/count-up — those
/// stay on [gameStatsProvider] (x01-shaped summary chrome fits them).

@ProviderFor(gameResult)
final gameResultProvider = GameResultFamily._();

/// Replays `game_events` through the practice/Shanghai engine and returns
/// the post-game `GameResult`. Returns null for x01/cricket/count-up — those
/// stay on [gameStatsProvider] (x01-shaped summary chrome fits them).

final class GameResultProvider
    extends
        $FunctionalProvider<
          AsyncValue<GameResult?>,
          GameResult?,
          FutureOr<GameResult?>
        >
    with $FutureModifier<GameResult?>, $FutureProvider<GameResult?> {
  /// Replays `game_events` through the practice/Shanghai engine and returns
  /// the post-game `GameResult`. Returns null for x01/cricket/count-up — those
  /// stay on [gameStatsProvider] (x01-shaped summary chrome fits them).
  GameResultProvider._({
    required GameResultFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gameResultProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gameResultHash();

  @override
  String toString() {
    return r'gameResultProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GameResult?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GameResult?> create(Ref ref) {
    final argument = this.argument as String;
    return gameResult(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GameResultProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameResultHash() => r'e669d3bec51794a7ac0ab7b25912af3e7e2db839';

/// Replays `game_events` through the practice/Shanghai engine and returns
/// the post-game `GameResult`. Returns null for x01/cricket/count-up — those
/// stay on [gameStatsProvider] (x01-shaped summary chrome fits them).

final class GameResultFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GameResult?>, String> {
  GameResultFamily._()
    : super(
        retry: null,
        name: r'gameResultProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Replays `game_events` through the practice/Shanghai engine and returns
  /// the post-game `GameResult`. Returns null for x01/cricket/count-up — those
  /// stay on [gameStatsProvider] (x01-shaped summary chrome fits them).

  GameResultProvider call(String gameId) =>
      GameResultProvider._(argument: gameId, from: this);

  @override
  String toString() => r'gameResultProvider';
}
