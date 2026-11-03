import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/features/game/domain/models/match_format.dart';

void main() {
  group('bestOfLegs', () {
    test('first to N is best of 2N - 1', () {
      expect(bestOfLegs(1), 1);
      expect(bestOfLegs(2), 3);
      expect(bestOfLegs(3), 5);
      expect(bestOfLegs(9), 17);
    });
  });

  group('maxLegsInMatch', () {
    test('two competitors match the best-of count', () {
      for (var n = 1; n <= 9; n++) {
        expect(maxLegsInMatch(n, 2), bestOfLegs(n));
      }
    });

    test('three competitors can each win N - 1 legs before the decider', () {
      expect(maxLegsInMatch(2, 3), 4);
      expect(maxLegsInMatch(3, 3), 7);
    });

    test('a single-leg match is always one leg', () {
      expect(maxLegsInMatch(1, 4), 1);
    });

    test('a solo match is exactly the legs to win', () {
      expect(maxLegsInMatch(3, 1), 3);
    });
  });
}
