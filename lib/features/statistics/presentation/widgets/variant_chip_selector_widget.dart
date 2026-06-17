import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/filter_chip_row_widget.dart';
import '../providers/player_stats_page_provider.dart';
import '../state/player_stats_page_state.dart';

class VariantChipSelectorWidget extends ConsumerWidget {
  final String playerId;

  const VariantChipSelectorWidget({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);
    final asyncScores = ref.watch(playerX01StartingScoresProvider(playerId));

    if (pageState.activeTab != StatsTabIndex.x01) return const SizedBox.shrink();

    return asyncScores.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (scores) {
        if (scores.isEmpty) return const SizedBox.shrink();
        return FilterChipRowWidget<int>(
          items: scores,
          selected: pageState.selectedStartingScore,
          labelBuilder: (score) => '$score',
          onSelected: notifier.setStartingScore,
          allLabel: AppLocalizations.of(context).statsAllX01,
        );
      },
    );
  }
}
