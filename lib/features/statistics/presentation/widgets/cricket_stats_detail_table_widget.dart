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
      StatsTableDataRow('First 9 MPR',
          StatFormatter.fmtDouble(stats.firstNineMpr, decimals: 2),
          '—'),
      StatsTableDataRow('Hit rate',
          StatFormatter.fmtPct(stats.hitRate),
          StatFormatter.fmtPct(stats.bestGameHitRate)),
      StatsTableDataRow('Win %', StatFormatter.fmtPct(stats.winRate), '—'),
      StatsTableHeader('TOTAL', col2: 'PER LEG'),
      // Mark-turn buckets are ≥-N counts here (career view); per-game
      // stats surface exact-N counts via the same fields — see CLAUDE.md
      // "Cricket mark-bucket field overload" (#286).
      StatsTableDataRow('5+ mark turns', stats.fiveMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.fiveMarkTurns, stats.legsPlayed)),
      StatsTableDataRow('6+ mark turns', stats.sixMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.sixMarkTurns, stats.legsPlayed)),
      StatsTableDataRow('7+ mark turns', stats.sevenMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.sevenMarkTurns, stats.legsPlayed)),
      StatsTableDataRow('8+ mark turns', stats.eightMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.eightMarkTurns, stats.legsPlayed)),
      // `nineMarkTurns` is a ≥-9 counter (matches the 5+/6+/7+/8+ rows
      // above) — labelled "9+" for consistency, even though 9 is the
      // practical max marks-per-turn cap.
      StatsTableDataRow('9+ mark turns', stats.nineMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.nineMarkTurns, stats.legsPlayed)),
    ];

    return StatsTableWidget(rows: rows);
  }
}
