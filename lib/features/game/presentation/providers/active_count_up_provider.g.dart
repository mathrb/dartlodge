// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_count_up_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Active-game notifier for count-up.
///
/// Mirrors [ActiveGameNotifier] (X01) but trimmed for count-up's simpler
/// rules: no bust, single leg, no round-cap dialog. The game ends only on
/// the TurnEnded that follows the last competitor of the last round; the
/// engine's [LegOutcome.gameCompleted] result drives that transition.

@ProviderFor(ActiveCountUpNotifier)
final activeCountUpProvider = ActiveCountUpNotifierFamily._();

/// Active-game notifier for count-up.
///
/// Mirrors [ActiveGameNotifier] (X01) but trimmed for count-up's simpler
/// rules: no bust, single leg, no round-cap dialog. The game ends only on
/// the TurnEnded that follows the last competitor of the last round; the
/// engine's [LegOutcome.gameCompleted] result drives that transition.
final class ActiveCountUpNotifierProvider
    extends $AsyncNotifierProvider<ActiveCountUpNotifier, ActiveCountUpState?> {
  /// Active-game notifier for count-up.
  ///
  /// Mirrors [ActiveGameNotifier] (X01) but trimmed for count-up's simpler
  /// rules: no bust, single leg, no round-cap dialog. The game ends only on
  /// the TurnEnded that follows the last competitor of the last round; the
  /// engine's [LegOutcome.gameCompleted] result drives that transition.
  ActiveCountUpNotifierProvider._({
    required ActiveCountUpNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeCountUpProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeCountUpNotifierHash();

  @override
  String toString() {
    return r'activeCountUpProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActiveCountUpNotifier create() => ActiveCountUpNotifier();

  @override
  bool operator ==(Object other) {
    return other is ActiveCountUpNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeCountUpNotifierHash() =>
    r'77a329bad9b4dd0ca2088edd360fcf94e4c4804d';

/// Active-game notifier for count-up.
///
/// Mirrors [ActiveGameNotifier] (X01) but trimmed for count-up's simpler
/// rules: no bust, single leg, no round-cap dialog. The game ends only on
/// the TurnEnded that follows the last competitor of the last round; the
/// engine's [LegOutcome.gameCompleted] result drives that transition.

final class ActiveCountUpNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ActiveCountUpNotifier,
          AsyncValue<ActiveCountUpState?>,
          ActiveCountUpState?,
          FutureOr<ActiveCountUpState?>,
          String
        > {
  ActiveCountUpNotifierFamily._()
    : super(
        retry: null,
        name: r'activeCountUpProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Active-game notifier for count-up.
  ///
  /// Mirrors [ActiveGameNotifier] (X01) but trimmed for count-up's simpler
  /// rules: no bust, single leg, no round-cap dialog. The game ends only on
  /// the TurnEnded that follows the last competitor of the last round; the
  /// engine's [LegOutcome.gameCompleted] result drives that transition.

  ActiveCountUpNotifierProvider call(String gameId) =>
      ActiveCountUpNotifierProvider._(argument: gameId, from: this);

  @override
  String toString() => r'activeCountUpProvider';
}

/// Active-game notifier for count-up.
///
/// Mirrors [ActiveGameNotifier] (X01) but trimmed for count-up's simpler
/// rules: no bust, single leg, no round-cap dialog. The game ends only on
/// the TurnEnded that follows the last competitor of the last round; the
/// engine's [LegOutcome.gameCompleted] result drives that transition.

abstract class _$ActiveCountUpNotifier
    extends $AsyncNotifier<ActiveCountUpState?> {
  late final _$args = ref.$arg as String;
  String get gameId => _$args;

  FutureOr<ActiveCountUpState?> build(String gameId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ActiveCountUpState?>, ActiveCountUpState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ActiveCountUpState?>, ActiveCountUpState?>,
              AsyncValue<ActiveCountUpState?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
