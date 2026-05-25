// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_practice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivePracticeNotifier)
final activePracticeProvider = ActivePracticeNotifierFamily._();

final class ActivePracticeNotifierProvider
    extends
        $AsyncNotifierProvider<ActivePracticeNotifier, ActivePracticeState?> {
  ActivePracticeNotifierProvider._({
    required ActivePracticeNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activePracticeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activePracticeNotifierHash();

  @override
  String toString() {
    return r'activePracticeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActivePracticeNotifier create() => ActivePracticeNotifier();

  @override
  bool operator ==(Object other) {
    return other is ActivePracticeNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activePracticeNotifierHash() =>
    r'810d1190acc4956ed0fc122c866ddab7aead4611';

final class ActivePracticeNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ActivePracticeNotifier,
          AsyncValue<ActivePracticeState?>,
          ActivePracticeState?,
          FutureOr<ActivePracticeState?>,
          String
        > {
  ActivePracticeNotifierFamily._()
    : super(
        retry: null,
        name: r'activePracticeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActivePracticeNotifierProvider call(String gameId) =>
      ActivePracticeNotifierProvider._(argument: gameId, from: this);

  @override
  String toString() => r'activePracticeProvider';
}

abstract class _$ActivePracticeNotifier
    extends $AsyncNotifier<ActivePracticeState?> {
  late final _$args = ref.$arg as String;
  String get gameId => _$args;

  FutureOr<ActivePracticeState?> build(String gameId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ActivePracticeState?>, ActivePracticeState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ActivePracticeState?>,
                ActivePracticeState?
              >,
              AsyncValue<ActivePracticeState?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
