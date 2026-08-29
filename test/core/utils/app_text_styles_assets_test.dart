// Guards the invariant behind Sentry MY-DARTS-N: every Google Fonts variant
// AppTextStyles asks for must be bundled under assets/fonts/google_fonts/.
//
// main.dart sets `GoogleFonts.config.allowRuntimeFetching = false`, so a
// variant with no matching asset does not silently fall back — google_fonts
// throws out of an unawaited future and the app reports a fatal crash. This
// test fails at review time instead, by reading the style declarations and
// the asset folder off disk.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `FontWeight.wNNN` → the Google Fonts API filename part.
/// Mirrors `_fontWeightToFilenameWeightParts` in google_fonts_variant.dart.
const Map<String, String> _weightToFilenamePart = {
  'w100': 'Thin',
  'w200': 'ExtraLight',
  'w300': 'Light',
  'w400': 'Regular',
  'w500': 'Medium',
  'w600': 'SemiBold',
  'w700': 'Bold',
  'w800': 'ExtraBold',
  'w900': 'Black',
};

/// `GoogleFonts.spaceGrotesk(...)` → the `SpaceGrotesk` filename family.
const Map<String, String> _methodToFamily = {
  'spaceGrotesk': 'SpaceGrotesk',
  'inter': 'Inter',
};

void main() {
  test('every AppTextStyles font variant is bundled as an asset', () {
    final source = File('lib/core/utils/app_text_styles.dart').readAsStringSync();
    final calls = RegExp(
      r'GoogleFonts\.(\w+)\(([^;]*?)\);',
      dotAll: true,
    ).allMatches(source);

    expect(calls, isNotEmpty, reason: 'no GoogleFonts calls found — did the file move?');

    final required = <String>{};
    for (final call in calls) {
      final method = call.group(1)!;
      final family = _methodToFamily[method];
      expect(
        family,
        isNotNull,
        reason:
            'AppTextStyles uses GoogleFonts.$method — add it to _methodToFamily '
            'and bundle its .ttf files under assets/fonts/google_fonts/.',
      );

      // No fontWeight means google_fonts defaults to w400.
      final weight =
          RegExp(r'fontWeight:\s*FontWeight\.(w\d00)').firstMatch(call.group(2)!)?.group(1) ??
          'w400';
      final part = _weightToFilenamePart[weight];
      expect(part, isNotNull, reason: 'unknown FontWeight.$weight');

      required.add('$family-$part.ttf');
    }

    final bundled = Directory('assets/fonts/google_fonts')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.ttf'))
        .toSet();

    expect(
      required.difference(bundled),
      isEmpty,
      reason:
          'AppTextStyles requests font variants that are not bundled. Download '
          'them into assets/fonts/google_fonts/ — runtime fetching is disabled, '
          'so a missing file crashes the app.',
    );
  });
}
