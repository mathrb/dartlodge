// Unit tests for the StatFormatter helper.
//
// The formatter underpins every numeric stats render in the app. The
// `170.0` → `'170'` trailing-zero stripping is load-bearing (it lets stat
// rows share a literal with raw int 170 in test finders — see CLAUDE.md).
// These tests guard the edge cases that drive that behaviour.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';

void main() {
  group('StatFormatter.fmtDouble', () {
    test('null returns the em-dash placeholder', () {
      expect(StatFormatter.fmtDouble(null), '—');
    });

    test('strips trailing zero (170.0 → "170")', () {
      // This is the load-bearing case called out in CLAUDE.md: stripped
      // doubles collide with int representation, so widget test finders
      // must use findsNWidgets or descendant finders.
      expect(StatFormatter.fmtDouble(170.0), '170');
    });

    test('strips multiple trailing zeros (3.10 → "3.1")', () {
      expect(StatFormatter.fmtDouble(3.10, decimals: 2), '3.1');
    });

    test('keeps significant decimal (60.5 → "60.5")', () {
      expect(StatFormatter.fmtDouble(60.5), '60.5');
    });

    test('zero is "0"', () {
      expect(StatFormatter.fmtDouble(0.0), '0');
    });

    test('negative value preserves sign', () {
      expect(StatFormatter.fmtDouble(-12.5), '-12.5');
    });

    test('very small fraction renders with the requested decimals', () {
      // At decimals=1 it rounds to '0.0' which strips to '0'.
      expect(StatFormatter.fmtDouble(0.005, decimals: 1), '0');
      // At decimals=3 it formats to '0.005'.
      expect(StatFormatter.fmtDouble(0.005, decimals: 3), '0.005');
    });

    test('decimal override honoured (decimals: 0)', () {
      expect(StatFormatter.fmtDouble(45.7, decimals: 0), '46');
    });

    test('NaN renders the literal "NaN"', () {
      // toStringAsFixed on a NaN returns 'NaN'; the helper is a thin
      // wrapper, so this codifies the platform behaviour.
      expect(StatFormatter.fmtDouble(double.nan), 'NaN');
    });

    test('positive infinity renders as "Infinity"', () {
      expect(StatFormatter.fmtDouble(double.infinity), 'Infinity');
    });

    test('negative infinity renders as "-Infinity"', () {
      expect(StatFormatter.fmtDouble(double.negativeInfinity), '-Infinity');
    });
  });

  group('StatFormatter.fmtPct', () {
    test('null returns the em-dash placeholder', () {
      expect(StatFormatter.fmtPct(null), '—');
    });

    test('ratio mode multiplies by 100 (0.5 → "50%")', () {
      expect(StatFormatter.fmtPct(0.5, decimals: 0), '50%');
    });

    test('non-ratio mode treats input as a percentage (75.0 → "75%")', () {
      expect(StatFormatter.fmtPct(75.0, isRatio: false, decimals: 0), '75%');
    });

    test('strips trailing zeros (1.0 → "100%")', () {
      expect(StatFormatter.fmtPct(1.0), '100%');
    });

    test('zero formats as "0%"', () {
      expect(StatFormatter.fmtPct(0.0), '0%');
    });

    test('decimal override is respected', () {
      expect(StatFormatter.fmtPct(0.123, decimals: 2), '12.3%');
    });

    test('negative ratio preserves sign', () {
      expect(StatFormatter.fmtPct(-0.25, decimals: 0), '-25%');
    });

    test('NaN renders as "NaN%"', () {
      expect(StatFormatter.fmtPct(double.nan), 'NaN%');
    });

    test('infinity renders with the "Infinity" literal', () {
      expect(StatFormatter.fmtPct(double.infinity), 'Infinity%');
    });

    test('preserves precision when decimals > 0 yields a non-zero fraction',
        () {
      // 0.5126 * 100 = 51.26 → rounds to 51.3 at decimals: 1.
      expect(StatFormatter.fmtPct(0.5126), '51.3%');
    });
  });

  group('StatFormatter.fmtPerLeg', () {
    test('zero legs returns the em-dash placeholder (no divide-by-zero)', () {
      expect(StatFormatter.fmtPerLeg(100, 0), '—');
    });

    test('normal case divides total by legs', () {
      expect(StatFormatter.fmtPerLeg(20, 2), '10');
    });

    test('strips trailing zero (40 / 4 = 10.0 → "10")', () {
      expect(StatFormatter.fmtPerLeg(40, 4), '10');
    });

    test('keeps single decimal when significant', () {
      // 15 / 2 = 7.5
      expect(StatFormatter.fmtPerLeg(15, 2), '7.5');
    });

    test('total = 0 with legs > 0 returns "0"', () {
      expect(StatFormatter.fmtPerLeg(0, 3), '0');
    });

    test('negative total is preserved', () {
      expect(StatFormatter.fmtPerLeg(-10, 2), '-5');
    });
  });

  group('StatFormatter.fmtInt', () {
    test('null returns the em-dash placeholder', () {
      expect(StatFormatter.fmtInt(null), '—');
    });

    test('zero formats as "0"', () {
      expect(StatFormatter.fmtInt(0), '0');
    });

    test('positive int formats as its decimal representation', () {
      expect(StatFormatter.fmtInt(170), '170');
    });

    test('negative int preserves sign', () {
      expect(StatFormatter.fmtInt(-3), '-3');
    });
  });
}
