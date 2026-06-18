import 'package:dart_lodge/features/achievements/domain/achievement.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metric.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metrics.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_status.dart';
import 'package:dart_lodge/features/achievements/domain/achievements_registry.dart';

/// Pure evaluation of achievements against a player's [AchievementMetrics]
/// (#521/#523). No Flutter / DB / randomness — fully deterministic.
///
/// An achievement unlocks when its metric value reaches its target
/// (`threshold ?? 1`). Binaries usually leave `threshold` null (unlock on first
/// occurrence) — except `big_fish`, a binary carrying an explicit 170; counters
/// set an explicit milestone. `hasNineDarter` (bool) reads as 0/1 so every
/// metric compares uniformly.
class AchievementEvaluator {
  const AchievementEvaluator();

  AchievementStatus evaluate(Achievement a, AchievementMetrics m) {
    final value = _read(a.metric, m);
    final target = a.threshold ?? 1;
    return AchievementStatus(
      achievement: a,
      current: value,
      target: target,
      unlocked: value >= target,
    );
  }

  /// Evaluates the whole [kAchievements] catalogue, preserving registry order.
  List<AchievementStatus> evaluateAll(AchievementMetrics m) =>
      [for (final a in kAchievements) evaluate(a, m)];

  int _read(AchievementMetric metric, AchievementMetrics m) => switch (metric) {
        AchievementMetric.total180s => m.total180s,
        AchievementMetric.highestCheckout => m.highestCheckout,
        AchievementMetric.totalWins => m.totalWins,
        AchievementMetric.totalDartsThrown => m.totalDartsThrown,
        AchievementMetric.games501Played => m.games501Played,
        AchievementMetric.hasNineDarter => m.hasNineDarter ? 1 : 0,
      };
}
