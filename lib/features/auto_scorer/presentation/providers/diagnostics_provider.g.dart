// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Developer diagnostics for the lag investigation (#377 §3). Both default
/// **off** and are surfaced only under a "Diagnostics" section of the
/// auto-scoring settings — they never affect a normal scoring session.
/// Shows the per-frame timing HUD (capture / detect / track) over the board so
/// we can attribute perceived slowness to a stage rather than guess.

@ProviderFor(AutoScorerTimingHudEnabled)
final autoScorerTimingHudEnabledProvider =
    AutoScorerTimingHudEnabledProvider._();

/// Developer diagnostics for the lag investigation (#377 §3). Both default
/// **off** and are surfaced only under a "Diagnostics" section of the
/// auto-scoring settings — they never affect a normal scoring session.
/// Shows the per-frame timing HUD (capture / detect / track) over the board so
/// we can attribute perceived slowness to a stage rather than guess.
final class AutoScorerTimingHudEnabledProvider
    extends $AsyncNotifierProvider<AutoScorerTimingHudEnabled, bool> {
  /// Developer diagnostics for the lag investigation (#377 §3). Both default
  /// **off** and are surfaced only under a "Diagnostics" section of the
  /// auto-scoring settings — they never affect a normal scoring session.
  /// Shows the per-frame timing HUD (capture / detect / track) over the board so
  /// we can attribute perceived slowness to a stage rather than guess.
  AutoScorerTimingHudEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerTimingHudEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerTimingHudEnabledHash();

  @$internal
  @override
  AutoScorerTimingHudEnabled create() => AutoScorerTimingHudEnabled();
}

String _$autoScorerTimingHudEnabledHash() =>
    r'f68f4560c343d22740ee8a892377e13381cf11b2';

/// Developer diagnostics for the lag investigation (#377 §3). Both default
/// **off** and are surfaced only under a "Diagnostics" section of the
/// auto-scoring settings — they never affect a normal scoring session.
/// Shows the per-frame timing HUD (capture / detect / track) over the board so
/// we can attribute perceived slowness to a stage rather than guess.

abstract class _$AutoScorerTimingHudEnabled extends $AsyncNotifier<bool> {
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

/// A/B: pass raw camera bytes to the plugin instead of our 800×800 preprocess,
/// so the HUD's `detect` time reveals the preprocess cost. The detector
/// provider watches this, so toggling it rebuilds the detector; restart the
/// camera (Stop → Start) for a clean comparison. See the caveat in
/// [UltralyticsDartDetector] — perf measurement only, not data collection.

@ProviderFor(AutoScorerSkipPreprocess)
final autoScorerSkipPreprocessProvider = AutoScorerSkipPreprocessProvider._();

/// A/B: pass raw camera bytes to the plugin instead of our 800×800 preprocess,
/// so the HUD's `detect` time reveals the preprocess cost. The detector
/// provider watches this, so toggling it rebuilds the detector; restart the
/// camera (Stop → Start) for a clean comparison. See the caveat in
/// [UltralyticsDartDetector] — perf measurement only, not data collection.
final class AutoScorerSkipPreprocessProvider
    extends $AsyncNotifierProvider<AutoScorerSkipPreprocess, bool> {
  /// A/B: pass raw camera bytes to the plugin instead of our 800×800 preprocess,
  /// so the HUD's `detect` time reveals the preprocess cost. The detector
  /// provider watches this, so toggling it rebuilds the detector; restart the
  /// camera (Stop → Start) for a clean comparison. See the caveat in
  /// [UltralyticsDartDetector] — perf measurement only, not data collection.
  AutoScorerSkipPreprocessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerSkipPreprocessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerSkipPreprocessHash();

  @$internal
  @override
  AutoScorerSkipPreprocess create() => AutoScorerSkipPreprocess();
}

String _$autoScorerSkipPreprocessHash() =>
    r'f46c8f5937d9b32e1c855c43cb4cc0ac5822049a';

/// A/B: pass raw camera bytes to the plugin instead of our 800×800 preprocess,
/// so the HUD's `detect` time reveals the preprocess cost. The detector
/// provider watches this, so toggling it rebuilds the detector; restart the
/// camera (Stop → Start) for a clean comparison. See the caveat in
/// [UltralyticsDartDetector] — perf measurement only, not data collection.

abstract class _$AutoScorerSkipPreprocess extends $AsyncNotifier<bool> {
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
