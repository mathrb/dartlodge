import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/statistics_provider.dart';
import '../state/player_stats_page_state.dart';

class TimeRangeSelectorWidget extends ConsumerWidget {
  final String playerId;

  const TimeRangeSelectorWidget({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<StatsTimeRange>(
        segments: const [
          ButtonSegment(value: StatsTimeRange.last10, label: Text('Last 10')),
          ButtonSegment(value: StatsTimeRange.last100, label: Text('Last 100')),
          ButtonSegment(value: StatsTimeRange.all, label: Text('All')),
        ],
        selected: {pageState.timeRange},
        onSelectionChanged: (selection) => notifier.setTimeRange(selection.first),
      ),
    );
  }
}
