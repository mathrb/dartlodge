import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CaptureMeta meta(int day, int size,
          {bool corrected = false, int dart = 1}) =>
      CaptureMeta(
        gameId: 'g',
        handle: CaptureHandle(turnOrdinal: day, dartInTurnOrdinal: dart),
        sizeBytes: size,
        timestamp: DateTime.utc(2026, 6, day),
        wasCorrected: corrected,
      );

  test('returns nothing when within budget', () {
    const policy = RetentionPolicy(maxBytes: 1000);
    expect(policy.selectForPruning([meta(1, 400), meta(2, 400)]), isEmpty);
  });

  test('prunes oldest un-corrected captures first until under cap', () {
    const policy = RetentionPolicy(maxBytes: 1000);
    final all = [
      meta(1, 500), // oldest
      meta(2, 500),
      meta(3, 500), // newest
    ];
    final pruned = policy.selectForPruning(all);
    expect(pruned, hasLength(1));
    expect(pruned.single.timestamp, DateTime.utc(2026, 6, 1));
  });

  test('protects corrected captures, pruning un-corrected even if newer', () {
    const policy = RetentionPolicy(maxBytes: 1000);
    final all = [
      meta(1, 600, corrected: true), // valuable, oldest — must survive
      meta(2, 600), // un-corrected, newer — pruned first
    ];
    final pruned = policy.selectForPruning(all);
    expect(pruned, hasLength(1));
    expect(pruned.single.wasCorrected, isFalse);
  });

  test('falls back to pruning corrected captures only as a last resort', () {
    const policy = RetentionPolicy(maxBytes: 700);
    final all = [
      meta(1, 500, corrected: true), // oldest corrected → first to go
      meta(2, 500, corrected: true, dart: 2),
    ];
    // Total 1000 > 700; pruning the oldest corrected (500) leaves 500 ≤ 700.
    final pruned = policy.selectForPruning(all);
    expect(pruned, hasLength(1));
    expect(pruned.single.timestamp, DateTime.utc(2026, 6, 1));
  });
}
