import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dart_lodge/features/settings/presentation/providers/crash_reporting_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() => ProviderContainer();

  group('CrashReportingEnabled.build()', () {
    test('defaults to true (opt-out) when nothing stored', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(await container.read(crashReportingEnabledProvider.future), isTrue);
    });

    test('reads a stored false', () async {
      SharedPreferences.setMockInitialValues({kCrashReportingPrefKey: false});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(crashReportingEnabledProvider.future),
        isFalse,
      );
    });
  });

  group('CrashReportingEnabled.setEnabled()', () {
    test('persists false so it survives a rebuild', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(crashReportingEnabledProvider.future);
      await container
          .read(crashReportingEnabledProvider.notifier)
          .setEnabled(false);

      // The persisted key is what main.dart reads before SentryFlutter.init.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kCrashReportingPrefKey), isFalse);

      // And a fresh container re-reads it as false.
      final container2 = makeContainer();
      addTearDown(container2.dispose);
      expect(
        await container2.read(crashReportingEnabledProvider.future),
        isFalse,
      );
    });
  });
}
