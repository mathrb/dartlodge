import 'package:dart_lodge/features/achievements/domain/achievement.dart';

/// One newly-unlocked achievement emitted by the `AchievementWatcher` (#525),
/// consumed by the notification host (SI-6). Pure value object.
class UnlockedAchievement {
  const UnlockedAchievement({
    required this.achievement,
    required this.playerId,
    this.gameId,
  });

  final Achievement achievement;
  final String playerId;

  /// The game whose completion triggered the unlock (nullable).
  final String? gameId;
}
