import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/player_leg_snapshot.dart';
import '../providers/statistics_provider.dart';

class MptTrendChartWidget extends ConsumerWidget {
  final String playerId;

  const MptTrendChartWidget({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(cricketLegHistoryProvider(playerId));

    return asyncHistory.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 200,
        child: Center(child: Text('Failed to load chart: $e')),
      ),
      data: (history) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: history.length < 2
            ? Center(
                child: Text(
                  'Not enough data yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: _buildChart(context, history),
              ),
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
          'Not enough data yet',
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
                final mptStr = leg.mpt?.toStringAsFixed(2) ?? '—';
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
              color: primaryContainer.withAlpha(76),
            ),
          ),
        ],
      ),
    );
  }
}
