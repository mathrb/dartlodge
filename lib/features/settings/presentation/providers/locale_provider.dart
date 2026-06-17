import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/persistence/database_provider.dart';

part 'locale_provider.g.dart';

const _kLocaleKey = 'app_locale';

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
@Riverpod(keepAlive: true)
class LocaleSetting extends _$LocaleSetting {
  @override
  Future<Locale?> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final code = prefs.getString(_kLocaleKey);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (locale == null) {
      await prefs.remove(_kLocaleKey); // back to system default
    } else {
      await prefs.setString(_kLocaleKey, locale.languageCode);
    }
    state = AsyncData(locale);
  }
}
