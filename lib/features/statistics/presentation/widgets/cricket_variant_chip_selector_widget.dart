import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/filter_chip_row_widget.dart';
import '../providers/player_stats_page_provider.dart';
import '../state/player_stats_page_state.dart';

class CricketVariantChipSelectorWidget extends ConsumerWidget {
  final String playerId;

  const CricketVariantChipSelectorWidget({super.key, required this.playerId});

  static String _displayLabel(String variant) {
    return switch (variant) {
      'standard' => 'Standard',
      'noScore' => 'No Score',
      'cutThroat' => 'Cut-Throat',
      _ => variant,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);
    final asyncVariants = ref.watch(playerCricketVariantsProvider(playerId));

    if (pageState.activeTab != StatsTabIndex.cricket) return const SizedBox.shrink();

    return asyncVariants.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (variants) {
        if (variants.isEmpty) return const SizedBox.shrink();
        return FilterChipRowWidget<String>(
          items: variants,
          selected: pageState.selectedCricketVariant,
          labelBuilder: _displayLabel,
          onSelected: notifier.setCricketVariant,
          allLabel: 'All Cricket',
        );
      },
    );
  }
}
