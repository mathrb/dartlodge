import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/heatmap_dartboard_widget.dart';
import '../../../../core/widgets/heatmap_density.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../providers/dart_heatmap_provider.dart';

/// Aggregated impact heatmap section for a [PlayerStatsPage] tab (#578).
///
/// Reuses the page's existing axes — it is fed by the current [playerId]
/// (the page is already per-player) and the tab's [gameType]. No new filter UI
/// is introduced.
///
/// The heatmap is intentionally **all-time per game type**: it always queries
/// with `from`/`to` left null (global aggregate) and deliberately ignores the
/// page's leg-count [TimeRangeSelectorWidget] selection. A leg count
/// ("last 10" / "last 100") has no exact date equivalent, and the heatmap query
/// filters only by date — so any mapping would be a misleading approximation.
/// The selector still scopes the page's other stats; it simply does not apply
/// to the heatmap.
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
    // All-time per game type: from/to left null (global). The page's
    // TimeRangeSelector deliberately does not apply to the heatmap.
    final asyncPositions = ref.watch(
      dartHeatmapProvider(
        DartHeatmapFilter(
          playerId: playerId,
          gameType: gameType,
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
