import 'package:dart_lodge/features/auto_scorer/domain/framing/aim_escalation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool explain(Duration without,
          {bool recognised = false, bool keepAiming = false}) =>
      shouldExplainAim(
        withoutRecognition: without,
        recognisedNow: recognised,
        keepAimingChosen: keepAiming,
      );

  test('stays quiet while the player is still plausibly aiming', () {
    expect(explain(Duration.zero), isFalse);
    expect(explain(const Duration(seconds: 9)), isFalse);
  });

  test('explains once the wait passes the threshold', () {
    expect(explain(kAimExplainAfter), isTrue);
    expect(explain(const Duration(seconds: 30)), isTrue);
  });

  test('a successful recognition takes it away immediately', () {
    expect(explain(const Duration(minutes: 5), recognised: true), isFalse);
  });

  test('"keep aiming" holds it back', () {
    expect(explain(const Duration(minutes: 5), keepAiming: true), isFalse);
  });

  test('the threshold is configurable for a caller with its own timing', () {
    expect(
      shouldExplainAim(
        withoutRecognition: const Duration(seconds: 3),
        recognisedNow: false,
        keepAimingChosen: false,
        after: const Duration(seconds: 2),
      ),
      isTrue,
    );
  });
}
