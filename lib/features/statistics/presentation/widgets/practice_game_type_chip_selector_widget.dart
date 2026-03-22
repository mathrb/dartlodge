import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/filter_chip_row_widget.dart';
import '../providers/statistics_provider.dart';
import '../state/player_stats_page_state.dart';

class PracticeGameTypeChipSelectorWidget extends ConsumerWidget {
  final String playerId;

  const PracticeGameTypeChipSelectorWidget({super.key, required this.playerId});

  static const _practiceTypes = [
    GameType.aroundTheClock,
    GameType.bobs27,
    GameType.shanghai,
    GameType.catch40,
    GameType.checkoutPractice,
  ];

  static String _label(GameType type) => switch (type) {
        GameType.aroundTheClock => 'Around the Clock',
        GameType.bobs27 => "Bob's 27",
        GameType.shanghai => 'Shanghai',
        GameType.catch40 => 'Catch-40',
        GameType.checkoutPractice => 'Checkout',
        _ => type.name,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);

    if (pageState.activeTab != StatsTabIndex.practice) return const SizedBox.shrink();

    return FilterChipRowWidget<GameType>(
      items: _practiceTypes,
      selected: pageState.selectedPracticeGameType,
      labelBuilder: _label,
      onSelected: (type) {
        if (type != null) notifier.setPracticeGameType(type);
      },
    );
  }
}
