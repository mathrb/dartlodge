import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/models/cricket_variant_label.dart';

void main() {
  group('cricketVariantLabel', () {
    const cases = {
      ('standard', 'fixed'): 'Standard',
      ('cut-throat', 'fixed'): 'Cut Throat',
      ('no-score', 'fixed'): 'No Score',
      ('standard', 'random'): 'Random',
      ('standard', 'crazy'): 'Crazy',
      ('cut-throat', 'random'): 'Random · Cut Throat',
      ('no-score', 'crazy'): 'Crazy · No Score',
    };
    for (final MapEntry(key: (scoring, mode), value: expected)
        in cases.entries) {
      test('$scoring × $mode → "$expected"', () {
        expect(
          cricketVariantLabel(scoring: scoring, targetMode: mode),
          expected,
        );
      });
    }
  });
}
