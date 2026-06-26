// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uncalibrated_notice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has acknowledged the one-time note shown when proceeding
/// past aiming WITHOUT calibration (markers not detected → auto-scoring off,
/// score by hand, frames help training). Default **false** so the note shows
/// the first time they continue uncalibrated; confirming sets it true so the
/// note never interrupts again. Mirrors [AutoScorerSetupTipsSeen].

@ProviderFor(AutoScorerUncalibratedNoticeSeen)
final autoScorerUncalibratedNoticeSeenProvider =
    AutoScorerUncalibratedNoticeSeenProvider._();

/// Whether the user has acknowledged the one-time note shown when proceeding
/// past aiming WITHOUT calibration (markers not detected → auto-scoring off,
/// score by hand, frames help training). Default **false** so the note shows
/// the first time they continue uncalibrated; confirming sets it true so the
/// note never interrupts again. Mirrors [AutoScorerSetupTipsSeen].
final class AutoScorerUncalibratedNoticeSeenProvider
    extends $AsyncNotifierProvider<AutoScorerUncalibratedNoticeSeen, bool> {
  /// Whether the user has acknowledged the one-time note shown when proceeding
  /// past aiming WITHOUT calibration (markers not detected → auto-scoring off,
  /// score by hand, frames help training). Default **false** so the note shows
  /// the first time they continue uncalibrated; confirming sets it true so the
  /// note never interrupts again. Mirrors [AutoScorerSetupTipsSeen].
  AutoScorerUncalibratedNoticeSeenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerUncalibratedNoticeSeenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerUncalibratedNoticeSeenHash();

  @$internal
  @override
  AutoScorerUncalibratedNoticeSeen create() =>
      AutoScorerUncalibratedNoticeSeen();
}

String _$autoScorerUncalibratedNoticeSeenHash() =>
    r'c88c8ca5267e0f14b62c7ab6a52fe0af3b62cf97';

/// Whether the user has acknowledged the one-time note shown when proceeding
/// past aiming WITHOUT calibration (markers not detected → auto-scoring off,
/// score by hand, frames help training). Default **false** so the note shows
/// the first time they continue uncalibrated; confirming sets it true so the
/// note never interrupts again. Mirrors [AutoScorerSetupTipsSeen].

abstract class _$AutoScorerUncalibratedNoticeSeen extends $AsyncNotifier<bool> {
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
