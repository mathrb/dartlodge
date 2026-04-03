import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_theme.dart';
import '../../domain/entities/player_leg_snapshot.dart';
import '../providers/statistics_provider.dart';
import '../state/player_stats_page_state.dart';

class PprTrendChartWidget extends ConsumerWidget {
  final String playerId;

  const PprTrendChartWidget({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(playerLegHistoryProvider(playerId));
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final notifier = ref.read(playerStatsPageProvider(playerId).notifier);

    return asyncHistory.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 200,
        child: Center(child: Text('Failed to load chart: $e')),
      ),
      data: (history) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
                    child: _buildChart(context, history, pageState),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: FilterChip(
              label: const Text('📊 Overlay: Checkout %'),
              selected: pageState.showCheckoutOverlay,
              onSelected: (_) => notifier.toggleCheckoutOverlay(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<PlayerLegSnapshot> history,
    PlayerStatsPageState pageState,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final primaryContainer = theme.colorScheme.primaryContainer;
    final secondary = theme.colorScheme.secondary;

    final pprSpots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.ppr))
        .toList();

    final coSpots = pageState.showCheckoutOverlay
        ? history
            .asMap()
            .entries
            .where((e) => e.value.checkoutPct != null)
            .map((e) => FlSpot(e.key.toDouble(), e.value.checkoutPct!))
            .toList()
        : <FlSpot>[];

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
                if (spot.barIndex == 0) {
                  final pprStr = leg.ppr.toStringAsFixed(1);
                  final coStr = pageState.showCheckoutOverlay && leg.checkoutPct != null
                      ? '\nCO: ${leg.checkoutPct!.toStringAsFixed(1)}%'
                      : '';
                  return LineTooltipItem(
                    '$pprStr PPR\n$dateStr$coStr',
                    TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12),
                  );
                }
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)}%',
                  TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 12),
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
            spots: pprSpots,
            isCurved: true,
            color: primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: primaryContainer.withAlpha(76), // ~30%
            ),
          ),
          if (coSpots.isNotEmpty)
            LineChartBarData(
              spots: coSpots,
              isCurved: true,
              color: secondary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}
