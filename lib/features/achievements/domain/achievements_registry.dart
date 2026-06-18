import 'package:dart_lodge/features/achievements/domain/achievement.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_metric.dart';

/// The v1 achievement catalogue (#521/#523) — the single source of truth, à la
/// `kGameRules`. Guarded by `achievements_registry_test`. Pure domain: titles and
/// descriptions are l10n keys, resolved in the presentation layer (SI-5).
///
/// 4 binary (unlock on first occurrence; `big_fish` is the one binary with an
/// explicit threshold, 170) + 11 counter (tiered milestones sharing a metric).
const List<Achievement> kAchievements = [
  // ── Binary ────────────────────────────────────────────────────────────────
  Achievement(
    id: 'first_180',
    kind: AchievementKind.binary,
    metric: AchievementMetric.total180s,
    titleKey: 'achievementFirst180Title',
    descriptionKey: 'achievementFirst180Description',
  ),
  Achievement(
    id: 'big_fish',
    kind: AchievementKind.binary,
    metric: AchievementMetric.highestCheckout,
    threshold: 170, // a magnitude, not a count → explicit bar (see Achievement)
    titleKey: 'achievementBigFishTitle',
    descriptionKey: 'achievementBigFishDescription',
  ),
  Achievement(
    id: 'first_win',
    kind: AchievementKind.binary,
    metric: AchievementMetric.totalWins,
    titleKey: 'achievementFirstWinTitle',
    descriptionKey: 'achievementFirstWinDescription',
  ),
  Achievement(
    id: 'nine_darter',
    kind: AchievementKind.binary,
    metric: AchievementMetric.hasNineDarter,
    titleKey: 'achievementNineDarterTitle',
    descriptionKey: 'achievementNineDarterDescription',
  ),

  // ── Counter — total darts thrown ────────────────────────────────────────────
  Achievement(
    id: 'darts_1000',
    kind: AchievementKind.counter,
    metric: AchievementMetric.totalDartsThrown,
    threshold: 1000,
    titleKey: 'achievementDarts1000Title',
    descriptionKey: 'achievementDarts1000Description',
  ),
  Achievement(
    id: 'darts_10000',
    kind: AchievementKind.counter,
    metric: AchievementMetric.totalDartsThrown,
    threshold: 10000,
    titleKey: 'achievementDarts10000Title',
    descriptionKey: 'achievementDarts10000Description',
  ),
  Achievement(
    id: 'darts_50000',
    kind: AchievementKind.counter,
    metric: AchievementMetric.totalDartsThrown,
    threshold: 50000,
    titleKey: 'achievementDarts50000Title',
    descriptionKey: 'achievementDarts50000Description',
  ),

  // ── Counter — cumulative 180s ───────────────────────────────────────────────
  Achievement(
    id: 'count_180_10',
    kind: AchievementKind.counter,
    metric: AchievementMetric.total180s,
    threshold: 10,
    titleKey: 'achievementCount18010Title',
    descriptionKey: 'achievementCount18010Description',
  ),
  Achievement(
    id: 'count_180_50',
    kind: AchievementKind.counter,
    metric: AchievementMetric.total180s,
    threshold: 50,
    titleKey: 'achievementCount18050Title',
    descriptionKey: 'achievementCount18050Description',
  ),
  Achievement(
    id: 'count_180_100',
    kind: AchievementKind.counter,
    metric: AchievementMetric.total180s,
    threshold: 100,
    titleKey: 'achievementCount180100Title',
    descriptionKey: 'achievementCount180100Description',
  ),

  // ── Counter — 501 games played ──────────────────────────────────────────────
  Achievement(
    id: 'games_501_100',
    kind: AchievementKind.counter,
    metric: AchievementMetric.games501Played,
    threshold: 100,
    titleKey: 'achievementGames501100Title',
    descriptionKey: 'achievementGames501100Description',
  ),
  Achievement(
    id: 'games_501_500',
    kind: AchievementKind.counter,
    metric: AchievementMetric.games501Played,
    threshold: 500,
    titleKey: 'achievementGames501500Title',
    descriptionKey: 'achievementGames501500Description',
  ),

  // ── Counter — games won ─────────────────────────────────────────────────────
  Achievement(
    id: 'wins_10',
    kind: AchievementKind.counter,
    metric: AchievementMetric.totalWins,
    threshold: 10,
    titleKey: 'achievementWins10Title',
    descriptionKey: 'achievementWins10Description',
  ),
  Achievement(
    id: 'wins_50',
    kind: AchievementKind.counter,
    metric: AchievementMetric.totalWins,
    threshold: 50,
    titleKey: 'achievementWins50Title',
    descriptionKey: 'achievementWins50Description',
  ),
  Achievement(
    id: 'wins_100',
    kind: AchievementKind.counter,
    metric: AchievementMetric.totalWins,
    threshold: 100,
    titleKey: 'achievementWins100Title',
    descriptionKey: 'achievementWins100Description',
  ),
];
