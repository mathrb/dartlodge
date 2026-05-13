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
import '../providers/statistics_provider.dart';

class PprTrendChartWidget extends ConsumerWidget {
  final String playerId;

  const PprTrendChartWidget({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(playerLegHistoryProvider(playerId));

    return asyncHistory.when(
      loading: () => const LoadingSpinnerWidget(height: 200),
      error: (e, _) => SizedBox(
        height: 200,
        child: ErrorRetryWidget(
          message: 'Failed to load chart: $e',
          onRetry: () => ref.invalidate(playerLegHistoryProvider(playerId)),
        ),
      ),
      data: (history) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrendChartShellWidget(
            hasEnoughData: history.length >= 2,
            child: _buildChart(context, history),
          ),
          if (history.length >= 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildLegend(context),
            ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<PlayerLegSnapshot> history) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final primaryContainer = theme.colorScheme.primaryContainer;
    final secondary = theme.colorScheme.secondary;
    final axisLabelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final tickLabelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final pprSpots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.ppr))
        .toList();

    final checkoutSpots = history
        .asMap()
        .entries
        .where((e) => e.value.checkoutScore != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.checkoutScore!.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 180,
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
                if (spot.barIndex == 0) {
                  return LineTooltipItem(
                    '${StatFormatter.fmtDouble(leg.ppr)} PPR\n$dateStr',
                    TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  );
                }
                return LineTooltipItem(
                  '${spot.y.toInt()} checkout',
                  TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 60,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text('Points', style: axisLabelStyle),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              interval: 60,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                if (value != 0 && value != 60 && value != 120 && value != 180) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(value.toInt().toString(), style: tickLabelStyle),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text('Legs', style: axisLabelStyle),
            axisNameSize: 18,
            sideTitles: const SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: pprSpots,
            isCurved: true,
            color: primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primaryContainer.withValues(
                alpha: AppTheme.opacityChartAreaFill,
              ),
            ),
          ),
          LineChartBarData(
            spots: checkoutSpots,
            isCurved: false,
            color: secondary,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: secondary,
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        _LegendSwatch(color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text('PPR', style: labelStyle),
        const SizedBox(width: 16),
        _LegendSwatch(color: theme.colorScheme.secondary),
        const SizedBox(width: 6),
        Text('Checkout score', style: labelStyle),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;

  const _LegendSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
