import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/players/domain/validators.dart';

void main() {
  group('validatePlayerName', () {
    test('returns error for empty string', () {
      expect(validatePlayerName(''), 'Name cannot be empty');
    });

    test('returns error for name exceeding 30 characters', () {
      expect(
        validatePlayerName('a' * 31),
        'Name must be 30 characters or fewer',
      );
    });

    test('returns null for exactly 30 characters', () {
      expect(validatePlayerName('a' * 30), isNull);
    });

    test('returns null for a normal name', () {
      expect(validatePlayerName('Alice'), isNull);
    });

    test('returns null for whitespace-only (trimming is caller responsibility)', () {
      expect(validatePlayerName('   '), isNull);
    });
  });
}
