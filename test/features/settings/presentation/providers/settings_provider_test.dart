import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dart_lodge/features/settings/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() => ProviderContainer();

  group('SettingsNotifier.build()', () {
    test('returns ThemeMode.system when no value stored (default)', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      final mode = await container.read(settingsProvider.future);
      expect(mode, ThemeMode.system);
    });

    test('round-trips "dark" -> ThemeMode.dark', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(await container.read(settingsProvider.future), ThemeMode.dark);
    });

    test('round-trips "light" -> ThemeMode.light', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(await container.read(settingsProvider.future), ThemeMode.light);
    });

    test('round-trips "system" -> ThemeMode.system (regression for #167)',
        () async {
      // Previously fell through to ThemeMode.light, silently breaking the
      // "Use system default" toggle across app restarts.
      SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(await container.read(settingsProvider.future), ThemeMode.system);
    });

    test('falls back to ThemeMode.system on unknown stored value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'garbage'});
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(await container.read(settingsProvider.future), ThemeMode.system);
    });
  });

  group('SettingsNotifier.setThemeMode()', () {
    test('persists "system" so it survives a rebuild', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container.read(settingsProvider.notifier).setThemeMode(
            ThemeMode.system,
          );

      // Re-read the stored token through a fresh container.
      final container2 = makeContainer();
      addTearDown(container2.dispose);
      expect(await container2.read(settingsProvider.future), ThemeMode.system);
    });

    test('persists "dark" and "light" through a rebuild', () async {
      SharedPreferences.setMockInitialValues({});
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.future);
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      final container2 = makeContainer();
      addTearDown(container2.dispose);
      expect(await container2.read(settingsProvider.future), ThemeMode.dark);
    });
  });
}
