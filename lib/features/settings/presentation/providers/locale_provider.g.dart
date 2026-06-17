// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The chosen app language.
///
/// `null` = follow the device locale (the default). A non-null [Locale] is an
/// explicit override. Persisted as the bare language code under [_kLocaleKey];
/// absence of the key means "system default".
///
/// This notifier stays deliberately dumb: it does not validate the stored code
/// against [kSupportedLocales]. An unsupported or stale code is resolved by
/// `MaterialApp`'s `localeResolutionCallback` (wired in a later sub-issue),
/// which falls back to English.

@ProviderFor(LocaleSetting)
final localeSettingProvider = LocaleSettingProvider._();

/// The chosen app language.
///
/// `null` = follow the device locale (the default). A non-null [Locale] is an
/// explicit override. Persisted as the bare language code under [_kLocaleKey];
/// absence of the key means "system default".
///
/// This notifier stays deliberately dumb: it does not validate the stored code
/// against [kSupportedLocales]. An unsupported or stale code is resolved by
/// `MaterialApp`'s `localeResolutionCallback` (wired in a later sub-issue),
/// which falls back to English.
final class LocaleSettingProvider
    extends $AsyncNotifierProvider<LocaleSetting, Locale?> {
  /// The chosen app language.
  ///
  /// `null` = follow the device locale (the default). A non-null [Locale] is an
  /// explicit override. Persisted as the bare language code under [_kLocaleKey];
  /// absence of the key means "system default".
  ///
  /// This notifier stays deliberately dumb: it does not validate the stored code
  /// against [kSupportedLocales]. An unsupported or stale code is resolved by
  /// `MaterialApp`'s `localeResolutionCallback` (wired in a later sub-issue),
  /// which falls back to English.
  LocaleSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeSettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeSettingHash();

  @$internal
  @override
  LocaleSetting create() => LocaleSetting();
}

String _$localeSettingHash() => r'440d84c12d76f009e92848b7fd87717a090c23bb';

/// The chosen app language.
///
/// `null` = follow the device locale (the default). A non-null [Locale] is an
/// explicit override. Persisted as the bare language code under [_kLocaleKey];
/// absence of the key means "system default".
///
/// This notifier stays deliberately dumb: it does not validate the stored code
/// against [kSupportedLocales]. An unsupported or stale code is resolved by
/// `MaterialApp`'s `localeResolutionCallback` (wired in a later sub-issue),
/// which falls back to English.

abstract class _$LocaleSetting extends $AsyncNotifier<Locale?> {
  FutureOr<Locale?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Locale?>, Locale?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Locale?>, Locale?>,
              AsyncValue<Locale?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
