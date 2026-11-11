import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
            softWrap: false,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
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
                  softWrap: false,
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
  /// column) that flex to absorb leftover width: the dart-chip column (chips
  /// wrap onto extra lines) and any wide free-text column (X01 / Checkout
  /// Practice's turn score + BUST/CHECKOUT flag, stacked on two lines by
  /// turnScoreCell). Every other column is a short number or label and sizes
  /// to its content. The flex columns never shrink below their content floor
  /// (the widest chip, the CHECKOUT flag, their header), so a chip is never
  /// clipped and a header never breaks mid-word. When the floors do not fit
  /// the width, [_TableOrStacked] swaps to one stacked block per turn, so the
  /// layout still fits the parent with no horizontal scroll (#309).
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

  /// Widest share of the row the PLAYER column may take before the name
  /// ellipsizes in the table layout (the stacked layout shows it in full).
  static const double _playerColumnMaxFraction = 0.28;

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

    const cellPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 8);
    final headingStyle = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.1,
    );
    Widget heading(String h) => Text(
          h.toUpperCase(),
          style: headingStyle,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        );
    Widget name(TurnRow row) => Text(
          NameFormatter.shortName(row.competitorName),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
    // Built once per turn and shared by both layouts below.
    final cellsByRow = [
      for (final row in turns) _cellsFor(row, theme, l10n),
    ];
    final rowDivider =
        BorderSide(color: cs.outlineVariant.withValues(alpha: 0.08));

    return LayoutBuilder(builder: (context, constraints) {
      const flexFloor = IntrinsicColumnWidth();
      final columnWidths = <int, TableColumnWidth>{
        for (var i = 0; i < headers.length; i++)
          i: i == dartsIdx
              ? const MaxColumnWidth(FlexColumnWidth(1.7), flexFloor)
              : i == wideIdx
                  // Favor the text column over the chips column so
                  // "CHECKOUT" has room in the tight multi-player layout
                  // (chips just wrap onto more rows when their column
                  // shrinks).
                  ? const MaxColumnWidth(FlexColumnWidth(2.6), flexFloor)
                  : i == 0 && showCompetitor && constraints.hasBoundedWidth
                      ? MinColumnWidth(
                          const IntrinsicColumnWidth(),
                          FixedColumnWidth(
                            constraints.maxWidth * _playerColumnMaxFraction,
                          ),
                        )
                      : const IntrinsicColumnWidth(),
      };

      final table = Table(
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(horizontalInside: rowDivider),
        children: [
          TableRow(
            decoration: BoxDecoration(color: cs.surfaceContainerLow),
            children: [
              for (final h in headers)
                Padding(padding: cellPadding, child: heading(h)),
            ],
          ),
          for (var r = 0; r < turns.length; r++)
            TableRow(
              children: [
                if (showCompetitor)
                  Padding(padding: cellPadding, child: name(turns[r])),
                for (final cell in cellsByRow[r])
                  Padding(padding: cellPadding, child: cell),
              ],
            ),
        ],
      );

      // Narrow fallback (large text, long names): one block per turn, each
      // value under an inline column label. Line 1 holds the short columns,
      // line 2 the chips and the turn score. Wraps never overflow.
      Widget labelled(int column, Widget cell) => Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [heading(columns[column]), cell],
          );
      final stacked = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var r = 0; r < turns.length; r++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: r == 0 ? null : Border(top: rowDivider),
              ),
              child: Padding(
                padding: cellPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showCompetitor) name(turns[r]),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        for (var c = 0; c < columns.length; c++)
                          if (c != flex.darts && c != flex.wideText)
                            labelled(c, cellsByRow[r][c]),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        labelled(flex.darts, cellsByRow[r][flex.darts]),
                        if (flex.wideText != null)
                          labelled(
                            flex.wideText!,
                            cellsByRow[r][flex.wideText!],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
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
        child: _TableOrStacked(table: table, stacked: stacked),
      );
    });
  }
}

/// Shows [table] when every column fits at its minimum width (the sum of the
/// table's column floors), and [stacked] otherwise. Only the chosen child is
/// laid out, painted, hit-tested and exposed to semantics — and to widget
/// finders, via [_TableOrStackedElement].
class _TableOrStacked extends MultiChildRenderObjectWidget {
  _TableOrStacked({required Widget table, required Widget stacked})
      : super(children: [table, stacked]);

  @override
  MultiChildRenderObjectElement createElement() =>
      _TableOrStackedElement(this);

  @override
  _RenderTableOrStacked createRenderObject(BuildContext context) =>
      _RenderTableOrStacked();
}

class _TableOrStackedElement extends MultiChildRenderObjectElement {
  _TableOrStackedElement(super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final kids = children.toList();
    if (kids.length != 2) return super.debugVisitOnstageChildren(visitor);
    final usesTable = (renderObject as _RenderTableOrStacked).usesTable;
    visitor(kids[usesTable ? 0 : 1]);
  }
}

class _TableOrStackedParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTableOrStacked extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TableOrStackedParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TableOrStackedParentData> {
  /// Whether the last layout chose the table (true) or the stacked fallback.
  bool usesTable = true;

  RenderBox get _table => firstChild!;
  RenderBox get _stacked => lastChild!;
  RenderBox get _active => usesTable ? _table : _stacked;

  bool _tableFits(double maxWidth) =>
      _table.getMinIntrinsicWidth(double.infinity) <=
      maxWidth + precisionErrorTolerance;

  RenderBox _childFor(double maxWidth) =>
      _tableFits(maxWidth) ? _table : _stacked;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TableOrStackedParentData) {
      child.parentData = _TableOrStackedParentData();
    }
  }

  @override
  void performLayout() {
    usesTable = _tableFits(constraints.maxWidth);
    _active.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(_active.size);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints
      .constrain(_childFor(constraints.maxWidth).getDryLayout(constraints));

  @override
  double computeMinIntrinsicWidth(double height) =>
      _stacked.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _table.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _childFor(width).getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _childFor(width).getMaxIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) =>
      context.paintChild(_active, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      _active.hitTest(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) =>
      visitor(_active);
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
      // Four short columns flex to fill the parent width (segment a little
      // wider) — fits without a horizontal scroll, matching the turn table.
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
