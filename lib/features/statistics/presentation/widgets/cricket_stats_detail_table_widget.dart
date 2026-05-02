import 'package:flutter/material.dart';

import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/stats_table_widget.dart';
import '../../domain/entities/player_stats.dart';

class CricketStatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const CricketStatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = <StatsTableRow>[
      StatsTableHeader('AVERAGE', col2: 'BEST'),
      StatsTableDataRow('MPR',
          StatFormatter.fmtDouble(stats.marksPerTurn, decimals: 2),
          StatFormatter.fmtDouble(stats.bestLegMpt, decimals: 2)),
      StatsTableDataRow('Hit rate',
          StatFormatter.fmtPct(stats.hitRate),
          StatFormatter.fmtPct(stats.bestGameHitRate)),
      StatsTableDataRow('Win %', StatFormatter.fmtPct(stats.winRate), '—'),
      StatsTableHeader('TOTAL', col2: 'PER LEG'),
      StatsTableDataRow('6+ mark turns', stats.sixMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.sixMarkTurns, stats.legsPlayed)),
      StatsTableDataRow('9 mark turns', stats.nineMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.nineMarkTurns, stats.legsPlayed)),
    ];

    return StatsTableWidget(rows: rows);
  }
}
