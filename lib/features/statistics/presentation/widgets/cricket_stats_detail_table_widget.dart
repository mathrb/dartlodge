import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/stats_table_widget.dart';
import '../../domain/entities/player_stats.dart';

class CricketStatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const CricketStatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <StatsTableRow>[
      StatsTableHeader(l10n.statsColAverage, col2: l10n.statsColBest),
      StatsTableDataRow('MPR',
          StatFormatter.fmtDouble(stats.marksPerTurn, decimals: 2),
          StatFormatter.fmtDouble(stats.bestLegMpt, decimals: 2)),
      StatsTableDataRow(l10n.statFirst9Mpr,
          StatFormatter.fmtDouble(stats.firstNineMpr, decimals: 2),
          '—'),
      StatsTableDataRow(l10n.statsHitRate,
          StatFormatter.fmtPct(stats.hitRate),
          StatFormatter.fmtPct(stats.bestGameHitRate)),
      StatsTableDataRow(l10n.statsWinPct, StatFormatter.fmtPct(stats.winRate), '—'),
      StatsTableHeader(l10n.statsColTotal, col2: l10n.statsColPerLeg),
      // Mark-turn buckets are ≥-N counts here (career view); per-game
      // stats surface exact-N counts via the same fields — see CLAUDE.md
      // "Cricket mark-bucket field overload" (#286).
      StatsTableDataRow(l10n.stats5PlusMarkTurns, stats.fiveMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.fiveMarkTurns, stats.legsPlayed)),
      StatsTableDataRow(l10n.stats6PlusMarkTurns, stats.sixMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.sixMarkTurns, stats.legsPlayed)),
      StatsTableDataRow(l10n.stats7PlusMarkTurns, stats.sevenMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.sevenMarkTurns, stats.legsPlayed)),
      StatsTableDataRow(l10n.stats8PlusMarkTurns, stats.eightMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.eightMarkTurns, stats.legsPlayed)),
      // `nineMarkTurns` is a ≥-9 counter (matches the 5+/6+/7+/8+ rows
      // above) — labelled "9+" for consistency, even though 9 is the
      // practical max marks-per-turn cap.
      StatsTableDataRow(l10n.stats9PlusMarkTurns, stats.nineMarkTurns.toString(),
          StatFormatter.fmtPerLeg(stats.nineMarkTurns, stats.legsPlayed)),
    ];

    return StatsTableWidget(rows: rows);
  }
}
