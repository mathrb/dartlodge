// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveGame)
final activeGameProvider = ActiveGameProvider._();

final class ActiveGameProvider
    extends $AsyncNotifierProvider<ActiveGame, GameState?> {
  ActiveGameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeGameHash();

  @$internal
  @override
  ActiveGame create() => ActiveGame();
}

String _$activeGameHash() => r'a6b7fe2c7d18448e43d6f9a2d7da351e77666bfa';

abstract class _$ActiveGame extends $AsyncNotifier<GameState?> {
  FutureOr<GameState?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GameState?>, GameState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GameState?>, GameState?>,
              AsyncValue<GameState?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
