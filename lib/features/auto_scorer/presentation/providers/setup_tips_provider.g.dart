// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setup_tips_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has dismissed the one-time auto-scorer setup tips (#393
/// setup flow). Default **false** so the tips show before the first aim; the
/// "don't show again" checkbox sets it true. The Settings page can reset it via
/// [setSeen] to re-show the tips. Mirrors [DataCollectionEnabled].

@ProviderFor(AutoScorerSetupTipsSeen)
final autoScorerSetupTipsSeenProvider = AutoScorerSetupTipsSeenProvider._();

/// Whether the user has dismissed the one-time auto-scorer setup tips (#393
/// setup flow). Default **false** so the tips show before the first aim; the
/// "don't show again" checkbox sets it true. The Settings page can reset it via
/// [setSeen] to re-show the tips. Mirrors [DataCollectionEnabled].
final class AutoScorerSetupTipsSeenProvider
    extends $AsyncNotifierProvider<AutoScorerSetupTipsSeen, bool> {
  /// Whether the user has dismissed the one-time auto-scorer setup tips (#393
  /// setup flow). Default **false** so the tips show before the first aim; the
  /// "don't show again" checkbox sets it true. The Settings page can reset it via
  /// [setSeen] to re-show the tips. Mirrors [DataCollectionEnabled].
  AutoScorerSetupTipsSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerSetupTipsSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerSetupTipsSeenHash();

  @$internal
  @override
  AutoScorerSetupTipsSeen create() => AutoScorerSetupTipsSeen();
}

String _$autoScorerSetupTipsSeenHash() =>
    r'2b5c2df4ac4308b18b8ac040192ece777db4443c';

/// Whether the user has dismissed the one-time auto-scorer setup tips (#393
/// setup flow). Default **false** so the tips show before the first aim; the
/// "don't show again" checkbox sets it true. The Settings page can reset it via
/// [setSeen] to re-show the tips. Mirrors [DataCollectionEnabled].

abstract class _$AutoScorerSetupTipsSeen extends $AsyncNotifier<bool> {
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
