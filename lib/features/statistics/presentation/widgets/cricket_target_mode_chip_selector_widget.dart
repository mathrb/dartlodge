import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/app_spacing.dart';
import '../providers/player_stats_page_provider.dart';
import '../state/player_stats_page_state.dart';

/// Cricket target-mode cohort selector — Fixed / Random / Crazy.
///
/// Random and Crazy Cricket games are stored in their own stats cohorts
/// (`StatisticsRepository.getPlayerStats(cricketTargetMode: ...)`) so they
/// don't pollute Standard Cricket career numbers. Before #260 the loader
/// supported this but the Cricket tab had no UI for switching cohorts —
/// Random / Crazy games were silently invisible.
///
/// Unlike the scoring-variant chip row (which has an "All Cricket" pseudo
/// option), the cohort axis is exhaustive: every cricket game falls into
/// exactly one of the three modes. So tapping the active chip leaves it
/// selected rather than nulling it out.
class CricketTargetModeChipSelectorWidget extends ConsumerWidget {
  final String playerId;

  const CricketTargetModeChipSelectorWidget({super.key, required this.playerId});

  static const _modes = ['fixed', 'random', 'crazy'];

  static String _modeLabel(AppLocalizations l10n, String mode) => switch (mode) {
        'fixed' => l10n.statsModeFixed,
        'random' => l10n.statsModeRandom,
        'crazy' => l10n.statsModeCrazy,
        _ => mode,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);

    if (pageState.activeTab != StatsTabIndex.cricket) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final selected = pageState.selectedCricketTargetMode;

    // Wrap (multi-line) so the chip row stays visible at narrow widths
    // (412px and below) — same pattern as `FilterChipRowWidget` (#261).
    // Only 3 modes today so it usually fits on one line; Wrap is a
    // safety net for future modes / very small displays.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: [
          for (final mode in _modes)
            FilterChip(
              label: Text(_modeLabel(l10n, mode)),
              selected: selected == mode,
              selectedColor: cs.primaryContainer,
              checkmarkColor: cs.onPrimaryContainer,
              backgroundColor: cs.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: selected == mode
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant,
              ),
              onSelected: (_) => notifier.setCricketTargetMode(mode),
            ),
        ],
      ),
    );
  }
}
