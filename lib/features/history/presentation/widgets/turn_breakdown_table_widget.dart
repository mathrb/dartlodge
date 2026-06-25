import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/utils/name_formatter.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/history/domain/turn_breakdown.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// Renders the per-leg turn breakdown for a single leg. The column layout
/// switches based on [gameType] following the spec in issue #105.
///
/// Around-the-Clock has no per-turn rows: it shows a per-segment hit-rate
/// table instead. All other game types render one row per turn (or, for
/// Catch 40, one row per target across up to 6 darts).
class TurnBreakdownTableWidget extends StatelessWidget {
  const TurnBreakdownTableWidget({
    required this.gameType,
    required this.breakdown,
    this.singleCompetitor = false,
    super.key,
  });

  final GameType gameType;
  final LegTurnBreakdown breakdown;

  /// True when only one competitor is in the leg — competitor name column is
  /// suppressed because every row would just repeat the same name.
  final bool singleCompetitor;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const SizedBox.shrink();
    }
    if (gameType == GameType.aroundTheClock) {
      return _AtcSegmentTable(segments: breakdown.atcSegments);
    }
    if (breakdown.turns.isEmpty) {
      return const SizedBox.shrink();
    }
    return _TurnTable(
      gameType: gameType,
      turns: breakdown.turns,
      singleCompetitor: singleCompetitor,
    );
  }
}

class _TurnTable extends StatelessWidget {
  const _TurnTable({
    required this.gameType,
    required this.turns,
    required this.singleCompetitor,
  });

  final GameType gameType;
  final List<TurnRow> turns;
  final bool singleCompetitor;

  List<String> _columns(AppLocalizations l10n) {
    // 'Shanghai' (column header) stays fixed — it is a game-type proper noun.
    switch (gameType) {
      case GameType.x01:
        return [
          l10n.historyColRound,
          l10n.historyColStart,
          l10n.historyColDarts,
          l10n.historyColTurn,
          l10n.historyColLeft,
        ];
      case GameType.cricket:
        return [l10n.historyColRound, l10n.historyColMarks, l10n.historyColDarts];
      case GameType.bobs27:
        return [
          l10n.historyColRound,
          l10n.historyColTarget,
          l10n.historyColDarts,
          l10n.historyColHits,
          l10n.historyColScore,
          l10n.historyColTotal,
        ];
      case GameType.catch40:
        return [
          l10n.historyColRound,
          l10n.historyColTarget,
          l10n.historyColDarts,
          l10n.historyColScore,
          l10n.historyColTotal,
          l10n.historyColDone,
        ];
      case GameType.shanghai:
        return [
          l10n.historyColRound,
          l10n.historyColDarts,
          l10n.historyColScore,
          'Shanghai',
          l10n.historyColTotal,
        ];
      case GameType.checkoutPractice:
        return [
          l10n.historyColTurn,
          l10n.historyColStart,
          l10n.historyColDarts,
          l10n.historyColTotal,
          l10n.historyColEnd,
        ];
      case GameType.countUp:
        return [
          l10n.historyColRound,
          l10n.historyColDarts,
          l10n.historyColScore,
          l10n.historyColTotal,
        ];
      case GameType.aroundTheClock:
        return [l10n.historyColRound, l10n.historyColDarts, l10n.historyColScore];
    }
  }

  List<Widget> _cellsFor(TurnRow row, ThemeData theme, AppLocalizations l10n) {
    final cs = theme.colorScheme;
    Widget txt(String s, {Color? color, FontWeight? weight}) => Text(
          s,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: weight,
          ),
        );
    Widget dartsCell() {
      if (row.darts.isEmpty) return txt('—');
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final d in row.darts) _DartChip(canonical: d),
        ],
      );
    }

    // X01 / Checkout Practice turn cell: the score, with a BUST/CHECKOUT flag
    // on its OWN line (the two are mutually exclusive). Stacking them avoids
    // the narrow flex column breaking "CHECKOUT" mid-word, which a single
    // "121 · CHECKOUT" string did once the table was made to fit the width.
    Widget turnScoreCell() {
      final flag = row.bust
          ? 'BUST'
          : row.checkout
              ? 'CHECKOUT'
              : null;
      if (flag == null) return txt(StatFormatter.fmtInt(row.turnScore));
      final color = row.bust ? cs.error : cs.primary;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          txt(StatFormatter.fmtInt(row.turnScore),
              color: color, weight: FontWeight.bold),
          Text(
            flag,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    switch (gameType) {
      case GameType.x01:
        return [
          txt(StatFormatter.fmtInt(row.round)),
          txt(StatFormatter.fmtInt(row.startingScore)),
          dartsCell(),
          turnScoreCell(),
          txt(StatFormatter.fmtInt(row.remainingScore)),
        ];
      case GameType.cricket:
        return [
          txt(StatFormatter.fmtInt(row.round)),
          txt(StatFormatter.fmtInt(row.turnScore)),
          dartsCell(),
        ];
      case GameType.bobs27:
        return [
          txt(StatFormatter.fmtInt(row.round)),
          txt('D${row.targetValue ?? row.round}'),
          dartsCell(),
          txt(StatFormatter.fmtInt(row.hitsOnTarget)),
          txt(
            row.turnScore >= 0 ? '+${row.turnScore}' : '${row.turnScore}',
            color: row.turnScore < 0 ? cs.error : cs.primary,
            weight: FontWeight.bold,
          ),
          txt(StatFormatter.fmtInt(row.runningTotal)),
        ];
      case GameType.catch40:
        return [
          txt(StatFormatter.fmtInt(row.round)),
          txt(StatFormatter.fmtInt(row.targetValue)),
          dartsCell(),
          txt(StatFormatter.fmtInt(row.turnScore)),
          txt(StatFormatter.fmtInt(row.runningTotal)),
          Icon(
            row.targetCompleted == true
                ? Icons.check_circle
                : Icons.cancel,
            size: 18,
            color: row.targetCompleted == true ? cs.primary : cs.outline,
            semanticLabel: row.targetCompleted == true
                ? l10n.historyCompleted
                : l10n.historyNotCompleted,
          ),
        ];
      case GameType.shanghai:
        return [
          txt(StatFormatter.fmtInt(row.round)),
          dartsCell(),
          txt(StatFormatter.fmtInt(row.turnScore)),
          row.shanghai == true
              ? Text(
                  'SHANGHAI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                )
              : txt('—'),
          txt(StatFormatter.fmtInt(row.runningTotal)),
        ];
      case GameType.checkoutPractice:
        return [
          txt(StatFormatter.fmtInt(row.round)),
          txt(StatFormatter.fmtInt(row.startingScore)),
          dartsCell(),
          turnScoreCell(),
          txt(StatFormatter.fmtInt(row.endingScore)),
        ];
      case GameType.countUp:
        return [
          txt(StatFormatter.fmtInt(row.round)),
          dartsCell(),
          txt(StatFormatter.fmtInt(row.turnScore)),
          txt(StatFormatter.fmtInt(row.runningTotal)),
        ];
      case GameType.aroundTheClock:
        return [
          txt(StatFormatter.fmtInt(row.round)),
          dartsCell(),
          txt(StatFormatter.fmtInt(row.turnScore)),
        ];
    }
  }

  /// Column indices (within [_columns], BEFORE the optional leading PLAYER
  /// column) that should flex to absorb leftover width: the dart-chip column
  /// (chips wrap onto extra lines) and any wide free-text column (X01 /
  /// Checkout Practice's "turn score · BUST/CHECKOUT"). Every other column is
  /// a short number or label and sizes to its content. Making only these flex
  /// keeps the whole table within the parent width — no horizontal scroll, and
  /// no empty band on narrow tables like Cricket (replaces the old
  /// scroll-when-cut-off behavior, #309).
  ({int darts, int? wideText}) _flexColumns() {
    switch (gameType) {
      case GameType.x01:
        return (darts: 2, wideText: 3);
      case GameType.checkoutPractice:
        return (darts: 2, wideText: 3);
      case GameType.cricket:
      case GameType.bobs27:
      case GameType.catch40:
        return (darts: 2, wideText: null);
      case GameType.shanghai:
      case GameType.countUp:
        return (darts: 1, wideText: null);
      case GameType.aroundTheClock:
        return (darts: 1, wideText: null); // unused — ATC uses _AtcSegmentTable
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final columns = _columns(l10n);
    final showCompetitor = !singleCompetitor;
    final headers = [
      if (showCompetitor) l10n.historyColPlayer,
      ...columns,
    ];

    final offset = showCompetitor ? 1 : 0;
    final flex = _flexColumns();
    final dartsIdx = flex.darts + offset;
    final wideIdx = flex.wideText == null ? null : flex.wideText! + offset;
    final columnWidths = <int, TableColumnWidth>{
      for (var i = 0; i < headers.length; i++)
        i: i == dartsIdx
            ? const FlexColumnWidth(1.7)
            : i == wideIdx
                // Favor the text column over the chips column so "CHECKOUT"
                // fits on one line even in the tight multi-player layout
                // (chips just wrap onto more rows when their column shrinks).
                ? const FlexColumnWidth(2.3)
                : const IntrinsicColumnWidth(),
    };

    const cellPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
    final headingStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.1,
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      // A width-bounded Table (chips column + wide-text column flex; the rest
      // intrinsic) fits within the parent — no horizontal scroll (#309 was
      // solved by scrolling; we now fit instead, per the at-a-glance UX goal).
      child: Table(
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.08)),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: cs.surfaceContainerLow),
            children: [
              for (final h in headers)
                Padding(
                  padding: cellPadding,
                  child: Text(h.toUpperCase(), style: headingStyle),
                ),
            ],
          ),
          for (final row in turns)
            TableRow(
              children: [
                if (showCompetitor)
                  Padding(
                    padding: cellPadding,
                    child: Text(
                      NameFormatter.shortName(row.competitorName),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                for (final cell in _cellsFor(row, theme, l10n))
                  Padding(padding: cellPadding, child: cell),
              ],
            ),
        ],
      ),
    );
  }
}

class _AtcSegmentTable extends StatelessWidget {
  const _AtcSegmentTable({required this.segments});

  final List<SegmentHitRate> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    const cellPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final headingStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.1,
    );
    Widget headCell(String s) =>
        Padding(padding: cellPadding, child: Text(s.toUpperCase(), style: headingStyle));
    Widget cell(String s) =>
        Padding(padding: cellPadding, child: Text(s, style: theme.textTheme.bodyMedium));

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      // Four short columns flex to fill the parent width evenly — fits without
      // a horizontal scroll, matching the turn table.
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.4),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.08)),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: cs.surfaceContainerLow),
            children: [
              headCell(l10n.historyColSegment),
              headCell(l10n.historyColHits),
              headCell(l10n.historyColAttempts),
              headCell(l10n.historyColRate),
            ],
          ),
          for (final s in segments)
            TableRow(
              children: [
                cell(s.segmentLabel),
                cell('${s.hits}'),
                cell('${s.attempts}'),
                cell(s.attempts == 0
                    ? '—'
                    : StatFormatter.fmtPct(s.hitRate, isRatio: true)),
              ],
            ),
        ],
      ),
    );
  }
}

class _DartChip extends StatelessWidget {
  const _DartChip({required this.canonical});

  final String canonical;

  Color _bg(ColorScheme cs) {
    if (canonical == 'MISS') return cs.surfaceContainerHigh;
    if (canonical.startsWith('T')) return cs.tertiaryContainer;
    if (canonical.startsWith('D')) return cs.secondaryContainer;
    if (canonical == 'SB' || canonical == 'DB') return cs.primaryContainer;
    return cs.surfaceContainerHighest;
  }

  Color _fg(ColorScheme cs) {
    if (canonical == 'MISS') return cs.onSurfaceVariant;
    if (canonical.startsWith('T')) return cs.onTertiaryContainer;
    if (canonical.startsWith('D')) return cs.onSecondaryContainer;
    if (canonical == 'SB' || canonical == 'DB') return cs.onPrimaryContainer;
    return cs.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bg(cs),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        canonical,
        // Never ellipsize the chip label itself — a chip is sized to its
        // text, and the chips live in a `Wrap` inside the flexible DARTS
        // column, so they reflow onto extra lines instead of being chopped
        // to "MI…" (#285).
        softWrap: false,
        overflow: TextOverflow.visible,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _fg(cs),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
