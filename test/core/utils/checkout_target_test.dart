import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/checkout_target.dart';

void main() {
  group('isCheckoutableScore', () {
    test('valid double-out finishes are checkoutable', () {
      for (final v in [2, 40, 50, 100, 160, 170]) {
        expect(isCheckoutableScore(v), isTrue, reason: '$v');
      }
    });
    test('bogey numbers and out-of-range are not checkoutable', () {
      for (final v in [169, 168, 166, 165, 163, 162, 159, 1, 0, 171]) {
        expect(isCheckoutableScore(v), isFalse, reason: '$v');
      }
    });
  });

  group('checkoutTargetForRun — fixed', () {
    test('always returns the fixed target', () {
      for (final idx in [0, 1, 5, 99]) {
        expect(
          checkoutTargetForRun(
            mode: kCheckoutModeFixed,
            fixedTarget: 121,
            minTarget: 40,
            maxTarget: 170,
            step: 10,
            gameId: 'g',
            runIndex: idx,
          ),
          121,
        );
      }
    });
    test('snaps a bogey fixed target to a checkoutable value', () {
      final t = checkoutTargetForRun(
        mode: kCheckoutModeFixed,
        fixedTarget: 169, // bogey
        minTarget: 40,
        maxTarget: 170,
        step: 10,
        gameId: 'g',
        runIndex: 0,
      );
      expect(isCheckoutableScore(t), isTrue);
    });
  });

  group('checkoutTargetForRun — progressive', () {
    test('climbs by step, clamps at max, always checkoutable', () {
      int t(int idx) => checkoutTargetForRun(
            mode: kCheckoutModeProgressive,
            fixedTarget: 170,
            minTarget: 60,
            maxTarget: 170,
            step: 10,
            gameId: 'g',
            runIndex: idx,
          );
      expect(t(0), 60); // 60 is checkoutable
      expect(t(1), 70);
      // climbs and never exceeds max; sits at the top once reached
      expect(t(20) <= 170, isTrue);
      expect(t(20), greaterThanOrEqualTo(t(1)));
      for (final idx in [0, 1, 2, 3, 5, 11, 20]) {
        expect(isCheckoutableScore(t(idx)), isTrue, reason: 'run $idx');
      }
    });
  });

  group('checkoutTargetForRun — random', () {
    test('picks a checkoutable value in range and is replay-stable', () {
      int t(int idx) => checkoutTargetForRun(
            mode: kCheckoutModeRandom,
            fixedTarget: 170,
            minTarget: 40,
            maxTarget: 170,
            step: 10,
            gameId: 'game-abc',
            runIndex: idx,
          );
      for (final idx in [0, 1, 2, 7, 42]) {
        final v = t(idx);
        expect(v, inInclusiveRange(40, 170));
        expect(isCheckoutableScore(v), isTrue, reason: 'run $idx → $v');
      }
      // Deterministic: same (gameId, runIndex) → same value across calls.
      expect(t(3), t(3));
      // Different gameId generally yields a different sequence.
      final other = checkoutTargetForRun(
        mode: kCheckoutModeRandom,
        fixedTarget: 170,
        minTarget: 40,
        maxTarget: 170,
        step: 10,
        gameId: 'different-game',
        runIndex: 3,
      );
      // (Not strictly required to differ, but the seed differs.)
      expect(other, inInclusiveRange(40, 170));
    });

    test('empty checkoutable range falls back to the fixed target', () {
      // 167..168 contains only 167 (checkoutable) — pick a truly empty band.
      final t = checkoutTargetForRun(
        mode: kCheckoutModeRandom,
        fixedTarget: 100,
        minTarget: 169, // bogey
        maxTarget: 169, // bogey-only band → empty pool
        step: 10,
        gameId: 'g',
        runIndex: 0,
      );
      expect(t, 100);
    });
  });
}
