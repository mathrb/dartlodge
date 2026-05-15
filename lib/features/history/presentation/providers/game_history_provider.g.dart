// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameHistoryNotifier)
final gameHistoryProvider = GameHistoryNotifierProvider._();

final class GameHistoryNotifierProvider
    extends $AsyncNotifierProvider<GameHistoryNotifier, GameHistoryState> {
  GameHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameHistoryNotifierHash();

  @$internal
  @override
  GameHistoryNotifier create() => GameHistoryNotifier();
}

String _$gameHistoryNotifierHash() =>
    r'490b9ea6ef98374617e2f05ced0e84e724ce2f3a';

abstract class _$GameHistoryNotifier extends $AsyncNotifier<GameHistoryState> {
  FutureOr<GameHistoryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<GameHistoryState>, GameHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GameHistoryState>, GameHistoryState>,
              AsyncValue<GameHistoryState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
