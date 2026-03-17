import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/statistics_provider.dart';
import '../state/player_stats_page_state.dart';

class CricketVariantChipSelectorWidget extends ConsumerWidget {
  final String playerId;

  const CricketVariantChipSelectorWidget({super.key, required this.playerId});

  static String _displayLabel(String variant) {
    return switch (variant) {
      'standard' => 'Standard',
      'noScore' => 'No Score',
      'cutThroat' => 'Cut-Throat',
      'tactics' => 'Tactics',
      _ => variant,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);
    final asyncVariants = ref.watch(playerCricketVariantsProvider(playerId));

    // Only show on cricket tab
    if (pageState.activeTab != StatsTabIndex.cricket) return const SizedBox.shrink();

    return asyncVariants.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (variants) {
        if (variants.isEmpty) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Cricket'),
                selected: pageState.selectedCricketVariant == null,
                selectedColor: cs.primaryContainer,
                checkmarkColor: cs.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: pageState.selectedCricketVariant == null
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
                backgroundColor: cs.surfaceContainerHighest,
                onSelected: (_) => notifier.setCricketVariant(null),
              ),
              const SizedBox(width: 8),
              ...variants.map((variant) {
                final isSelected = pageState.selectedCricketVariant == variant;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_displayLabel(variant)),
                    selected: isSelected,
                    selectedColor: cs.primaryContainer,
                    checkmarkColor: cs.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    ),
                    backgroundColor: cs.surfaceContainerHighest,
                    onSelected: (_) => notifier.setCricketVariant(
                      isSelected ? null : variant,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
