import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards that every translation ARB carries exactly the same key set as the
/// English template. Fails CI if a migration adds a key to `app_en.arb` but
/// forgets a language (or leaves a stale key behind). Grows automatically with
/// every per-feature migration sub-issue.
void main() {
  const arbDir = 'lib/l10n/arb';
  const template = 'app_en.arb';

  Set<String> keysOf(String fileName) {
    final raw = File('$arbDir/$fileName').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    // Drop metadata: @@locale and every @-prefixed description block.
    return json.keys.where((k) => !k.startsWith('@')).toSet();
  }

  test('every ARB file has the same keys as the English template', () {
    final expected = keysOf(template);
    expect(expected, isNotEmpty, reason: 'template has no message keys');

    final others = Directory(arbDir)
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.arb') && name != template)
        .toList()
      ..sort();

    expect(others, isNotEmpty, reason: 'no translation ARB files found');

    for (final name in others) {
      final keys = keysOf(name);
      expect(
        keys,
        equals(expected),
        reason: '$name key set diverges from $template '
            '(missing: ${expected.difference(keys)}; '
            'extra: ${keys.difference(expected)})',
      );
    }
  });
}
