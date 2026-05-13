import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../../../../core/widgets/trend_chart_shell_widget.dart';
import '../../domain/entities/player_leg_snapshot.dart';
import '../providers/statistics_provider.dart';

class PracticeTrendChartWidget extends ConsumerWidget {
  final String playerId;

  const PracticeTrendChartWidget({super.key, required this.playerId});

  static String _yLabel(GameType type) => switch (type) {
        GameType.aroundTheClock => 'Hit Rate',
        GameType.checkoutPractice => 'Success Rate',
        _ => 'Score',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(practiceDrillHistoryProvider(playerId));
    final pageState = ref.watch(playerStatsPageProvider(playerId));

    return asyncHistory.when(
      loading: () => const LoadingSpinnerWidget(height: 200),
      error: (e, _) => SizedBox(
        height: 200,
        child: ErrorRetryWidget(
          message: 'Failed to load chart: $e',
          onRetry: () =>
              ref.invalidate(practiceDrillHistoryProvider(playerId)),
        ),
      ),
      data: (history) {
        final spots = history
            .asMap()
            .entries
            .where((e) => e.value.practiceScore != null)
            .map((e) => FlSpot(e.key.toDouble(), e.value.practiceScore!))
            .toList();

        return TrendChartShellWidget(
          hasEnoughData: spots.length >= 2,
          child: _buildChart(
            context,
            spots,
            history,
            pageState.selectedPracticeGameType,
          ),
        );
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<FlSpot> spots,
    List<PlayerLegSnapshot> history,
    GameType gameType,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final primaryContainer = theme.colorScheme.primaryContainer;
    final label = _yLabel(gameType);
    final isPct = gameType == GameType.aroundTheClock ||
        gameType == GameType.checkoutPractice;

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
                final drill = history[idx];
                final dateStr = DateFormat.MMMd().format(drill.gameDate);
                final valStr = isPct
                    ? StatFormatter.fmtPct(spot.y)
                    : StatFormatter.fmtDouble(spot.y);
                return LineTooltipItem(
                  '$valStr $label\n$dateStr',
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
            spots: spots,
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
