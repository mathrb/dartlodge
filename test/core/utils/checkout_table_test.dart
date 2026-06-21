import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/checkout_table.dart';

void main() {
  group('checkoutSuggestionForStrategy', () {
    group('double out', () {
      test('returns suggestion for score in range', () {
        expect(checkoutSuggestionForStrategy(170, 'double'), 'T20 · T20 · DB');
        expect(checkoutSuggestionForStrategy(100, 'double'), 'T20 · D20');
        expect(checkoutSuggestionForStrategy(50, 'double'), 'DB');
        expect(checkoutSuggestionForStrategy(2, 'double'), 'D1');
      });

      test('returns null outside range', () {
        expect(checkoutSuggestionForStrategy(1, 'double'), isNull);
        expect(checkoutSuggestionForStrategy(171, 'double'), isNull);
        expect(checkoutSuggestionForStrategy(0, 'double'), isNull);
      });
    });

    group('straight out', () {
      test('scores 1-20 use singles', () {
        expect(checkoutSuggestionForStrategy(1, 'straight'), 'S1');
        expect(checkoutSuggestionForStrategy(10, 'straight'), 'S10');
        expect(checkoutSuggestionForStrategy(20, 'straight'), 'S20');
      });

      test('score 25 is SB', () {
        expect(checkoutSuggestionForStrategy(25, 'straight'), 'SB');
      });

      test('score 50 is DB', () {
        expect(checkoutSuggestionForStrategy(50, 'straight'), 'DB');
      });

      test('score 180 is T20 · T20 · T20', () {
        expect(
          checkoutSuggestionForStrategy(180, 'straight'),
          'T20 · T20 · T20',
        );
      });

      test('2-dart routes prefer ending on singles', () {
        // Score 80: T20 + S20 (not T20 + D10 like double-out)
        expect(checkoutSuggestionForStrategy(80, 'straight'), 'T20 · S20');
        // Score 70: T20 + S10 (not T18 + D8 like double-out)
        expect(checkoutSuggestionForStrategy(70, 'straight'), 'T20 · S10');
      });

      test('returns null for score 0 and negative', () {
        expect(checkoutSuggestionForStrategy(0, 'straight'), isNull);
        expect(checkoutSuggestionForStrategy(-1, 'straight'), isNull);
      });

      test('returns null for scores above 180', () {
        expect(checkoutSuggestionForStrategy(181, 'straight'), isNull);
      });
    });

    group('master out', () {
      test('score 3 is T1 (not S1 · D1 like double-out)', () {
        expect(checkoutSuggestionForStrategy(3, 'master'), 'T1');
      });

      test('score 9 is T3', () {
        expect(checkoutSuggestionForStrategy(9, 'master'), 'T3');
      });

      test('score 15 is T5', () {
        expect(checkoutSuggestionForStrategy(15, 'master'), 'T5');
      });

      test('score 50 is DB', () {
        expect(checkoutSuggestionForStrategy(50, 'master'), 'DB');
      });

      test('score 180 is T20 · T20 · T20', () {
        expect(
          checkoutSuggestionForStrategy(180, 'master'),
          'T20 · T20 · T20',
        );
      });

      test('returns null for score 1 (no master finish possible)', () {
        expect(checkoutSuggestionForStrategy(1, 'master'), isNull);
      });

      test('returns null for scores above 180', () {
        expect(checkoutSuggestionForStrategy(181, 'master'), isNull);
      });
    });
  });

  group('maxCheckoutScore', () {
    test('double out is 170', () {
      expect(maxCheckoutScore('double'), 170);
    });

    test('straight out is 180', () {
      expect(maxCheckoutScore('straight'), 180);
    });

    test('master out is 180', () {
      expect(maxCheckoutScore('master'), 180);
    });
  });

  group('minCheckoutScore', () {
    test('double out is 2', () {
      expect(minCheckoutScore('double'), 2);
    });

    test('straight out is 1', () {
      expect(minCheckoutScore('straight'), 1);
    });

    test('master out is 2', () {
      expect(minCheckoutScore('master'), 2);
    });
  });

  group('dartsRequiredForCheckout', () {
    test('single-segment suggestion is 1 dart', () {
      expect(dartsRequiredForCheckout('D20'), 1);
      expect(dartsRequiredForCheckout('DB'), 1);
      expect(dartsRequiredForCheckout('S20'), 1);
    });

    test('two-segment suggestion is 2 darts', () {
      expect(dartsRequiredForCheckout('T20 · D20'), 2);
      expect(dartsRequiredForCheckout('T20 · DB'), 2);
    });

    test('three-segment suggestion is 3 darts', () {
      expect(dartsRequiredForCheckout('T20 · T20 · DB'), 3);
      expect(dartsRequiredForCheckout('T20 · T20 · D20'), 3);
    });

    test('matches every emitted suggestion in all three tables', () {
      // Sanity check: no suggestion in our tables requires more than 3 darts.
      for (final strategy in const ['double', 'straight', 'master']) {
        for (var score = minCheckoutScore(strategy);
            score <= maxCheckoutScore(strategy);
            score++) {
          final suggestion = checkoutSuggestionForStrategy(score, strategy);
          if (suggestion == null) continue;
          final darts = dartsRequiredForCheckout(suggestion);
          expect(darts, inInclusiveRange(1, 3),
              reason: 'strategy=$strategy score=$score suggestion="$suggestion"');
        }
      }
    });
  });

  group('isOnADoubleFinish (#635)', () {
    test('even 2..40 are single-dart double finishes', () {
      for (final r in [2, 4, 16, 32, 40]) {
        expect(isOnADoubleFinish(r), isTrue, reason: 'D${r ~/ 2} finishes $r');
      }
    });

    test('50 (DB) is a single-dart double finish', () {
      expect(isOnADoubleFinish(50), isTrue);
    });

    test('odd, >40 (non-50), and 0/1 are not single-dart double finishes', () {
      for (final r in [1, 3, 41, 42, 49, 51, 60, 100, 170, 0]) {
        expect(isOnADoubleFinish(r), isFalse, reason: '$r is not on a double');
      }
    });
  });

  group('isOnAFinish (#637 — strategy-aware single-dart finish)', () {
    test('double: only double finishes (even 2..40, 50)', () {
      for (final r in [2, 40, 50]) {
        expect(isOnAFinish(r, 'double'), isTrue, reason: '$r');
      }
      for (final r in [17, 57, 25, 1, 41]) {
        expect(isOnAFinish(r, 'double'), isFalse, reason: '$r');
      }
    });

    test('master: doubles + triples + double bull', () {
      // doubles
      expect(isOnAFinish(40, 'master'), isTrue);
      expect(isOnAFinish(50, 'master'), isTrue);
      // triples 3..60
      for (final r in [3, 27, 57, 60]) {
        expect(isOnAFinish(r, 'master'), isTrue, reason: 'T finishes $r');
      }
      // single bull (25) and plain singles are NOT master finishes
      expect(isOnAFinish(25, 'master'), isFalse);
      expect(isOnAFinish(17, 'master'), isFalse);
      expect(isOnAFinish(61, 'master'), isFalse);
    });

    test('straight: any single dart (singles, bulls, doubles, triples)', () {
      for (final r in [1, 17, 20, 25, 40, 50, 57, 60]) {
        expect(isOnAFinish(r, 'straight'), isTrue, reason: '$r');
      }
      // 23 is not reachable by any single dart; >60 never is
      for (final r in [23, 61, 100, 170]) {
        expect(isOnAFinish(r, 'straight'), isFalse, reason: '$r');
      }
    });

    test('unknown strategy falls back to double-out', () {
      expect(isOnAFinish(40, 'weird'), isTrue);
      expect(isOnAFinish(17, 'weird'), isFalse);
    });
  });
}
