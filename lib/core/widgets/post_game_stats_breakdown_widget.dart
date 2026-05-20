import 'package:flutter/material.dart';

import '../utils/app_text_styles.dart';
import '../utils/app_theme.dart';

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
  });

  final String category;
  final List<String> values;
  final List<bool> highlights;
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
    this.title = 'STATISTICS BREAKDOWN',
    this.categoryHeader = 'CATEGORY',
  });

  final String title;
  final String categoryHeader;
  final List<PostGameBreakdownColumn> columns;
  final List<PostGameBreakdownRow> rows;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 1, color: cs.primaryFixed),
            const SizedBox(width: 12),
            Text(
              title,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: cs.outlineVariant
                  .withValues(alpha: AppTheme.opacityGhostBorderLight),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _BreakdownTable(
              columns: columns,
              rows: rows,
              categoryHeader: categoryHeader,
            ),
          ),
        ),
      ],
    );
  }
}

class _BreakdownTable extends StatelessWidget {
  const _BreakdownTable({
    required this.columns,
    required this.rows,
    required this.categoryHeader,
  });

  final List<PostGameBreakdownColumn> columns;
  final List<PostGameBreakdownRow> rows;
  final String categoryHeader;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final headerStyle = tt.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w900,
    );
    final categoryStyle = tt.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w700,
    );
    const cellPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
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
              padding: cellPadding,
              child: Text(categoryHeader, style: headerStyle),
            ),
            ...columns.map((col) {
              return Padding(
                padding: cellPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col.name,
                      style: tt.labelMedium?.copyWith(
                        color: col.emphasize
                            ? cs.primaryFixed
                            : cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (col.subtitle != null)
                      Text(
                        col.subtitle!,
                        style: tt.labelSmall?.copyWith(
                          color: col.emphasize
                              ? cs.primaryFixed.withValues(alpha: 0.7)
                              : cs.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
        ...rows.map((row) => TableRow(
              children: [
                Padding(
                  padding: cellPadding,
                  child: Text(
                    row.category.toUpperCase(),
                    style: categoryStyle,
                  ),
                ),
                ...List.generate(columns.length, (i) {
                  final isHighlight = row.highlights[i];
                  return Padding(
                    padding: cellPadding,
                    child: Text(
                      row.values[i],
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: isHighlight ? cs.primaryFixed : cs.onSurface,
                        fontSize: 20,
                      ),
                    ),
                  );
                }),
              ],
            )),
      ],
    );
  }
}
