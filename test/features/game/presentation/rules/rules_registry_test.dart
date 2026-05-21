import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/presentation/rules/rules_registry.dart';

void main() {
  // Every variant offered on variant_selection_page.dart must resolve here.
  // If you add a new variant row, add its slug to this list and to kGameRules.
  const expectedSlugs = [
    'x01-301',
    'x01-501',
    'x01-701',
    'x01-901',
    'cricket-standard',
    'cricket-no-score',
    'cricket-cut-throat',
    'cricket-random',
    'cricket-crazy',
    'practice-atc',
    'practice-catch40',
    'practice-bobs27',
    'practice-shanghai',
    'practice-170-checkout',
    'practice-count-up',
  ];

  group('rules registry', () {
    test('every expected slug resolves to a GameRules entry', () {
      for (final slug in expectedSlugs) {
        expect(rulesFor(slug), isNotNull, reason: 'missing rules for $slug');
      }
    });

    test('every entry has a non-empty title, tagline, and at least one section',
        () {
      for (final slug in expectedSlugs) {
        final rules = rulesFor(slug)!;
        expect(rules.title, isNotEmpty, reason: '$slug.title is empty');
        expect(rules.tagline, isNotEmpty, reason: '$slug.tagline is empty');
        expect(rules.sections, isNotEmpty,
            reason: '$slug has no sections');
        for (final section in rules.sections) {
          expect(section.heading, isNotEmpty,
              reason: '$slug section heading is empty');
          expect(section.body.isNotEmpty || section.bullets.isNotEmpty, isTrue,
              reason: '$slug "${section.heading}" has no body or bullets');
        }
      }
    });

    test('every entry has Objective and Winning sections', () {
      for (final slug in expectedSlugs) {
        final headings =
            rulesFor(slug)!.sections.map((s) => s.heading).toList();
        expect(headings, contains('Objective'),
            reason: '$slug is missing Objective');
        expect(headings, contains('Winning'),
            reason: '$slug is missing Winning');
      }
    });

    test('unknown slug returns null', () {
      expect(rulesFor('does-not-exist'), isNull);
    });
  });
}
