// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_setup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameSetupNotifier)
final gameSetupProvider = GameSetupNotifierProvider._();

final class GameSetupNotifierProvider
    extends $NotifierProvider<GameSetupNotifier, GameSetupState> {
  GameSetupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameSetupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameSetupNotifierHash();

  @$internal
  @override
  GameSetupNotifier create() => GameSetupNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameSetupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameSetupState>(value),
    );
  }
}

String _$gameSetupNotifierHash() => r'c862b735ad6b5eefafc9fd830ea4492e7a164abf';

abstract class _$GameSetupNotifier extends $Notifier<GameSetupState> {
  GameSetupState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GameSetupState, GameSetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GameSetupState, GameSetupState>,
              GameSetupState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
