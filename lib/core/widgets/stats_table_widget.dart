import 'package:flutter/material.dart';

sealed class StatsTableRow {}

/// Header row for a stats table.
///
/// Two-column mode (x01/cricket): `StatsTableHeader('AVERAGE', 'BEST')` — renders
/// an empty label column on the left with both value columns right-aligned.
///
/// Single-column mode (practice): `StatsTableHeader('VALUE', leftLabel: 'METRIC')`
/// — renders [leftLabel] in the expanded left column and [col1] in the single
/// right-aligned value column.
class StatsTableHeader extends StatsTableRow {
  final String col1;
  final String? col2;
  final String? leftLabel;
  StatsTableHeader(this.col1, {this.col2, this.leftLabel});
}

/// Data row for a stats table.
///
/// When [col2] is null the row renders in single-column mode (one right-aligned
/// value column). When [col2] is provided the row renders in two-column mode.
class StatsTableDataRow extends StatsTableRow {
  final String label;
  final String col1;
  final String? col2;
  StatsTableDataRow(this.label, this.col1, [this.col2]);
}

class StatsTableWidget extends StatelessWidget {
  const StatsTableWidget({
    required this.rows,
    this.valueColumnWidth = 80,
    super.key,
  });

  final List<StatsTableRow> rows;

  /// Width of each value column. Pass 80 for two-column layout, 100 for
  /// single-column layout.
  final double valueColumnWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 0.8,
    );

    int dataRowIndex = 0;
    final children = <Widget>[];

    for (final row in rows) {
      switch (row) {
        case StatsTableHeader r:
          children.add(_buildHeader(theme, cs, labelStyle, r));
        case StatsTableDataRow r:
          final bg = dataRowIndex.isEven
              ? cs.surface
              : theme.scaffoldBackgroundColor;
          dataRowIndex++;
          children.add(_buildDataRow(theme, cs, r, bg));
      }
    }

    return Column(children: children);
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme cs,
    TextStyle? labelStyle,
    StatsTableHeader row,
  ) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          if (row.leftLabel != null)
            Expanded(
              child: Text(row.leftLabel!, style: labelStyle),
            )
          else
            const Expanded(child: SizedBox.shrink()),
          SizedBox(
            width: valueColumnWidth,
            child: Text(
              row.col1,
              style: labelStyle,
              textAlign: TextAlign.end,
            ),
          ),
          if (row.col2 != null)
            SizedBox(
              width: valueColumnWidth,
              child: Text(
                row.col2!,
                style: labelStyle,
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    ThemeData theme,
    ColorScheme cs,
    StatsTableDataRow row,
    Color bg,
  ) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
          SizedBox(
            width: valueColumnWidth,
            child: Text(
              row.col1,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.primary),
              textAlign: TextAlign.end,
            ),
          ),
          if (row.col2 != null)
            SizedBox(
              width: valueColumnWidth,
              child: Text(
                row.col2!,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: cs.secondary),
                textAlign: TextAlign.end,
              ),
            ),
        ],
      ),
    );
  }
}
