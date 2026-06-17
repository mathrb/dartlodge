import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../providers/player_stats_page_provider.dart';
import '../state/player_stats_page_state.dart';

class TimeRangeSelectorWidget extends ConsumerWidget {
  final String playerId;

  const TimeRangeSelectorWidget({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<StatsTimeRange>(
        segments: [
          ButtonSegment(
              value: StatsTimeRange.last10, label: Text(l10n.statsRangeLast10)),
          ButtonSegment(
              value: StatsTimeRange.last100, label: Text(l10n.statsRangeLast100)),
          ButtonSegment(value: StatsTimeRange.all, label: Text(l10n.statsRangeAll)),
        ],
        selected: {pageState.timeRange},
        onSelectionChanged: (selection) => notifier.setTimeRange(selection.first),
      ),
    );
  }
}
