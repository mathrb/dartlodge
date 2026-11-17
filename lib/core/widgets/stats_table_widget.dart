import 'package:flutter/material.dart';

import '../glossary/stat_term.dart';
import '../utils/app_spacing.dart';
import 'glossary_term_label.dart';

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
  /// Second value column (BEST / PER LEG). `null` drops the column from the
  /// row; `''` keeps the column but leaves the cell blank, for a stat that
  /// has no such value (e.g. Win % has no best).
  final String? col2;

  /// When set, [label] renders as a tappable glossary term (info glyph +
  /// definition dialog) instead of plain text (#719).
  final StatTerm? term;
  StatsTableDataRow(this.label, this.col1, [this.col2, this.term]);
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

  /// Text colour of the second (BEST) value column: `secondary` in dark;
  /// `onSurfaceVariant` in light, where `secondary` is only ~2.2:1 on the
  /// light surfaces (WCAG 1.4.3 asks for 4.5:1).
  static Color bestColumnColor(ColorScheme cs) =>
      cs.brightness == Brightness.dark ? cs.secondary : cs.onSurfaceVariant;

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
      // `vertical: 6` is off-grid (AppSpacing is 4-pt); keeping as a
      // literal until the header sizing is revisited.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: 6,
      ),
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
            child: _ValueCell(row.col1, style: labelStyle),
          ),
          if (row.col2 != null)
            SizedBox(
              width: valueColumnWidth,
              child: _ValueCell(row.col2!, style: labelStyle),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Builder(builder: (_) {
              final labelStyle =
                  theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface);
              if (row.term != null) {
                return GlossaryTermLabel(
                  label: row.label,
                  term: row.term!,
                  style: labelStyle,
                );
              }
              return Text(row.label, style: labelStyle);
            }),
          ),
          SizedBox(
            width: valueColumnWidth,
            child: _ValueCell(
              row.col1,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.primary),
            ),
          ),
          if (row.col2 != null)
            SizedBox(
              width: valueColumnWidth,
              child: row.col2!.isEmpty
                  ? null
                  : _ValueCell(
                      row.col2!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: bestColumnColor(cs),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// A value-column cell (header or value): end-aligned on one line, kept
/// [AppSpacing.space2] clear of the column before it, and scaled down rather
/// than broken or run into its neighbour when the column is too narrow (long
/// locales, large system text — DESIGN_SYSTEM §13).
class _ValueCell extends StatelessWidget {
  const _ValueCell(this.text, {required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.space2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(text, style: style, maxLines: 1, softWrap: false),
        ),
      );
}
