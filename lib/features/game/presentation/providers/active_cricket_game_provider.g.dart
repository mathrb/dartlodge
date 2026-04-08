// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_cricket_game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveCricketGameNotifier)
final activeCricketGameProvider = ActiveCricketGameNotifierFamily._();

final class ActiveCricketGameNotifierProvider
    extends
        $AsyncNotifierProvider<
          ActiveCricketGameNotifier,
          ActiveCricketGameState?
        > {
  ActiveCricketGameNotifierProvider._({
    required ActiveCricketGameNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeCricketGameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeCricketGameNotifierHash();

  @override
  String toString() {
    return r'activeCricketGameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActiveCricketGameNotifier create() => ActiveCricketGameNotifier();

  @override
  bool operator ==(Object other) {
    return other is ActiveCricketGameNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeCricketGameNotifierHash() =>
    r'b694b1c712e268e8aee22e0985ebfe8533e6a16e';

final class ActiveCricketGameNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ActiveCricketGameNotifier,
          AsyncValue<ActiveCricketGameState?>,
          ActiveCricketGameState?,
          FutureOr<ActiveCricketGameState?>,
          String
        > {
  ActiveCricketGameNotifierFamily._()
    : super(
        retry: null,
        name: r'activeCricketGameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveCricketGameNotifierProvider call(String gameId) =>
      ActiveCricketGameNotifierProvider._(argument: gameId, from: this);

  @override
  String toString() => r'activeCricketGameProvider';
}

abstract class _$ActiveCricketGameNotifier
    extends $AsyncNotifier<ActiveCricketGameState?> {
  late final _$args = ref.$arg as String;
  String get gameId => _$args;

  FutureOr<ActiveCricketGameState?> build(String gameId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ActiveCricketGameState?>,
              ActiveCricketGameState?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ActiveCricketGameState?>,
                ActiveCricketGameState?
              >,
              AsyncValue<ActiveCricketGameState?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
