import 'package:dart_lodge/features/achievements/domain/achievement.dart';

/// The evaluated state of one [Achievement] for a player (#521/#523).
///
/// Carries both the unlock flag and the raw [current]/[target] so the UI can
/// render live progress for counters (and a yes/no badge for binaries) from the
/// same model.
class AchievementStatus {
  const AchievementStatus({
    required this.achievement,
    required this.current,
    required this.target,
    required this.unlocked,
  });

  final Achievement achievement;
  final int current;
  final int target;
  final bool unlocked;

  /// Progress in [0, 1] toward [target]. Falls back to the unlock flag when
  /// [target] is non-positive (defensive — registry targets are always ≥ 1).
  double get progress => target <= 0
      ? (unlocked ? 1.0 : 0.0)
      : (current / target).clamp(0.0, 1.0);
}
