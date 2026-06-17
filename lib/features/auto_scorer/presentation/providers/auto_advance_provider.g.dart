// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_advance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The "Auto-advance turn when board is cleared" opt-in. When on, the auto-scorer
/// advances to the next turn/player as soon as it detects all darts have been
/// removed from the board (board-clear → `TrackerPhase.rebaselined`), so the
/// player doesn't press NEXT. Default **off**: changing the game flow
/// automatically is opt-in, like the other auto-scorer switches. Only consulted
/// on the YOLOView live-game path (X01 + Cricket).

@ProviderFor(AutoAdvanceOnClearEnabled)
final autoAdvanceOnClearEnabledProvider = AutoAdvanceOnClearEnabledProvider._();

/// The "Auto-advance turn when board is cleared" opt-in. When on, the auto-scorer
/// advances to the next turn/player as soon as it detects all darts have been
/// removed from the board (board-clear → `TrackerPhase.rebaselined`), so the
/// player doesn't press NEXT. Default **off**: changing the game flow
/// automatically is opt-in, like the other auto-scorer switches. Only consulted
/// on the YOLOView live-game path (X01 + Cricket).
final class AutoAdvanceOnClearEnabledProvider
    extends $AsyncNotifierProvider<AutoAdvanceOnClearEnabled, bool> {
  /// The "Auto-advance turn when board is cleared" opt-in. When on, the auto-scorer
  /// advances to the next turn/player as soon as it detects all darts have been
  /// removed from the board (board-clear → `TrackerPhase.rebaselined`), so the
  /// player doesn't press NEXT. Default **off**: changing the game flow
  /// automatically is opt-in, like the other auto-scorer switches. Only consulted
  /// on the YOLOView live-game path (X01 + Cricket).
  AutoAdvanceOnClearEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoAdvanceOnClearEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoAdvanceOnClearEnabledHash();

  @$internal
  @override
  AutoAdvanceOnClearEnabled create() => AutoAdvanceOnClearEnabled();
}

String _$autoAdvanceOnClearEnabledHash() =>
    r'd75bb50587007759efb5d875a4f51e3e506d169c';

/// The "Auto-advance turn when board is cleared" opt-in. When on, the auto-scorer
/// advances to the next turn/player as soon as it detects all darts have been
/// removed from the board (board-clear → `TrackerPhase.rebaselined`), so the
/// player doesn't press NEXT. Default **off**: changing the game flow
/// automatically is opt-in, like the other auto-scorer switches. Only consulted
/// on the YOLOView live-game path (X01 + Cricket).

abstract class _$AutoAdvanceOnClearEnabled extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
