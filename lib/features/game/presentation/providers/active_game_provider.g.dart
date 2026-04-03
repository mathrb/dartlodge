// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveGameNotifier)
final activeGameProvider = ActiveGameNotifierFamily._();

final class ActiveGameNotifierProvider
    extends $AsyncNotifierProvider<ActiveGameNotifier, ActiveGameState?> {
  ActiveGameNotifierProvider._({
    required ActiveGameNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeGameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeGameNotifierHash();

  @override
  String toString() {
    return r'activeGameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActiveGameNotifier create() => ActiveGameNotifier();

  @override
  bool operator ==(Object other) {
    return other is ActiveGameNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeGameNotifierHash() =>
    r'553c81b78c35dc71477ecffe2d36dab17a64ac1f';

final class ActiveGameNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ActiveGameNotifier,
          AsyncValue<ActiveGameState?>,
          ActiveGameState?,
          FutureOr<ActiveGameState?>,
          String
        > {
  ActiveGameNotifierFamily._()
    : super(
        retry: null,
        name: r'activeGameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveGameNotifierProvider call(String gameId) =>
      ActiveGameNotifierProvider._(argument: gameId, from: this);

  @override
  String toString() => r'activeGameProvider';
}

abstract class _$ActiveGameNotifier extends $AsyncNotifier<ActiveGameState?> {
  late final _$args = ref.$arg as String;
  String get gameId => _$args;

  FutureOr<ActiveGameState?> build(String gameId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ActiveGameState?>, ActiveGameState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ActiveGameState?>, ActiveGameState?>,
              AsyncValue<ActiveGameState?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
