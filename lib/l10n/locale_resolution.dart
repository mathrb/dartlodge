import 'package:flutter/widgets.dart';

/// Resolves the effective app locale for `MaterialApp.localeResolutionCallback`.
///
/// [preferred] is the locale Flutter hands the callback: the explicit
/// `MaterialApp.locale` when set, otherwise the device locale. It is matched by
/// language code against [supported]; when none matches (e.g. a `ja` device
/// with no Japanese ARB) it falls back to English.
Locale resolveAppLocale(Locale? preferred, Iterable<Locale> supported) {
  for (final locale in supported) {
    if (locale.languageCode == preferred?.languageCode) return locale;
  }
  return const Locale('en');
}
