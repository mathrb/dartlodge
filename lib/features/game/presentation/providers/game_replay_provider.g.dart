// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_replay_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads a game from persistence and replays all recorded events to produce
/// the current [GameState]. Returns null when no game exists for [gameId].
///
/// Each active-game notifier delegates its [build] to this provider so the
/// fetch → initial-state → replay sequence lives in exactly one place.

@ProviderFor(loadedGameState)
final loadedGameStateProvider = LoadedGameStateFamily._();

/// Loads a game from persistence and replays all recorded events to produce
/// the current [GameState]. Returns null when no game exists for [gameId].
///
/// Each active-game notifier delegates its [build] to this provider so the
/// fetch → initial-state → replay sequence lives in exactly one place.

final class LoadedGameStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<GameState?>,
          GameState?,
          FutureOr<GameState?>
        >
    with $FutureModifier<GameState?>, $FutureProvider<GameState?> {
  /// Loads a game from persistence and replays all recorded events to produce
  /// the current [GameState]. Returns null when no game exists for [gameId].
  ///
  /// Each active-game notifier delegates its [build] to this provider so the
  /// fetch → initial-state → replay sequence lives in exactly one place.
  LoadedGameStateProvider._({
    required LoadedGameStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'loadedGameStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loadedGameStateHash();

  @override
  String toString() {
    return r'loadedGameStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GameState?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GameState?> create(Ref ref) {
    final argument = this.argument as String;
    return loadedGameState(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LoadedGameStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loadedGameStateHash() => r'da86e6a4c3dfff31cf702398ee21e8a1b8e11a16';

/// Loads a game from persistence and replays all recorded events to produce
/// the current [GameState]. Returns null when no game exists for [gameId].
///
/// Each active-game notifier delegates its [build] to this provider so the
/// fetch → initial-state → replay sequence lives in exactly one place.

final class LoadedGameStateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GameState?>, String> {
  LoadedGameStateFamily._()
    : super(
        retry: null,
        name: r'loadedGameStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads a game from persistence and replays all recorded events to produce
  /// the current [GameState]. Returns null when no game exists for [gameId].
  ///
  /// Each active-game notifier delegates its [build] to this provider so the
  /// fetch → initial-state → replay sequence lives in exactly one place.

  LoadedGameStateProvider call(String gameId) =>
      LoadedGameStateProvider._(argument: gameId, from: this);

  @override
  String toString() => r'loadedGameStateProvider';
}
