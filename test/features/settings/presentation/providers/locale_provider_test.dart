import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dart_lodge/features/settings/presentation/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() => ProviderContainer();

  group('LocaleSetting.build()', () {
    test('returns null (system default) when no value stored', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(await container.read(localeSettingProvider.future), isNull);
    });

    test('returns the stored locale', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'fr'});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(localeSettingProvider.future),
        const Locale('fr'),
      );
    });
  });

  group('LocaleSetting.setLocale()', () {
    test('persists an explicit locale across a rebuild', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(localeSettingProvider.future);
      await container
          .read(localeSettingProvider.notifier)
          .setLocale(const Locale('fr'));

      final container2 = makeContainer();
      addTearDown(container2.dispose);
      expect(
        await container2.read(localeSettingProvider.future),
        const Locale('fr'),
      );
    });

    test('setLocale(null) clears the stored value (back to system)', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'fr'});
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(localeSettingProvider.future);
      await container.read(localeSettingProvider.notifier).setLocale(null);

      final container2 = makeContainer();
      addTearDown(container2.dispose);
      expect(await container2.read(localeSettingProvider.future), isNull);
    });
  });
}
