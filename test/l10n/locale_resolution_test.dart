import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/l10n/locale_resolution.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  group('resolveAppLocale', () {
    test('falls back to English for an unsupported device locale', () {
      expect(
        resolveAppLocale(const Locale('ja'), kSupportedLocales),
        const Locale('en'),
      );
    });

    test('returns a supported locale that matches by language code', () {
      expect(
        resolveAppLocale(const Locale('fr'), kSupportedLocales),
        const Locale('fr'),
      );
    });

    test('falls back to English when no locale is preferred', () {
      expect(
        resolveAppLocale(null, kSupportedLocales),
        const Locale('en'),
      );
    });

    test('matches by language code, ignoring the country subtag', () {
      expect(
        resolveAppLocale(const Locale('fr', 'CA'), kSupportedLocales),
        const Locale('fr'),
      );
    });
  });
}
