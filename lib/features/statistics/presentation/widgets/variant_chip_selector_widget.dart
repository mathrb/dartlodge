import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/statistics_provider.dart';
import '../state/player_stats_page_state.dart';

class VariantChipSelectorWidget extends ConsumerWidget {
  final String playerId;

  const VariantChipSelectorWidget({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);
    final asyncScores = ref.watch(playerX01StartingScoresProvider(playerId));

    // Only show on X01 tab
    if (pageState.activeTab != StatsTabIndex.x01) return const SizedBox.shrink();

    return asyncScores.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (scores) {
        if (scores.isEmpty) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All X01'),
                selected: pageState.selectedStartingScore == null,
                onSelected: (_) => notifier.setStartingScore(null),
              ),
              const SizedBox(width: 8),
              ...scores.map((score) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('$score'),
                      selected: pageState.selectedStartingScore == score,
                      onSelected: (_) => notifier.setStartingScore(
                        pageState.selectedStartingScore == score ? null : score,
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
