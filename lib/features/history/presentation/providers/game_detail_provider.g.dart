// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameDetailNotifier)
final gameDetailProvider = GameDetailNotifierFamily._();

final class GameDetailNotifierProvider
    extends $AsyncNotifierProvider<GameDetailNotifier, GameDetailState?> {
  GameDetailNotifierProvider._({
    required GameDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gameDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gameDetailNotifierHash();

  @override
  String toString() {
    return r'gameDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GameDetailNotifier create() => GameDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is GameDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameDetailNotifierHash() =>
    r'f493757212542257ec1c7ff5bdec4b944d057260';

final class GameDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GameDetailNotifier,
          AsyncValue<GameDetailState?>,
          GameDetailState?,
          FutureOr<GameDetailState?>,
          String
        > {
  GameDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'gameDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GameDetailNotifierProvider call(String gameId) =>
      GameDetailNotifierProvider._(argument: gameId, from: this);

  @override
  String toString() => r'gameDetailProvider';
}

abstract class _$GameDetailNotifier extends $AsyncNotifier<GameDetailState?> {
  late final _$args = ref.$arg as String;
  String get gameId => _$args;

  FutureOr<GameDetailState?> build(String gameId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<GameDetailState?>, GameDetailState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GameDetailState?>, GameDetailState?>,
              AsyncValue<GameDetailState?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
