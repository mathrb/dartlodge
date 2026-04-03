import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../domain/entities/player_stats.dart';

class StatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const StatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String fmtDouble(double? v, {int decimals = 1}) =>
        v != null ? v.toStringAsFixed(decimals) : '—';

    String fmtPct(double? v) =>
        v != null ? '${v.toStringAsFixed(1)}%' : '—';

    String fmtInt(int? v) => v != null ? v.toString() : '—';

    String perLeg(int total) {
      if (stats.legsPlayed == 0) return '—';
      return (total / stats.legsPlayed).toStringAsFixed(1);
    }

    final rows = <_TableRow>[
      _SectionHeader('AVERAGE', 'BEST'),
      _DataRow('PPR', fmtDouble(stats.threeDartAverage),
          fmtDouble(stats.bestLegPpr)),
      _DataRow('First 9 PPR', fmtDouble(stats.firstNinePpr),
          fmtDouble(stats.bestFirstNinePpr)),
      _DataRow('Checkout %', fmtPct(stats.checkoutPercentage),
          fmtPct(stats.bestGameCheckoutPercentage)),
      _DataRow(
        'Checkout points',
        fmtDouble(stats.avgCheckoutScore),
        fmtInt(stats.highestCheckout),
      ),
      _DataRow('Win %', fmtPct(stats.winRate * 100), '—'),
      _SectionHeader('TOTAL', 'PER LEG'),
      _DataRow('60+', stats.sixtyPlusTurns.toString(),
          perLeg(stats.sixtyPlusTurns)),
      _DataRow('100+', stats.oneHundredPlusTurns.toString(),
          perLeg(stats.oneHundredPlusTurns)),
      _DataRow('140+', stats.oneFortyPlusTurns.toString(),
          perLeg(stats.oneFortyPlusTurns)),
      _DataRow('180', stats.oneEightyTurns.toString(),
          perLeg(stats.oneEightyTurns)),
    ];

    int dataRowIndex = 0;
    final children = <Widget>[];
    for (final row in rows) {
      if (row is _SectionHeader) {
        children.add(_buildHeader(theme, colorScheme, row));
      } else {
        final dataRow = row as _DataRow;
        final bg = dataRowIndex.isEven
            ? colorScheme.surface
            : theme.scaffoldBackgroundColor;
        dataRowIndex++;
        children.add(_buildDataRow(theme, colorScheme, dataRow, bg));
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
            child: Text(
              row.col1,
              style: labelStyle,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              row.col2,
              style: labelStyle,
              textAlign: TextAlign.end,
            ),
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
