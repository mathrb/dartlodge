import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';

class CricketStatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const CricketStatsDetailTableWidget({super.key, required this.stats});

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
        'MPT',
        stats.marksPerTurn != null
            ? stats.marksPerTurn!.toStringAsFixed(2)
            : '—',
      ),
      _RowData(
        'Hit rate',
        stats.hitRate != null
            ? '${(stats.hitRate! * 100).toStringAsFixed(1)}%'
            : '—',
      ),
      _RowData(
        'Win %',
        '${(stats.winRate * 100).toStringAsFixed(1)}%',
      ),
      _RowData('6+ mark turns', perLeg(stats.sixMarkTurns)),
      _RowData('9 mark turns', perLeg(stats.nineMarkTurns)),
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
