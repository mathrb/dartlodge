// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aim_confirmed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has completed the full-screen aim step once during THIS app
/// run (#687). In-memory only (NOT persisted): a `keepAlive` provider lives for
/// the app-session lifetime and resets on restart — exactly the "skip setup for
/// the next consecutive game, but re-prompt after a relaunch (where the phone
/// was likely re-mounted)" semantics we want.
///
/// When true, [AutoScorerBoardOverlay] skips the aim view on the next camera
/// start and goes straight to the running preview. Scoring is unaffected: the
/// running preview re-derives the board transform live from each frame's
/// calibration points, so the aim step is only a positioning confidence gate.
/// The "Re-aim" button in the running preview re-runs it when the phone moved.

@ProviderFor(AutoScorerAimConfirmed)
final autoScorerAimConfirmedProvider = AutoScorerAimConfirmedProvider._();

/// Whether the user has completed the full-screen aim step once during THIS app
/// run (#687). In-memory only (NOT persisted): a `keepAlive` provider lives for
/// the app-session lifetime and resets on restart — exactly the "skip setup for
/// the next consecutive game, but re-prompt after a relaunch (where the phone
/// was likely re-mounted)" semantics we want.
///
/// When true, [AutoScorerBoardOverlay] skips the aim view on the next camera
/// start and goes straight to the running preview. Scoring is unaffected: the
/// running preview re-derives the board transform live from each frame's
/// calibration points, so the aim step is only a positioning confidence gate.
/// The "Re-aim" button in the running preview re-runs it when the phone moved.
final class AutoScorerAimConfirmedProvider
    extends $NotifierProvider<AutoScorerAimConfirmed, bool> {
  /// Whether the user has completed the full-screen aim step once during THIS app
  /// run (#687). In-memory only (NOT persisted): a `keepAlive` provider lives for
  /// the app-session lifetime and resets on restart — exactly the "skip setup for
  /// the next consecutive game, but re-prompt after a relaunch (where the phone
  /// was likely re-mounted)" semantics we want.
  ///
  /// When true, [AutoScorerBoardOverlay] skips the aim view on the next camera
  /// start and goes straight to the running preview. Scoring is unaffected: the
  /// running preview re-derives the board transform live from each frame's
  /// calibration points, so the aim step is only a positioning confidence gate.
  /// The "Re-aim" button in the running preview re-runs it when the phone moved.
  AutoScorerAimConfirmedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerAimConfirmedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerAimConfirmedHash();

  @$internal
  @override
  AutoScorerAimConfirmed create() => AutoScorerAimConfirmed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$autoScorerAimConfirmedHash() =>
    r'99522658cbf44b3ca408b87246c573013d3f15f3';

/// Whether the user has completed the full-screen aim step once during THIS app
/// run (#687). In-memory only (NOT persisted): a `keepAlive` provider lives for
/// the app-session lifetime and resets on restart — exactly the "skip setup for
/// the next consecutive game, but re-prompt after a relaunch (where the phone
/// was likely re-mounted)" semantics we want.
///
/// When true, [AutoScorerBoardOverlay] skips the aim view on the next camera
/// start and goes straight to the running preview. Scoring is unaffected: the
/// running preview re-derives the board transform live from each frame's
/// calibration points, so the aim step is only a positioning confidence gate.
/// The "Re-aim" button in the running preview re-runs it when the phone moved.

abstract class _$AutoScorerAimConfirmed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
