import 'package:flutter/widgets.dart';

/// Single source of truth for the languages DartLodge ships.
///
/// Reused by `MaterialApp.supportedLocales` (wired in a later sub-issue) and
/// the language selector. `en` is the source/fallback locale.
const kSupportedLocales = [
  Locale('en'),
  Locale('fr'),
  Locale('es'),
  Locale('de'),
  Locale('pt'),
  Locale('it'),
  Locale('nl'),
];

/// Each supported language named in its own language (autonym). Intentionally
/// NOT localized — a language always lists itself the same way, whatever the
/// current UI locale. Keyed by language code; covers every [kSupportedLocales]
/// entry.
const kLanguageAutonyms = <String, String>{
  'en': 'English',
  'fr': 'Français',
  'es': 'Español',
  'de': 'Deutsch',
  'pt': 'Português',
  'it': 'Italiano',
  'nl': 'Nederlands',
};
