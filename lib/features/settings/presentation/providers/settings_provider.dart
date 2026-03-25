import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/persistence/database_provider.dart';

part 'settings_provider.g.dart';

const _kThemeModeKey = 'theme_mode';

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  Future<ThemeMode> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final stored = prefs.getString(_kThemeModeKey);
    return switch (stored) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.light, // dark mode TBD per Kinetic Precision spec
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_kThemeModeKey, value);
    state = AsyncData(mode);
  }
}

@riverpod
Future<String> appVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
}
