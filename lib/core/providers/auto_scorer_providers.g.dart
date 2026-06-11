// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_scorer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Master "Use auto-scoring" switch (#382 §5.1), default **off**. Distinct from
/// the data-collection opt-in (#381). Lives in `core/` because it is read both
/// by the auto_scorer feature (whether to run the camera) and the game board
/// (whether to offer the assist entry point) — a cross-feature concern.

@ProviderFor(AutoScoringEnabled)
final autoScoringEnabledProvider = AutoScoringEnabledProvider._();

/// Master "Use auto-scoring" switch (#382 §5.1), default **off**. Distinct from
/// the data-collection opt-in (#381). Lives in `core/` because it is read both
/// by the auto_scorer feature (whether to run the camera) and the game board
/// (whether to offer the assist entry point) — a cross-feature concern.
final class AutoScoringEnabledProvider
    extends $AsyncNotifierProvider<AutoScoringEnabled, bool> {
  /// Master "Use auto-scoring" switch (#382 §5.1), default **off**. Distinct from
  /// the data-collection opt-in (#381). Lives in `core/` because it is read both
  /// by the auto_scorer feature (whether to run the camera) and the game board
  /// (whether to offer the assist entry point) — a cross-feature concern.
  AutoScoringEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScoringEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScoringEnabledHash();

  @$internal
  @override
  AutoScoringEnabled create() => AutoScoringEnabled();
}

String _$autoScoringEnabledHash() =>
    r'90581e2c5c601a888bad46c216059f434805ea64';

/// Master "Use auto-scoring" switch (#382 §5.1), default **off**. Distinct from
/// the data-collection opt-in (#381). Lives in `core/` because it is read both
/// by the auto_scorer feature (whether to run the camera) and the game board
/// (whether to offer the assist entry point) — a cross-feature concern.

abstract class _$AutoScoringEnabled extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Holds the [DartInputSink] of the currently active game board, so the
/// auto-scorer can emit detected darts without importing the game feature. The
/// board binds itself on entry and clears on exit.

@ProviderFor(ActiveDartInputSink)
final activeDartInputSinkProvider = ActiveDartInputSinkProvider._();

/// Holds the [DartInputSink] of the currently active game board, so the
/// auto-scorer can emit detected darts without importing the game feature. The
/// board binds itself on entry and clears on exit.
final class ActiveDartInputSinkProvider
    extends $NotifierProvider<ActiveDartInputSink, DartInputSink?> {
  /// Holds the [DartInputSink] of the currently active game board, so the
  /// auto-scorer can emit detected darts without importing the game feature. The
  /// board binds itself on entry and clears on exit.
  ActiveDartInputSinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDartInputSinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDartInputSinkHash();

  @$internal
  @override
  ActiveDartInputSink create() => ActiveDartInputSink();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DartInputSink? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DartInputSink?>(value),
    );
  }
}

String _$activeDartInputSinkHash() =>
    r'bdc69ca04c3faaa2150f13e15d0ea9b0115b9f55';

/// Holds the [DartInputSink] of the currently active game board, so the
/// auto-scorer can emit detected darts without importing the game feature. The
/// board binds itself on entry and clears on exit.

abstract class _$ActiveDartInputSink extends $Notifier<DartInputSink?> {
  DartInputSink? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DartInputSink?, DartInputSink?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DartInputSink?, DartInputSink?>,
              DartInputSink?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// A monotonically increasing counter bumped by the game board whenever the
/// **turn advances** (manual next-turn). The auto-scorer listens so it can reset
/// the per-turn 3-dart cap in lock-step — without this, advancing via the
/// board's own next button (which can't reach the tracker) would wedge the cap
/// and silently block the next player's darts (#380 / #382 rework). Cross-feature
/// via `core/`, mirroring the sink bridge.

@ProviderFor(ActiveTurnSignal)
final activeTurnSignalProvider = ActiveTurnSignalProvider._();

/// A monotonically increasing counter bumped by the game board whenever the
/// **turn advances** (manual next-turn). The auto-scorer listens so it can reset
/// the per-turn 3-dart cap in lock-step — without this, advancing via the
/// board's own next button (which can't reach the tracker) would wedge the cap
/// and silently block the next player's darts (#380 / #382 rework). Cross-feature
/// via `core/`, mirroring the sink bridge.
final class ActiveTurnSignalProvider
    extends $NotifierProvider<ActiveTurnSignal, int> {
  /// A monotonically increasing counter bumped by the game board whenever the
  /// **turn advances** (manual next-turn). The auto-scorer listens so it can reset
  /// the per-turn 3-dart cap in lock-step — without this, advancing via the
  /// board's own next button (which can't reach the tracker) would wedge the cap
  /// and silently block the next player's darts (#380 / #382 rework). Cross-feature
  /// via `core/`, mirroring the sink bridge.
  ActiveTurnSignalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeTurnSignalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeTurnSignalHash();

  @$internal
  @override
  ActiveTurnSignal create() => ActiveTurnSignal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeTurnSignalHash() => r'f4f8746322e0e62b2ed8b960da05781be3a5d49d';

/// A monotonically increasing counter bumped by the game board whenever the
/// **turn advances** (manual next-turn). The auto-scorer listens so it can reset
/// the per-turn 3-dart cap in lock-step — without this, advancing via the
/// board's own next button (which can't reach the tracker) would wedge the cap
/// and silently block the next player's darts (#380 / #382 rework). Cross-feature
/// via `core/`, mirroring the sink bridge.

abstract class _$ActiveTurnSignal extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Holds the [CaptureCorrectionSink] of the active auto-scoring overlay, so the
/// game's correction flow can propagate a dart correction into the matching
/// training capture without importing the auto_scorer feature. The auto-scorer
/// overlay binds itself while running and clears on stop — null when no
/// auto-scoring session is active, so the game side simply no-ops. Inverse of
/// the [ActiveDartInputSink] bridge (here the auto_scorer binds, the game calls).

@ProviderFor(ActiveCaptureCorrectionSink)
final activeCaptureCorrectionSinkProvider =
    ActiveCaptureCorrectionSinkProvider._();

/// Holds the [CaptureCorrectionSink] of the active auto-scoring overlay, so the
/// game's correction flow can propagate a dart correction into the matching
/// training capture without importing the auto_scorer feature. The auto-scorer
/// overlay binds itself while running and clears on stop — null when no
/// auto-scoring session is active, so the game side simply no-ops. Inverse of
/// the [ActiveDartInputSink] bridge (here the auto_scorer binds, the game calls).
final class ActiveCaptureCorrectionSinkProvider
    extends
        $NotifierProvider<ActiveCaptureCorrectionSink, CaptureCorrectionSink?> {
  /// Holds the [CaptureCorrectionSink] of the active auto-scoring overlay, so the
  /// game's correction flow can propagate a dart correction into the matching
  /// training capture without importing the auto_scorer feature. The auto-scorer
  /// overlay binds itself while running and clears on stop — null when no
  /// auto-scoring session is active, so the game side simply no-ops. Inverse of
  /// the [ActiveDartInputSink] bridge (here the auto_scorer binds, the game calls).
  ActiveCaptureCorrectionSinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeCaptureCorrectionSinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeCaptureCorrectionSinkHash();

  @$internal
  @override
  ActiveCaptureCorrectionSink create() => ActiveCaptureCorrectionSink();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaptureCorrectionSink? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaptureCorrectionSink?>(value),
    );
  }
}

String _$activeCaptureCorrectionSinkHash() =>
    r'2c142bd012f8e93c703224e9460244ad8b2b6a35';

/// Holds the [CaptureCorrectionSink] of the active auto-scoring overlay, so the
/// game's correction flow can propagate a dart correction into the matching
/// training capture without importing the auto_scorer feature. The auto-scorer
/// overlay binds itself while running and clears on stop — null when no
/// auto-scoring session is active, so the game side simply no-ops. Inverse of
/// the [ActiveDartInputSink] bridge (here the auto_scorer binds, the game calls).

abstract class _$ActiveCaptureCorrectionSink
    extends $Notifier<CaptureCorrectionSink?> {
  CaptureCorrectionSink? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<CaptureCorrectionSink?, CaptureCorrectionSink?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CaptureCorrectionSink?, CaptureCorrectionSink?>,
              CaptureCorrectionSink?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
