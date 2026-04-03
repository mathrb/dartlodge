import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../domain/entities/player_stats.dart';

class CricketStatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const CricketStatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String fmtDouble(double? v, {int decimals = 2}) =>
        v != null ? v.toStringAsFixed(decimals) : '—';

    String fmtPct(double? v) =>
        v != null ? '${(v * 100).toStringAsFixed(1)}%' : '—';

    String perLeg(int total) {
      if (stats.legsPlayed == 0) return '—';
      return (total / stats.legsPlayed).toStringAsFixed(1);
    }

    final rows = <_TableRow>[
      _SectionHeader('AVERAGE', 'BEST'),
      _DataRow('MPT', fmtDouble(stats.marksPerTurn),
          fmtDouble(stats.bestLegMpt)),
      _DataRow('Hit rate', fmtPct(stats.hitRate),
          fmtPct(stats.bestGameHitRate)),
      _DataRow('Win %', '${(stats.winRate * 100).toStringAsFixed(1)}%', '—'),
      _SectionHeader('TOTAL', 'PER LEG'),
      _DataRow('6+ mark turns', stats.sixMarkTurns.toString(),
          perLeg(stats.sixMarkTurns)),
      _DataRow('9 mark turns', stats.nineMarkTurns.toString(),
          perLeg(stats.nineMarkTurns)),
    ];

    int dataRowIndex = 0;
    final children = <Widget>[];
    for (final row in rows) {
      switch (row) {
        case _SectionHeader r:
          children.add(_buildHeader(theme, colorScheme, r));
        case _DataRow r:
          final bg = dataRowIndex.isEven
              ? colorScheme.surface
              : theme.scaffoldBackgroundColor;
          dataRowIndex++;
          children.add(_buildDataRow(theme, colorScheme, r, bg));
      }
    }
    return Column(children: children);
  }

  Widget _buildHeader(
      ThemeData theme, ColorScheme colorScheme, _SectionHeader row) {
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 1.2,
    );
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          const Expanded(child: SizedBox.shrink()),
          SizedBox(
            width: 80,
            child: Text(row.col1, style: labelStyle, textAlign: TextAlign.end),
          ),
          SizedBox(
            width: 80,
            child: Text(row.col2, style: labelStyle, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
      ThemeData theme, ColorScheme colorScheme, _DataRow row, Color bg) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              row.col1,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              row.col2,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

sealed class _TableRow {}

class _SectionHeader extends _TableRow {
  final String col1;
  final String col2;
  _SectionHeader(this.col1, this.col2);
}

class _DataRow extends _TableRow {
  final String label;
  final String col1;
  final String col2;
  _DataRow(this.label, this.col1, this.col2);
}
