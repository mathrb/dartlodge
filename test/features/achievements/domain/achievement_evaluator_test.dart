import 'package:dart_lodge/features/achievements/domain/achievement.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_evaluator.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metrics.dart';
import 'package:dart_lodge/features/achievements/domain/achievements_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = AchievementEvaluator();

  Achievement byId(String id) => kAchievements.firstWhere((a) => a.id == id);

  group('binary — implicit threshold 1', () {
    final firstWin = byId('first_win'); // metric totalWins, threshold null

    test('value 0 → locked, target defaults to 1', () {
      final s = evaluator.evaluate(firstWin, AchievementMetrics.zero);
      expect(s.current, 0);
      expect(s.target, 1);
      expect(s.unlocked, isFalse);
      expect(s.progress, 0.0);
    });

    test('value 1 → unlocked', () {
      final s = evaluator.evaluate(firstWin, const AchievementMetrics(totalWins: 1));
      expect(s.unlocked, isTrue);
      expect(s.progress, 1.0);
    });
  });

  group('binary with explicit threshold — big_fish (170)', () {
    final bigFish = byId('big_fish');

    test('169 → locked, progress just under 1', () {
      final s = evaluator.evaluate(
          bigFish, const AchievementMetrics(highestCheckout: 169));
      expect(s.target, 170);
      expect(s.unlocked, isFalse);
      expect(s.progress, closeTo(169 / 170, 1e-9));
    });

    test('170 → unlocked', () {
      final s = evaluator.evaluate(
          bigFish, const AchievementMetrics(highestCheckout: 170));
      expect(s.unlocked, isTrue);
      expect(s.progress, 1.0);
    });

    test('above threshold → unlocked, progress capped at 1', () {
      final s = evaluator.evaluate(
          bigFish, const AchievementMetrics(highestCheckout: 200));
      expect(s.unlocked, isTrue);
      expect(s.progress, 1.0);
    });
  });

  group('counter — wins_10 (threshold 10)', () {
    final wins10 = byId('wins_10');

    test('below threshold → locked', () {
      final s = evaluator.evaluate(wins10, const AchievementMetrics(totalWins: 9));
      expect(s.unlocked, isFalse);
      expect(s.current, 9);
      expect(s.target, 10);
      expect(s.progress, closeTo(0.9, 1e-9));
    });

    test('at threshold → unlocked', () {
      final s = evaluator.evaluate(wins10, const AchievementMetrics(totalWins: 10));
      expect(s.unlocked, isTrue);
    });

    test('above threshold → unlocked', () {
      final s = evaluator.evaluate(wins10, const AchievementMetrics(totalWins: 12));
      expect(s.unlocked, isTrue);
      expect(s.progress, 1.0);
    });
  });

  group('bool metric — hasNineDarter', () {
    final nineDarter = byId('nine_darter');

    test('false → 0 → locked', () {
      final s = evaluator.evaluate(nineDarter, AchievementMetrics.zero);
      expect(s.current, 0);
      expect(s.unlocked, isFalse);
    });

    test('true → 1 → unlocked', () {
      final s = evaluator.evaluate(
          nineDarter, const AchievementMetrics(hasNineDarter: true));
      expect(s.current, 1);
      expect(s.unlocked, isTrue);
    });
  });

  group('evaluateAll', () {
    test('returns one status per catalogue entry, none unlocked at zero', () {
      final all = evaluator.evaluateAll(AchievementMetrics.zero);
      expect(all, hasLength(kAchievements.length));
      expect(all.where((s) => s.unlocked), isEmpty);
    });

    test('unlocks the matching tiers for a rich metric set', () {
      final all = evaluator.evaluateAll(const AchievementMetrics(
        total180s: 12, // first_180 + count_180_10, not _50/_100
        totalWins: 1, // first_win only
        totalDartsThrown: 1500, // darts_1000 only
      ));
      final unlocked = {for (final s in all.where((s) => s.unlocked)) s.achievement.id};
      expect(unlocked, {'first_180', 'count_180_10', 'first_win', 'darts_1000'});
    });
  });
}
