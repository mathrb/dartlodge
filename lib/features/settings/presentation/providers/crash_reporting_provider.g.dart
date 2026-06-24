// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crash_reporting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The "Send crash diagnostics" toggle. Crash reporting (Sentry) is **opt-out**:
/// default **on**, so the app keeps crash visibility for the launch, but users
/// can disable it in Settings. Because Sentry installs its native crash handler
/// at startup and a clean runtime re-init isn't supported, the toggle only takes
/// effect on the **next app launch** — `main.dart` reads [kCrashReportingPrefKey]
/// before `SentryFlutter.init`. The settings UI surfaces a "takes effect after
/// restart" note. See `docs/legal/privacy-policy.md`.

@ProviderFor(CrashReportingEnabled)
final crashReportingEnabledProvider = CrashReportingEnabledProvider._();

/// The "Send crash diagnostics" toggle. Crash reporting (Sentry) is **opt-out**:
/// default **on**, so the app keeps crash visibility for the launch, but users
/// can disable it in Settings. Because Sentry installs its native crash handler
/// at startup and a clean runtime re-init isn't supported, the toggle only takes
/// effect on the **next app launch** — `main.dart` reads [kCrashReportingPrefKey]
/// before `SentryFlutter.init`. The settings UI surfaces a "takes effect after
/// restart" note. See `docs/legal/privacy-policy.md`.
final class CrashReportingEnabledProvider
    extends $AsyncNotifierProvider<CrashReportingEnabled, bool> {
  /// The "Send crash diagnostics" toggle. Crash reporting (Sentry) is **opt-out**:
  /// default **on**, so the app keeps crash visibility for the launch, but users
  /// can disable it in Settings. Because Sentry installs its native crash handler
  /// at startup and a clean runtime re-init isn't supported, the toggle only takes
  /// effect on the **next app launch** — `main.dart` reads [kCrashReportingPrefKey]
  /// before `SentryFlutter.init`. The settings UI surfaces a "takes effect after
  /// restart" note. See `docs/legal/privacy-policy.md`.
  CrashReportingEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crashReportingEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crashReportingEnabledHash();

  @$internal
  @override
  CrashReportingEnabled create() => CrashReportingEnabled();
}

String _$crashReportingEnabledHash() =>
    r'7420385b63f1d7d81c8edaa0edd44a4163cb2ec6';

/// The "Send crash diagnostics" toggle. Crash reporting (Sentry) is **opt-out**:
/// default **on**, so the app keeps crash visibility for the launch, but users
/// can disable it in Settings. Because Sentry installs its native crash handler
/// at startup and a clean runtime re-init isn't supported, the toggle only takes
/// effect on the **next app launch** — `main.dart` reads [kCrashReportingPrefKey]
/// before `SentryFlutter.init`. The settings UI surfaces a "takes effect after
/// restart" note. See `docs/legal/privacy-policy.md`.

abstract class _$CrashReportingEnabled extends $AsyncNotifier<bool> {
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
