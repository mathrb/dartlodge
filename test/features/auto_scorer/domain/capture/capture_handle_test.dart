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

  test('manual handle formats as t<turn>-m<seq> and round-trips', () {
    const h = CaptureHandle.manual(turnOrdinal: 3, sequence: 1);
    expect(h.key, 't3-m1');
    final parsed = CaptureHandle.parse('t3-m1');
    expect(parsed.turnOrdinal, 3);
    expect(parsed.manualSequence, 1);
    expect(parsed, h);
  });

  test('a dart handle and a manual handle are not equal', () {
    expect(
      const CaptureHandle.manual(turnOrdinal: 3, sequence: 2),
      isNot(const CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 2)),
    );
  });

  test('corrected handle formats as t<turn>-c<seq> and round-trips', () {
    const h = CaptureHandle.corrected(turnOrdinal: 3, sequence: 1);
    expect(h.key, 't3-c1');
    final parsed = CaptureHandle.parse('t3-c1');
    expect(parsed.turnOrdinal, 3);
    expect(parsed.correctedSequence, 1);
    expect(parsed.manualSequence, isNull);
    expect(parsed, h);
  });

  test('dart, manual, and corrected handles are mutually distinct', () {
    const dart = CaptureHandle(turnOrdinal: 3, dartInTurnOrdinal: 2);
    const manual = CaptureHandle.manual(turnOrdinal: 3, sequence: 2);
    const corrected = CaptureHandle.corrected(turnOrdinal: 3, sequence: 2);
    expect(manual, isNot(dart));
    expect(corrected, isNot(dart));
    expect(corrected, isNot(manual));
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
