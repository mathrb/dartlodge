import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../glossary/stat_term.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_theme.dart';
import 'glossary_term_label.dart';
import 'text_measurer.dart';

/// Minimum comfortable width per breakdown column (category + each player).
/// Below this the columns would be cramped, so the table falls back to a
/// horizontal scroll instead of flexing to fill the width (#693).
const double _kMinBreakdownColWidth = 92.0;

/// One column header in [PostGameStatsBreakdown]. A column has a primary
/// name (e.g. competitor name in multi-player games, or `Total score`/`Round`
/// for solo drills) and an optional smaller subtitle (e.g. `WINNER`).
class PostGameBreakdownColumn {
  const PostGameBreakdownColumn({
    required this.name,
    this.subtitle,
    this.emphasize = false,
  });

  final String name;
  final String? subtitle;

  /// Renders both the column name and any matching row highlights in the
  /// table's accent color.
  final bool emphasize;
}

/// One row in [PostGameStatsBreakdown]. [values] and [highlights] must have
/// the same length as the table's `columns`.
class PostGameBreakdownRow {
  const PostGameBreakdownRow({
    required this.category,
    required this.values,
    required this.highlights,
    this.term,
  });

  final String category;
  final List<String> values;
  final List<bool> highlights;

  /// When set, [category] renders as a tappable glossary term (info glyph +
  /// definition dialog) instead of plain text (#719).
  final StatTerm? term;
}

/// Reusable "STATISTICS BREAKDOWN" table shell — section title with a short
/// accent rule on the left, plus a rounded container wrapping a horizontally
/// scrollable Table. Extracted from `GameSummarySectionWidget`'s former
/// private `_StatsBreakdownSection` so Shanghai (and future game types) can
/// reuse the chrome (#230).
class PostGameStatsBreakdown extends StatelessWidget {
  const PostGameStatsBreakdown({
    super.key,
    required this.columns,
    required this.rows,
    this.title,
    this.categoryHeader,
    this.showHeader = true,
  });

  /// When false, only the bordered table is rendered — the accent-rule section
  /// title is dropped. Used when the table is embedded under an existing
  /// heading (e.g. one breakdown per leg in the history leg breakdown), where
  /// repeating "STATISTICS BREAKDOWN" above every leg would be redundant.
  final bool showHeader;

  /// Defaults to the localized "Statistics Breakdown" (upper-cased) when null.
  final String? title;

  /// Defaults to the localized "Category" (upper-cased) when null.
  final String? categoryHeader;
  final List<PostGameBreakdownColumn> columns;
  final List<PostGameBreakdownRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final resolvedTitle = title ?? l10n.statisticsBreakdown.toUpperCase();
    final resolvedCategoryHeader =
        categoryHeader ?? l10n.historyCategory.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          PostGameSectionLabel(resolvedTitle),
          const SizedBox(height: 16),
        ],
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: cs.outlineVariant
                  .withValues(alpha: AppTheme.opacityGhostBorderLight),
            ),
          ),
          // Fill the available width with flex columns whenever the table fits
          // — an intrinsic-width table left a large empty band on its right
          // (#334 desktop, #693 phone with few players). It "fits" on a wide
          // viewport (~desktop) or whenever the column count needs no more than
          // the available width (the common 1–3 player case on a phone). Only a
          // genuinely too-wide table (many players) keeps the horizontal-scroll
          // fallback so columns never get cramped (this widget's scroll
          // fallback dates to #334/#241).
          child: LayoutBuilder(
            builder: (context, constraints) {
              // +1 for the leading category column.
              final minWidth = (columns.length + 1) * _kMinBreakdownColWidth;
              final fillsWidth =
                  constraints.maxWidth >= 600 || minWidth <= constraints.maxWidth;
              if (!fillsWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _BreakdownTable(
                    columns: columns,
                    rows: rows,
                    categoryHeader: resolvedCategoryHeader,
                    columnFloors: null,
                  ),
                );
              }
              // Flex columns only while every column keeps room for its
              // content at the ambient text scale: the widest word of each
              // label and name, and each value whole. Otherwise (large system
              // text, long names, longer locales) the cells would break words
              // mid-way or ellipsize, so each category stacks its values
              // instead (DESIGN_SYSTEM §13).
              final floors = _BreakdownTable.measureFloors(
                context,
                columns: columns,
                rows: rows,
              );
              final needed = floors.fold<double>(0, (sum, w) => sum + w);
              if (needed <= constraints.maxWidth) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: _BreakdownTable(
                    columns: columns,
                    rows: rows,
                    categoryHeader: resolvedCategoryHeader,
                    columnFloors: floors,
                  ),
                );
              }
              return _StackedBreakdown(columns: columns, rows: rows);
            },
          ),
        ),
      ],
    );
  }
}

/// Section title with a short accent rule on the left, in the tracked
/// upper-case style of "— STATISTICS BREAKDOWN". Shared so the sections that
/// follow the breakdown (e.g. the history detail's leg / turn breakdowns)
/// read as the same page. [text] is rendered as given; callers upper-case it.
class PostGameSectionLabel extends StatelessWidget {
  const PostGameSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(width: 32, height: 1, color: cs.primaryFixed),
        const SizedBox(width: 12),
        // One line, scaled down when too wide: a long single-word label
        // ("STATISTIKAUFSCHLÜSSELUNG") at large text would otherwise break
        // mid-word.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const EdgeInsets _kCellPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 12,
);

/// Gap and size of the info glyph a [GlossaryTermLabel] adds after its text.
const double _kGlossaryGlyphWidth = AppSpacing.space1 + 14;

/// Text styles shared by the table, the stacked fallback and the width
/// measurement, so what is measured is what is rendered.
class _BreakdownStyles {
  _BreakdownStyles(BuildContext context)
      : cs = Theme.of(context).colorScheme,
        tt = Theme.of(context).textTheme;

  final ColorScheme cs;
  final TextTheme tt;

  TextStyle? get header => tt.labelSmall?.copyWith(
        color: cs.onSurfaceVariant,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w900,
      );

  TextStyle? get category => tt.labelSmall?.copyWith(
        color: cs.onSurfaceVariant,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      );

  TextStyle? name(bool emphasize) => tt.labelMedium?.copyWith(
        color: emphasize ? cs.primaryFixed : cs.onSurface,
        fontWeight: FontWeight.w700,
      );

  TextStyle? subtitle(bool emphasize) => tt.labelSmall?.copyWith(
        color: emphasize
            ? cs.primaryFixed.withValues(alpha: 0.7)
            : cs.onSurfaceVariant,
        letterSpacing: 1.2,
      );

  TextStyle value(bool highlight) => AppTextStyles.headlineSmall.copyWith(
        color: highlight ? cs.primaryFixed : cs.onSurface,
        fontSize: 20,
      );
}

/// A row's category label: a tappable glossary term when it has one,
/// plain text otherwise. Wraps at word boundaries.
class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.row, required this.style});

  final PostGameBreakdownRow row;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final label = row.category.toUpperCase();
    return row.term != null
        ? GlossaryTermLabel(label: label, term: row.term!, style: style)
        : Text(label, style: style);
  }
}

/// A column's name with its optional subtitle (e.g. `WINNER`) below it.
class _ColumnName extends StatelessWidget {
  const _ColumnName({required this.column, required this.styles});

  final PostGameBreakdownColumn column;
  final _BreakdownStyles styles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(column.name, style: styles.name(column.emphasize)),
        if (column.subtitle != null)
          Text(column.subtitle!, style: styles.subtitle(column.emphasize)),
      ],
    );
  }
}

class _BreakdownTable extends StatelessWidget {
  const _BreakdownTable({
    required this.columns,
    required this.rows,
    required this.categoryHeader,
    required this.columnFloors,
  });

  final List<PostGameBreakdownColumn> columns;
  final List<PostGameBreakdownRow> rows;
  final String categoryHeader;

  /// When set (category column first, then one per player column), each
  /// column is at least that wide and the remaining width is shared equally
  /// so the table fills its parent. When null, columns size to their content
  /// (the horizontal-scroll fallback in the parent handles overflow).
  final List<double>? columnFloors;

  /// Narrowest width (cell padding included) of each column, category column
  /// first, that holds its content at the ambient text scale without
  /// breaking a word: the widest word of each category label (whole label
  /// plus glyph for glossary terms, which render on one line) and column
  /// name, each subtitle and value whole.
  static List<double> measureFloors(
    BuildContext context, {
    required List<PostGameBreakdownColumn> columns,
    required List<PostGameBreakdownRow> rows,
  }) {
    final styles = _BreakdownStyles(context);
    final measure = TextMeasurer.of(context);
    double floor(double content) =>
        content.ceilToDouble() + _kCellPadding.horizontal;

    var category = 0.0;
    for (final row in rows) {
      final label = row.category.toUpperCase();
      final w = row.term != null
          ? measure.width(label, styles.category) + _kGlossaryGlyphWidth
          : measure.widestWord(label, styles.category);
      if (w > category) category = w;
    }

    return [
      floor(category),
      for (var i = 0; i < columns.length; i++)
        floor([
          measure.widestWord(
            columns[i].name,
            styles.name(columns[i].emphasize),
          ),
          if (columns[i].subtitle != null)
            measure.width(
              columns[i].subtitle!,
              styles.subtitle(columns[i].emphasize),
            ),
          for (final row in rows)
            measure.width(row.values[i], styles.value(row.highlights[i])),
        ].fold<double>(0, (a, b) => a > b ? a : b)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final styles = _BreakdownStyles(context);
    final cs = styles.cs;
    final floors = columnFloors;

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      columnWidths: floors == null
          ? null
          : {
              for (var i = 0; i < floors.length; i++)
                i: MaxColumnWidth(
                  FixedColumnWidth(floors[i]),
                  const FlexColumnWidth(),
                ),
            },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.08),
        ),
      ),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLarge),
            ),
          ),
          children: [
            Padding(
              padding: _kCellPadding,
              // Scale down rather than wrap: the letter-spaced upper-case
              // header broke mid-word ("CATEGOR" / "Y") in a ~95 px flex
              // cell (3 players on a phone), and longer locales are wider.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  categoryHeader,
                  style: styles.header,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
            for (final col in columns)
              Padding(
                padding: _kCellPadding,
                child: _ColumnName(column: col, styles: styles),
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              Padding(
                padding: _kCellPadding,
                child: _CategoryLabel(row: row, style: styles.category),
              ),
              for (var i = 0; i < columns.length; i++)
                Padding(
                  padding: _kCellPadding,
                  child: Text(
                    row.values[i],
                    style: styles.value(row.highlights[i]),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Fallback for when the table's columns cannot hold their content (large
/// system text, long names): one block per category, the label on its own
/// line, then one line per column with its name on the left and its value on
/// the right. The column header row is dropped; each line carries its name.
class _StackedBreakdown extends StatelessWidget {
  const _StackedBreakdown({required this.columns, required this.rows});

  final List<PostGameBreakdownColumn> columns;
  final List<PostGameBreakdownRow> rows;

  @override
  Widget build(BuildContext context) {
    final styles = _BreakdownStyles(context);
    final divider = BorderSide(
      color: styles.cs.outlineVariant.withValues(alpha: 0.08),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows.length; r++)
          Container(
            padding: _kCellPadding,
            decoration: r == 0
                ? null
                : BoxDecoration(border: Border(top: divider)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryLabel(row: rows[r], style: styles.category),
                for (var i = 0; i < columns.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space2),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ColumnName(
                            column: columns[i],
                            styles: styles,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Text(
                          rows[r].values[i],
                          style: styles.value(rows[r].highlights[i]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
