import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/heatmap_dartboard_widget.dart';
import '../../../../core/widgets/heatmap_density.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../providers/dart_heatmap_provider.dart';
import '../providers/player_stats_page_provider.dart';
import '../state/player_stats_page_state.dart';

/// Maps the page's leg-count [StatsTimeRange] to a `start_time` date window for
/// [dartHeatmapProvider] (whose only period filter is `from`/`to` on the game's
/// start time).
///
/// The stats page's time range is a *leg count* ("last 10" / "last 100" / "all"),
/// which has no exact date equivalent. The heatmap query filters by date only,
/// so the bounded ranges are approximated as recent-date windows:
///
/// - [StatsTimeRange.all]    → `(null, null)` (global aggregate — the canonical
///   "global" case from the design doc).
/// - [StatsTimeRange.last10] → darts from the last 30 days.
/// - [StatsTimeRange.last100]→ darts from the last 365 days.
///
/// `now` is injectable for deterministic tests.
({DateTime? from, DateTime? to}) statsTimeRangeToDateWindow(
  StatsTimeRange range, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  return switch (range) {
    StatsTimeRange.all => (from: null, to: null),
    StatsTimeRange.last10 => (
        from: reference.subtract(const Duration(days: 30)),
        to: null,
      ),
    StatsTimeRange.last100 => (
        from: reference.subtract(const Duration(days: 365)),
        to: null,
      ),
  };
}

/// Aggregated impact heatmap section for a [PlayerStatsPage] tab (#578).
///
/// Reuses the page's existing axes — it is fed by the current [playerId]
/// (the page is already per-player), the tab's [gameType], and the page's
/// [TimeRangeSelectorWidget] selection (mapped to a date window). No new filter
/// UI is introduced.
///
/// The whole section (title included) is hidden when no located dart positions
/// exist for the current scope (manual-only games, or games played before the
/// capture pipeline existed) so the tab does not show an empty board.
class StatsHeatmapSectionWidget extends ConsumerWidget {
  const StatsHeatmapSectionWidget({
    super.key,
    required this.playerId,
    required this.gameType,
  });

  final String playerId;

  /// The tab's game type — fixes the heatmap to this game's darts.
  final GameType gameType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeRange =
        ref.watch(playerStatsPageProvider(playerId)).timeRange;
    final window = statsTimeRangeToDateWindow(timeRange);

    final asyncPositions = ref.watch(
      dartHeatmapProvider(
        DartHeatmapFilter(
          playerId: playerId,
          gameType: gameType,
          from: window.from,
          to: window.to,
        ),
      ),
    );

    return asyncPositions.when(
      // While loading or on error, take no vertical space rather than flashing
      // chrome — the heatmap is a supplementary view, not a primary metric.
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (positions) {
        if (positions.isEmpty) return const SizedBox.shrink();

        final points = <HeatPoint>[
          for (final p in positions) (x: p.x, y: p.y),
        ];

        final l10n = AppLocalizations.of(context);
        final cs = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space4,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.statsHeatmapTitle.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: cs.primaryFixed,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: HeatmapDartboardWidget(points: points),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
