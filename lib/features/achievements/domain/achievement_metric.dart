/// The measurable quantity an [Achievement] unlocks against (#521/#523).
///
/// Each value names a per-player metric carried by `AchievementMetrics`. The
/// `AchievementEvaluator` reads the matching field; `hasNineDarter` (a bool) is
/// read as 0/1 so every metric compares uniformly against a threshold.
enum AchievementMetric {
  /// Count of 180-scoring turns (across all game types).
  total180s,

  /// Highest checkout achieved (X01), as a score.
  highestCheckout,

  /// Total games won (across all game types).
  totalWins,

  /// Cumulative darts thrown (across all game types).
  totalDartsThrown,

  /// Count of completed X01 games started at 501.
  games501Played,

  /// Whether the player has ever finished a 501 leg in 9 darts.
  hasNineDarter,
}
