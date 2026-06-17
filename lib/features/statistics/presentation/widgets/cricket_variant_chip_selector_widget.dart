import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/filter_chip_row_widget.dart';
import '../providers/player_stats_page_provider.dart';
import '../state/player_stats_page_state.dart';

class CricketVariantChipSelectorWidget extends ConsumerWidget {
  final String playerId;

  const CricketVariantChipSelectorWidget({super.key, required this.playerId});

  static String _displayLabel(AppLocalizations l10n, String variant) {
    return switch (variant) {
      'standard' => l10n.statsScoringStandard,
      'noScore' => l10n.statsScoringNoScore,
      'cutThroat' => l10n.statsScoringCutThroat,
      _ => variant,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);
    final asyncVariants = ref.watch(playerCricketVariantsProvider(playerId));
    final l10n = AppLocalizations.of(context);

    if (pageState.activeTab != StatsTabIndex.cricket) return const SizedBox.shrink();

    return asyncVariants.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (variants) {
        if (variants.isEmpty) return const SizedBox.shrink();
        return FilterChipRowWidget<String>(
          items: variants,
          selected: pageState.selectedCricketVariant,
          labelBuilder: (v) => _displayLabel(l10n, v),
          onSelected: notifier.setCricketVariant,
          allLabel: l10n.statsAllCricket,
        );
      },
    );
  }
}
