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
