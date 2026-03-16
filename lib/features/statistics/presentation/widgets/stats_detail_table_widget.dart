import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';

class StatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const StatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String perLeg(int total) {
      if (stats.legsPlayed == 0) return '$total / —';
      final avg = (total / stats.legsPlayed).toStringAsFixed(1);
      return '$total / $avg';
    }

    final rows = [
      _RowData(
        'PPR',
        stats.threeDartAverage.toStringAsFixed(1),
      ),
      _RowData(
        'First 9 PPR',
        stats.firstNinePpr != null
            ? stats.firstNinePpr!.toStringAsFixed(1)
            : '—',
      ),
      _RowData(
        'Checkout %',
        stats.checkoutPercentage != null
            ? '${stats.checkoutPercentage!.toStringAsFixed(1)}%'
            : '—',
      ),
      _RowData(
        'Highest Checkout',
        stats.highestCheckout != null
            ? stats.highestCheckout!.toString()
            : '—',
      ),
      _RowData(
        'Win %',
        '${(stats.winRate * 100).toStringAsFixed(1)}%',
      ),
      _RowData('60+', perLeg(stats.sixtyPlusTurns)),
      _RowData('100+', perLeg(stats.oneHundredPlusTurns)),
      _RowData('140+', perLeg(stats.oneFortyPlusTurns)),
      _RowData('180', perLeg(stats.oneEightyTurns)),
    ];

    return Column(
      children: rows.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        final bg = i.isEven ? colorScheme.surface : theme.scaffoldBackgroundColor;
        return Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                row.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                row.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RowData {
  final String label;
  final String value;
  const _RowData(this.label, this.value);
}
