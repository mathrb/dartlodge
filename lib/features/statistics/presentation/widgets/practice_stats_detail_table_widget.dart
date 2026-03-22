import 'package:flutter/material.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/stats_table_widget.dart';
import '../../domain/entities/player_stats.dart';

class PracticeStatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const PracticeStatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = switch (stats.gameType) {
      GameType.aroundTheClock => <StatsTableRow>[
          StatsTableHeader('VALUE', leftLabel: 'METRIC'),
          StatsTableDataRow('Drills Played', stats.totalGames.toString()),
          StatsTableDataRow('Completions', stats.atcCompletions.toString()),
          StatsTableDataRow('Hit Rate', StatFormatter.fmtPct(stats.atcHitRate)),
          StatsTableDataRow('Avg Turns to Complete',
              StatFormatter.fmtDouble(stats.atcAvgTurns, decimals: 1)),
          StatsTableDataRow(
              'Best Turns to Complete', StatFormatter.fmtInt(stats.atcBestTurns)),
        ],
      GameType.bobs27 => <StatsTableRow>[
          StatsTableHeader('VALUE', leftLabel: 'METRIC'),
          StatsTableDataRow('Drills Played', stats.totalGames.toString()),
          StatsTableDataRow('Avg Score',
              StatFormatter.fmtDouble(stats.bobs27AvgScore, decimals: 1)),
          StatsTableDataRow('Best Score', StatFormatter.fmtInt(stats.bobs27BestScore)),
          StatsTableDataRow(
              'Completion Rate', StatFormatter.fmtPct(stats.bobs27CompletionRate)),
          StatsTableDataRow(
              'Doubles Hit Rate', StatFormatter.fmtPct(stats.bobs27DoubleHitRate)),
        ],
      GameType.shanghai => <StatsTableRow>[
          StatsTableHeader('VALUE', leftLabel: 'METRIC'),
          StatsTableDataRow('Drills Played', stats.totalGames.toString()),
          StatsTableDataRow('Avg Score',
              StatFormatter.fmtDouble(stats.shanghaiAvgScore, decimals: 1)),
          StatsTableDataRow('Best Score', StatFormatter.fmtInt(stats.shanghaiBestScore)),
          StatsTableDataRow('Shanghai Count', stats.shanghaiCount.toString()),
        ],
      GameType.catch40 => <StatsTableRow>[
          StatsTableHeader('VALUE', leftLabel: 'METRIC'),
          StatsTableDataRow('Drills Played', stats.totalGames.toString()),
          StatsTableDataRow('Avg Score (/ 120)',
              StatFormatter.fmtDouble(stats.catch40AvgScore, decimals: 1)),
          StatsTableDataRow('Best Score', StatFormatter.fmtInt(stats.catch40BestScore)),
          StatsTableDataRow(
              '2-dart checkouts', stats.catch40TwoDartCheckouts.toString()),
          StatsTableDataRow(
              '3-dart checkouts', stats.catch40ThreeDartCheckouts.toString()),
          StatsTableDataRow(
              '4–6 dart checkouts', stats.catch40FourSixDartCheckouts.toString()),
          StatsTableDataRow('Failed', stats.catch40FailedCheckouts.toString()),
        ],
      GameType.checkoutPractice => <StatsTableRow>[
          StatsTableHeader('VALUE', leftLabel: 'METRIC'),
          StatsTableDataRow('Total Attempts', stats.checkoutAttempts.toString()),
          StatsTableDataRow('Total Successes', stats.checkoutSuccesses.toString()),
          StatsTableDataRow(
              'Success Rate', StatFormatter.fmtPct(stats.checkoutSuccessRate)),
        ],
      _ => <StatsTableRow>[],
    };

    return StatsTableWidget(rows: rows, valueColumnWidth: 100);
  }
}
