import 'package:flutter/material.dart';

import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/stats_table_widget.dart';
import '../../domain/entities/player_stats.dart';

class StatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const StatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = <StatsTableRow>[
      StatsTableHeader('AVERAGE', col2: 'BEST'),
      StatsTableDataRow('PPR',
          StatFormatter.fmtDouble(stats.threeDartAverage),
          StatFormatter.fmtDouble(stats.bestLegPpr)),
      StatsTableDataRow('First 9 PPR',
          StatFormatter.fmtDouble(stats.firstNinePpr),
          StatFormatter.fmtDouble(stats.bestFirstNinePpr)),
      StatsTableDataRow('Checkout %',
          StatFormatter.fmtPct(stats.checkoutPercentage, isRatio: false),
          StatFormatter.fmtPct(stats.bestGameCheckoutPercentage, isRatio: false)),
      StatsTableDataRow(
        'Checkout points',
        StatFormatter.fmtDouble(stats.avgCheckoutScore),
        StatFormatter.fmtInt(stats.highestCheckout),
      ),
      StatsTableDataRow('Win %', StatFormatter.fmtPct(stats.winRate), '—'),
      StatsTableHeader('TOTAL', col2: 'PER LEG'),
      // High-score buckets are mutually exclusive (see
      // `X01HighScoreBucketsProjection`): 180 → oneEightyTurns,
      // 140–179 → oneFortyPlus, 100–139 → oneHundredPlus, 60–99 →
      // sixtyPlus. Labels match the actual range so users don't read
      // them as cumulative "100+" / "140+" (#261 fixed the 60+ → 60–99
      // ambiguity; #290 finishes the job for the higher buckets).
      StatsTableDataRow('60–99', stats.sixtyPlusTurns.toString(),
          StatFormatter.fmtPerLeg(stats.sixtyPlusTurns, stats.legsPlayed)),
      StatsTableDataRow('100–139', stats.oneHundredPlusTurns.toString(),
          StatFormatter.fmtPerLeg(stats.oneHundredPlusTurns, stats.legsPlayed)),
      StatsTableDataRow('140–179', stats.oneFortyPlusTurns.toString(),
          StatFormatter.fmtPerLeg(stats.oneFortyPlusTurns, stats.legsPlayed)),
      StatsTableDataRow('180', stats.oneEightyTurns.toString(),
          StatFormatter.fmtPerLeg(stats.oneEightyTurns, stats.legsPlayed)),
    ];

    return StatsTableWidget(rows: rows);
  }
}
