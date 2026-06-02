import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('key formats as t<turn>-d<dart>', () {
    expect(const CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 2).key, 't3-d2');
  });

  test('parse round-trips the key', () {
    final h = CaptureHandle.parse('t12-d1');
    expect(h.turnOrdinal, 12);
    expect(h.dartInTurnOrdinal, 1);
    expect(h.key, 't12-d1');
  });

  test('parse rejects malformed keys', () {
    expect(() => CaptureHandle.parse('turn3'), throwsFormatException);
    expect(() => CaptureHandle.parse('t3'), throwsFormatException);
  });

  test('equality is by (turn, dart)', () {
    expect(
      const CaptureHandle(turnOrdinal: 1, dartInTurnOrdinal: 1),
      const CaptureHandle(turnOrdinal: 1, dartInTurnOrdinal: 1),
    );
    expect(
      const CaptureHandle(turnOrdinal: 1, dartInTurnOrdinal: 1),
      isNot(const CaptureHandle(turnOrdinal: 1, dartInTurnOrdinal: 2)),
    );
  });
}
