import 'package:dart_lodge/features/auto_scorer/domain/framing/rotation_auto_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RotationAutoDetector', () {
    test('locks the rotation that yields all 4 cals after the stable window', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      expect(d.update({0: 0, 1: 4, 2: 0, 3: 0}), isNull); // tick 1
      expect(d.update({0: 1, 1: 4, 2: 0, 3: 0}), 1); // tick 2 → locked
      expect(d.locked, 1);
    });

    test('stays locked once locked, ignoring later observations', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      d.update({1: 4});
      d.update({1: 4}); // locked at 1
      expect(d.update({0: 4, 1: 0, 2: 0, 3: 0}), 1); // still 1
    });

    test('a rotation below requiredCals never locks', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      expect(d.update({0: 3, 1: 3, 2: 3, 3: 3}), isNull);
      expect(d.update({0: 3, 1: 3, 2: 3, 3: 3}), isNull);
      expect(d.locked, isNull);
    });

    test('switching best rotation resets the streak', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      d.update({1: 4}); // streak: rot1 = 1
      d.update({2: 4}); // best switched to rot2 → streak resets to 1, no lock
      expect(d.locked, isNull);
      expect(d.update({2: 4}), 2); // rot2 second consecutive → locks
    });

    test('ties prefer the lower rotation (0 = no rotation)', () {
      final d = RotationAutoDetector(requiredStableTicks: 1);
      // 0 and 2 both have 4; strict-greater keeps 0.
      expect(d.update({0: 4, 1: 0, 2: 4, 3: 0}), 0);
    });

    test('a dropout (no eligible rotation) resets the streak', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      d.update({1: 4}); // streak 1
      d.update({0: 0, 1: 2, 2: 0, 3: 0}); // none ≥4 → reset
      expect(d.locked, isNull);
      d.update({1: 4}); // streak 1 again
      expect(d.update({1: 4}), 1); // now locks
    });
  });
}
