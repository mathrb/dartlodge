import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/stats_table_widget.dart';
import '../../domain/entities/player_stats.dart';

class PracticeStatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const PracticeStatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = switch (stats.gameType) {
      GameType.aroundTheClock => <StatsTableRow>[
          StatsTableHeader(l10n.statsColValue, leftLabel: l10n.statsColMetric),
          StatsTableDataRow(l10n.statsDrillsPlayed, stats.totalGames.toString()),
          StatsTableDataRow(l10n.statsCompletions, stats.atcCompletions.toString()),
          StatsTableDataRow(l10n.statsHitRate, StatFormatter.fmtPct(stats.atcHitRate)),
          StatsTableDataRow(l10n.statsAvgTurnsToComplete,
              StatFormatter.fmtDouble(stats.atcAvgTurns, decimals: 1)),
          StatsTableDataRow(
              l10n.statsBestTurnsToComplete, StatFormatter.fmtInt(stats.atcBestTurns)),
        ],
      GameType.bobs27 => <StatsTableRow>[
          StatsTableHeader(l10n.statsColValue, leftLabel: l10n.statsColMetric),
          StatsTableDataRow(l10n.statsDrillsPlayed, stats.totalGames.toString()),
          StatsTableDataRow(l10n.statsAvgScore,
              StatFormatter.fmtDouble(stats.bobs27AvgScore, decimals: 1)),
          StatsTableDataRow(l10n.statsBestScore, StatFormatter.fmtInt(stats.bobs27BestScore)),
          StatsTableDataRow(
              l10n.statsCompletionRate, StatFormatter.fmtPct(stats.bobs27CompletionRate)),
          StatsTableDataRow(
              l10n.statsDoublesHitRate, StatFormatter.fmtPct(stats.bobs27DoubleHitRate)),
        ],
      GameType.shanghai => <StatsTableRow>[
          StatsTableHeader(l10n.statsColValue, leftLabel: l10n.statsColMetric),
          StatsTableDataRow(l10n.statsDrillsPlayed, stats.totalGames.toString()),
          StatsTableDataRow(l10n.statsAvgScore,
              StatFormatter.fmtDouble(stats.shanghaiAvgScore, decimals: 1)),
          StatsTableDataRow(l10n.statsBestScore, StatFormatter.fmtInt(stats.shanghaiBestScore)),
          StatsTableDataRow(l10n.statsShanghaiCount, stats.shanghaiCount.toString()),
        ],
      GameType.catch40 => <StatsTableRow>[
          StatsTableHeader(l10n.statsColValue, leftLabel: l10n.statsColMetric),
          StatsTableDataRow(l10n.statsDrillsPlayed, stats.totalGames.toString()),
          StatsTableDataRow(l10n.statsCatch40AvgScore,
              StatFormatter.fmtDouble(stats.catch40AvgScore, decimals: 1)),
          StatsTableDataRow(l10n.statsBestScore, StatFormatter.fmtInt(stats.catch40BestScore)),
          StatsTableDataRow(
              l10n.stats2DartCheckouts, stats.catch40TwoDartCheckouts.toString()),
          StatsTableDataRow(
              l10n.stats3DartCheckouts, stats.catch40ThreeDartCheckouts.toString()),
          StatsTableDataRow(
              l10n.stats46DartCheckouts, stats.catch40FourSixDartCheckouts.toString()),
          StatsTableDataRow(l10n.statsFailed, stats.catch40FailedCheckouts.toString()),
        ],
      GameType.checkoutPractice => <StatsTableRow>[
          StatsTableHeader(l10n.statsColValue, leftLabel: l10n.statsColMetric),
          StatsTableDataRow(l10n.statsTotalAttempts, stats.checkoutAttempts.toString()),
          StatsTableDataRow(l10n.statsTotalSuccesses, stats.checkoutSuccesses.toString()),
          StatsTableDataRow(
              l10n.statsSuccessRate, StatFormatter.fmtPct(stats.checkoutSuccessRate)),
        ],
      _ => <StatsTableRow>[],
    };

    return StatsTableWidget(rows: rows, valueColumnWidth: 100);
  }
}
