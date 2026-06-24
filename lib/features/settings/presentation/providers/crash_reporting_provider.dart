import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'crash_reporting_provider.g.dart';

/// SharedPreferences key for the crash-reporting opt-out. Read directly in
/// `main.dart` (before the ProviderScope exists) to decide whether to call
/// `SentryFlutter.init`, and via [CrashReportingEnabled] from the settings UI.
const kCrashReportingPrefKey = 'crash_reporting_enabled';

/// The "Send crash diagnostics" toggle. Crash reporting (Sentry) is **opt-out**:
/// default **on**, so the app keeps crash visibility for the launch, but users
/// can disable it in Settings. Because Sentry installs its native crash handler
/// at startup and a clean runtime re-init isn't supported, the toggle only takes
/// effect on the **next app launch** — `main.dart` reads [kCrashReportingPrefKey]
/// before `SentryFlutter.init`. The settings UI surfaces a "takes effect after
/// restart" note. See `docs/legal/privacy-policy.md`.
@Riverpod(keepAlive: true)
class CrashReportingEnabled extends _$CrashReportingEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(kCrashReportingPrefKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(kCrashReportingPrefKey, enabled);
    state = AsyncData(enabled);
  }
}
