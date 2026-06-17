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
