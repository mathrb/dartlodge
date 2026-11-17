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
        // Labels stay on one line and scale down when a segment is too
        // narrow (long locales, large system text — DESIGN_SYSTEM §13)
        // instead of wrapping "Letzte / 100".
        segments: [
          ButtonSegment(
            value: StatsTimeRange.last10,
            label: _SegmentLabel(l10n.statsRangeLast10),
          ),
          ButtonSegment(
            value: StatsTimeRange.last100,
            label: _SegmentLabel(l10n.statsRangeLast100),
          ),
          ButtonSegment(
            value: StatsTimeRange.all,
            label: _SegmentLabel(l10n.statsRangeAll),
          ),
        ],
        selected: {pageState.timeRange},
        onSelectionChanged: (selection) => notifier.setTimeRange(selection.first),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, softWrap: false),
      );
}
