import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/stats_table_widget.dart';
import '../../domain/entities/player_stats.dart';

class StatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const StatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <StatsTableRow>[
      StatsTableHeader(l10n.statsColAverage, col2: l10n.statsColBest),
      StatsTableDataRow('PPR',
          StatFormatter.fmtDouble(stats.threeDartAverage),
          StatFormatter.fmtDouble(stats.bestLegPpr)),
      StatsTableDataRow(l10n.statsFirst9Ppr,
          StatFormatter.fmtDouble(stats.firstNinePpr),
          StatFormatter.fmtDouble(stats.bestFirstNinePpr)),
      StatsTableDataRow(l10n.statsCheckoutPct,
          StatFormatter.fmtPct(stats.checkoutPercentage, isRatio: false),
          StatFormatter.fmtPct(stats.bestGameCheckoutPercentage, isRatio: false)),
      StatsTableDataRow(
        l10n.statsCheckoutPoints,
        StatFormatter.fmtDouble(stats.avgCheckoutScore),
        StatFormatter.fmtInt(stats.highestCheckout),
      ),
      StatsTableDataRow(l10n.statsWinPct, StatFormatter.fmtPct(stats.winRate), '—'),
      StatsTableHeader(l10n.statsColTotal, col2: l10n.statsColPerLeg),
      // High-score buckets are mutually exclusive (see
      // `X01HighScoreBucketsProjection`): 180 → oneEightyTurns,
      // 140–179 → oneFortyPlus, 100–139 → oneHundredPlus, 60–99 →
      // sixtyPlus. Labels match the actual range so users don't read
      // them as cumulative "100+" / "140+" (#261 fixed the 60+ → 60–99
      // ambiguity; #290 finishes the job for the higher buckets).
      StatsTableDataRow(l10n.stat6099, stats.sixtyPlusTurns.toString(),
          StatFormatter.fmtPerLeg(stats.sixtyPlusTurns, stats.legsPlayed)),
      StatsTableDataRow(l10n.stat100139, stats.oneHundredPlusTurns.toString(),
          StatFormatter.fmtPerLeg(stats.oneHundredPlusTurns, stats.legsPlayed)),
      StatsTableDataRow(l10n.stat140179, stats.oneFortyPlusTurns.toString(),
          StatFormatter.fmtPerLeg(stats.oneFortyPlusTurns, stats.legsPlayed)),
      StatsTableDataRow(l10n.stat180s, stats.oneEightyTurns.toString(),
          StatFormatter.fmtPerLeg(stats.oneEightyTurns, stats.legsPlayed)),
    ];

    return StatsTableWidget(rows: rows);
  }
}
