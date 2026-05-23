import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../../../../core/widgets/trend_chart_shell_widget.dart';
import '../../domain/entities/player_leg_snapshot.dart';
import '../providers/player_stats_page_provider.dart';

class MptTrendChartWidget extends ConsumerWidget {
  final String playerId;

  const MptTrendChartWidget({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(cricketLegHistoryProvider(playerId));

    return asyncHistory.when(
      loading: () => const LoadingSpinnerWidget(height: 200),
      error: (e, _) => SizedBox(
        height: 200,
        child: ErrorRetryWidget(
          message: 'Failed to load chart: $e',
          onRetry: () => ref.invalidate(cricketLegHistoryProvider(playerId)),
        ),
      ),
      data: (history) => TrendChartShellWidget(
        hasEnoughData: history.length >= 2,
        child: _buildChart(context, history),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<PlayerLegSnapshot> history) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final primaryContainer = theme.colorScheme.primaryContainer;

    final mptSpots = history
        .asMap()
        .entries
        .where((e) => e.value.mpt != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.mpt!))
        .toList();

    if (mptSpots.length < 2) {
      return Center(
        child: Text(
          // Match the wording in `TrendChartShellWidget` — chart needs
          // ≥2 games to draw a line, so the previous "Not enough data
          // yet" misread as contradicting populated stats below (#287).
          'Need ≥2 games for a trend',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx < 0 || idx >= history.length) {
                  return LineTooltipItem('', const TextStyle());
                }
                final leg = history[idx];
                final dateStr = DateFormat.MMMd().format(leg.gameDate);
                final mptStr = StatFormatter.fmtDouble(leg.mpt, decimals: 2);
                return LineTooltipItem(
                  '$mptStr MPT\n$dateStr',
                  TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: mptSpots,
            isCurved: true,
            color: primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primaryContainer.withValues(alpha: AppTheme.opacityChartAreaFill),
            ),
          ),
        ],
      ),
    );
  }
}
