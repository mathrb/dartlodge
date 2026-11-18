import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the CLAUDE.md rule "Call ref.read() inside a widget's build()
/// method" (Things You Must Not Do).
///
/// A `final x = ref.read(...)` statement whose closest enclosing block is a
/// `build(` method or a builder-style closure (`data:`, `builder:`) runs on
/// every rebuild, so it is flagged. The same read inside an event handler
/// (`onPressed: () { ... }`, a private method) is allowed: that is where
/// CLAUDE.md wants `ref.read`.
///
/// This is a line-based scan, not a parser: it relies on the repo's
/// one-statement-per-line formatting and on indentation to find the
/// enclosing block.
void main() {
  final buildOpener = RegExp(r'\bWidget build\(');
  final builderOpener = RegExp(r'\b(data|builder):\s*\(');
  final readAssignment = RegExp(r'^\s*final \w+ = ref\s*\.read\(');

  int indentOf(String line) => line.length - line.trimLeft().length;

  List<String> offendersIn(String path, List<String> lines) {
    final offenders = <String>[];
    for (var i = 0; i < lines.length; i++) {
      if (!readAssignment.hasMatch(lines[i])) continue;
      final indent = indentOf(lines[i]);
      // Walk up to the nearest non-blank line with a smaller indent: the
      // line that opened the enclosing block.
      for (var j = i - 1; j >= 0; j--) {
        final candidate = lines[j];
        if (candidate.trim().isEmpty) continue;
        if (indentOf(candidate) >= indent) continue;
        if (buildOpener.hasMatch(candidate) ||
            builderOpener.hasMatch(candidate)) {
          offenders.add('$path:${i + 1}: ${lines[i].trim()}');
        }
        break;
      }
    }
    return offenders;
  }

  test('no widget build() or builder closure assigns a ref.read()', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (!entity.path.contains('/presentation/')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      offenders.addAll(offendersIn(entity.path, entity.readAsLinesSync()));
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Use ref.watch() in build(); call ref.read(x.notifier) inside '
          'the callback that needs it (CLAUDE.md, Riverpod Conventions).',
    );
  });

  test('the scan flags build-time reads and allows event-handler reads', () {
    const source = '''
class A extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(fooProvider.notifier);
    return async.when(
      data: (s) {
        final other = ref.read(barProvider.notifier);
        return ElevatedButton(
          onPressed: () {
            final ok = ref.read(bazProvider.notifier);
          },
        );
      },
    );
  }

  void _onTap() {
    final fine = ref.read(fooProvider.notifier);
  }
}
''';
    final offenders = offendersIn('a.dart', source.split('\n'));
    expect(offenders, [
      'a.dart:4: final notifier = ref.read(fooProvider.notifier);',
      'a.dart:7: final other = ref.read(barProvider.notifier);',
    ]);
  });
}
