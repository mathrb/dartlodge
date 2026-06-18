/// Per-player metric bundle the achievements are evaluated against (#521/#523).
///
/// Pure value object. Populated by `PlayerStatsAssembler.achievementMetricsFromEvents`
/// (SI-3) by replaying the player's full cross-type history; consumed by
/// `AchievementEvaluator`. SI-2 only defines the shape.
class AchievementMetrics {
  const AchievementMetrics({
    this.total180s = 0,
    this.highestCheckout = 0,
    this.totalWins = 0,
    this.totalDartsThrown = 0,
    this.games501Played = 0,
    this.hasNineDarter = false,
  });

  final int total180s;
  final int highestCheckout;
  final int totalWins;
  final int totalDartsThrown;
  final int games501Played;
  final bool hasNineDarter;

  /// All-zero metrics — a player with no recorded history.
  static const AchievementMetrics zero = AchievementMetrics();
}
