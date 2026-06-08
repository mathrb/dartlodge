import 'package:dart_lodge/features/auto_scorer/domain/framing/rotation_auto_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RotationAutoDetector', () {
    test('locks the upright rotation after the stable window', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      expect(d.update({0: false, 1: true, 2: false, 3: false}), isNull); // 1
      expect(d.update({0: false, 1: true, 2: false, 3: false}), 1); // 2 → lock
      expect(d.locked, 1);
    });

    test('stays locked once locked, ignoring later observations', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      d.update({1: true});
      d.update({1: true}); // locked at 1
      expect(d.update({0: true, 1: false}), 1); // still 1
    });

    test('a rotation that is never upright never locks', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      expect(d.update({0: false, 1: false, 2: false, 3: false}), isNull);
      expect(d.update({0: false, 1: false, 2: false, 3: false}), isNull);
      expect(d.locked, isNull);
    });

    test('switching the upright rotation resets the streak', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      d.update({1: true}); // streak rot1 = 1
      d.update({2: true}); // switched to rot2 → streak resets to 1, no lock
      expect(d.locked, isNull);
      expect(d.update({2: true}), 2); // rot2 second consecutive → locks
    });

    test('ties prefer the lower rotation', () {
      final d = RotationAutoDetector(requiredStableTicks: 1);
      expect(d.update({0: true, 1: false, 2: true, 3: false}), 0);
    });

    test('a dropout (no upright rotation) resets the streak', () {
      final d = RotationAutoDetector(requiredStableTicks: 2);
      d.update({1: true}); // streak 1
      d.update({0: false, 1: false}); // none upright → reset
      expect(d.locked, isNull);
      d.update({1: true}); // streak 1 again
      expect(d.update({1: true}), 1); // now locks
    });
  });
}
