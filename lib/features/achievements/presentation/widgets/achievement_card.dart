import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dart_lodge/core/utils/app_spacing.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/achievements/domain/achievement.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_status.dart';
import 'package:dart_lodge/features/achievements/presentation/achievement_l10n.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// A single achievement card (#526): a trophy + title + description, plus the
/// unlock date when unlocked, or a `current/target` progress bar for a still-
/// locked counter.
class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.status,
    this.unlockedAt,
  });

  final AchievementStatus status;

  /// When the achievement was unlocked, or null if still locked.
  final DateTime? unlockedAt;

  bool get _unlocked => unlockedAt != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final a = status.achievement;

    final iconColor =
        _unlocked ? AppTheme.award(context) : cs.onSurfaceVariant;
    final titleColor = _unlocked ? cs.onSurface : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            achievementTitle(l10n, a),
            style: tt.labelLarge?.copyWith(color: titleColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            achievementDescription(l10n, a),
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space2),
          if (_unlocked)
            Text(
              l10n.achievementUnlockedOn(
                DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
                    .format(unlockedAt!),
              ),
              style: tt.labelSmall?.copyWith(color: AppTheme.award(context)),
            )
          else if (a.kind == AchievementKind.counter)
            _CounterProgress(status: status)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _CounterProgress extends StatelessWidget {
  const _CounterProgress({required this.status});

  final AchievementStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: LinearProgressIndicator(
            value: status.progress,
            minHeight: 4,
            color: cs.primaryFixed,
            backgroundColor: cs.surfaceContainerLow,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '${StatFormatter.fmtInt(status.current)} / ${StatFormatter.fmtInt(status.target)}',
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
