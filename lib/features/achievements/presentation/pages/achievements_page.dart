import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/core/utils/app_spacing.dart';
import 'package:dart_lodge/core/widgets/app_header.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';
import 'package:dart_lodge/core/widgets/loading_spinner_widget.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_evaluator.dart';
import 'package:dart_lodge/features/achievements/domain/achievement_status.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/achievement_metrics_provider.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/unlocked_achievements_provider.dart';
import 'package:dart_lodge/features/achievements/presentation/widgets/achievement_card.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// Grid of the player's achievements (#526): unlocked (trophy + date) first,
/// then locked by proximity to threshold. Watches the metric bundle (drives the
/// grid) + the reactive unlocked-dates map (lights up unlock state).
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key, required this.playerId});

  final String playerId;

  static const _evaluator = AchievementEvaluator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final metricsAsync = ref.watch(achievementMetricsProvider(playerId));
    final unlockedAsync = ref.watch(unlockedAchievementsProvider(playerId));

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: AppHeader(showBack: true, onBack: () => context.pop()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space4,
                  AppSpacing.space2, AppSpacing.space4, AppSpacing.space2),
              child: Text(
                l10n.achievementsPageTitle.toUpperCase(),
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 1.2),
              ),
            ),
            Expanded(
              child: metricsAsync.when(
                loading: () => const LoadingSpinnerWidget(height: 80),
                error: (e, _) => ErrorRetryWidget(
                  message: l10n.achievementsLoadFailed(e.toString()),
                  onRetry: () =>
                      ref.invalidate(achievementMetricsProvider(playerId)),
                ),
                data: (metrics) {
                  // The unlocked-dates stream is secondary: while it loads, show
                  // the grid with everything locked; it lights up on first emit.
                  final unlocked = unlockedAsync.value ?? const {};
                  final ordered = _sorted(
                    _evaluator.evaluateAll(metrics),
                    unlocked,
                  );
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.space3,
                      crossAxisSpacing: AppSpacing.space3,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: ordered.length,
                    itemBuilder: (context, i) {
                      final s = ordered[i];
                      return AchievementCard(
                        status: s,
                        unlockedAt: unlocked[s.achievement.id],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Unlocked first (most recent first), then locked by progress descending
  /// (closest to threshold first); ties keep registry order (stable sort).
  List<AchievementStatus> _sorted(
    List<AchievementStatus> statuses,
    Map<String, DateTime> unlocked,
  ) {
    final unlockedList = <AchievementStatus>[];
    final lockedList = <AchievementStatus>[];
    for (final s in statuses) {
      (unlocked.containsKey(s.achievement.id) ? unlockedList : lockedList)
          .add(s);
    }
    unlockedList.sort((a, b) => unlocked[b.achievement.id]!
        .compareTo(unlocked[a.achievement.id]!));
    lockedList.sort((a, b) => b.progress.compareTo(a.progress));
    return [...unlockedList, ...lockedList];
  }
}
