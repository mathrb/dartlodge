import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/utils/name_formatter.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/history/domain/turn_breakdown.dart';
import 'package:dart_lodge/features/history/presentation/widgets/turn_breakdown_table_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

class LegBreakdownTableWidget extends StatefulWidget {
  final List<LegStatsBreakdown> legs;
  final Game game;
  final List<Competitor> competitors;
  final List<GameEvent> events;

  const LegBreakdownTableWidget({
    required this.legs,
    required this.game,
    this.competitors = const [],
    this.events = const [],
    super.key,
  });

  GameType get gameType => game.gameType;

  @override
  State<LegBreakdownTableWidget> createState() =>
      _LegBreakdownTableWidgetState();
}

class _LegBreakdownTableWidgetState extends State<LegBreakdownTableWidget> {
  late Set<int> _expandedLegs;
  late Map<int, LegTurnBreakdown> _turnBreakdownByLeg;

  bool get _isSingleLeg => widget.legs.length == 1;
  bool get _expandable => widget.legs.length > 1;

  @override
  void initState() {
    super.initState();
    _expandedLegs = _isSingleLeg ? {widget.legs.first.legNumber} : <int>{};
    _turnBreakdownByLeg = _buildBreakdown();
  }

  @override
  void didUpdateWidget(covariant LegBreakdownTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.events, widget.events) ||
        !identical(oldWidget.game, widget.game) ||
        !identical(oldWidget.competitors, widget.competitors)) {
      _turnBreakdownByLeg = _buildBreakdown();
    }
  }

  Map<int, LegTurnBreakdown> _buildBreakdown() =>
      const TurnBreakdownBuilder().build(
        game: widget.game,
        competitors: widget.competitors,
        events: widget.events,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (widget.legs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.historyNoLegs),
        ),
      );
    }

    return Table(
      columnWidths: {
        0: const FixedColumnWidth(48),
        1: const FlexColumnWidth(),
        2: const FixedColumnWidth(60),
        if (_expandable) 3: const FixedColumnWidth(40),
      },
      children: [
        _headerRow(theme, l10n),
        for (final leg in widget.legs) ...[
          _legRow(leg, theme),
          if (_expandedLegs.contains(leg.legNumber))
            _expandedRow(leg, theme, l10n),
        ],
      ],
    );
  }

  TableRow _headerRow(ThemeData theme, AppLocalizations l10n) {
    final cells = <Widget>[
      _headerCell(l10n.historyColLeg),
      _headerCell(l10n.historyWinner),
      _headerCell(l10n.historyColDarts),
      if (_expandable) const SizedBox.shrink(),
    ];
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      children: cells,
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  TableRow _legRow(LegStatsBreakdown leg, ThemeData theme) {
    final isExpanded = _expandedLegs.contains(leg.legNumber);
    final totalDarts =
        leg.byCompetitor.fold<int>(0, (s, c) => s + c.dartsThrown);
    final cells = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text('${leg.legNumber}'),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(leg.winnerName),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text('$totalDarts'),
      ),
      if (_expandable)
        GestureDetector(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedLegs.remove(leg.legNumber);
            } else {
              _expandedLegs.add(leg.legNumber);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
          ),
        ),
    ];
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      children: cells,
    );
  }

  TableRow _expandedRow(
      LegStatsBreakdown leg, ThemeData theme, AppLocalizations l10n) {
    final showStatsTable = widget.gameType == GameType.x01 ||
        widget.gameType == GameType.cricket;
    final breakdown = _turnBreakdownByLeg[leg.legNumber];
    return TableRow(
      children: [
        const SizedBox.shrink(),
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showStatsTable)
                _LegStatsTable(
                  leg: leg,
                  gameType: widget.gameType,
                ),
              if (breakdown != null && !breakdown.isEmpty) ...[
                if (showStatsTable) const SizedBox(height: 12),
                Text(
                  l10n.historyTurnBreakdown,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                TurnBreakdownTableWidget(
                  gameType: widget.gameType,
                  breakdown: breakdown,
                  singleCompetitor: widget.competitors.length <= 1,
                ),
              ],
            ],
          ),
        ),
        const SizedBox.shrink(),
        if (_expandable) const SizedBox.shrink(),
      ],
    );
  }
}

class _LegStatsTable extends StatelessWidget {
  const _LegStatsTable({required this.leg, required this.gameType});

  final LegStatsBreakdown leg;
  final GameType gameType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final competitors = leg.byCompetitor;
    if (competitors.isEmpty) return const SizedBox.shrink();

    final isCricket = gameType == GameType.cricket;
    final rows =
        isCricket ? _cricketRows(l10n, competitors) : _x01Rows(l10n, competitors);

    const cellPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final headerStyle = tt.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w900,
    );
    final categoryStyle = tt.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(
            horizontalInside:
                BorderSide(color: cs.outlineVariant.withValues(alpha: 0.08)),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              children: [
                Padding(
                  padding: cellPadding,
                  child: Text(l10n.historyCategory.toUpperCase(),
                      style: headerStyle),
                ),
                ...competitors.map((c) {
                  final isWinner = c.competitorId == leg.winnerCompetitorId;
                  return Padding(
                    padding: cellPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          NameFormatter.shortName(c.competitorName),
                          style: tt.labelMedium?.copyWith(
                            color: isWinner ? cs.primaryFixed : cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          (isWinner ? l10n.historyWinner : l10n.historyOpponent)
                              .toUpperCase(),
                          style: tt.labelSmall?.copyWith(
                            color: isWinner
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
                    ...List.generate(competitors.length, (i) {
                      final highlight = row.highlightWinner &&
                          competitors[i].competitorId ==
                              leg.winnerCompetitorId;
                      return Padding(
                        padding: cellPadding,
                        child: Text(
                          row.values[i],
                          style: tt.titleMedium?.copyWith(
                            color:
                                highlight ? cs.primaryFixed : cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  List<_StatRow> _x01Rows(
      AppLocalizations l10n, List<LegCompetitorStats> competitors) {
    return [
      _StatRow(
        category: l10n.historyStatAvgPpr,
        values: competitors
            .map((c) => StatFormatter.fmtDouble(c.threeDartAverage))
            .toList(),
        highlightWinner: true,
      ),
      _StatRow(
        category: l10n.historyStatCheckout,
        values: competitors
            .map((c) =>
                StatFormatter.fmtPct(c.checkoutPercentage, isRatio: false))
            .toList(),
      ),
      _StatRow(
        category: l10n.historyStatBestOut,
        values: competitors
            .map((c) => c.highestCheckout != null
                ? '${c.highestCheckout}'
                : '—')
            .toList(),
      ),
      _StatRow(
        category: l10n.historyStat180s,
        values:
            competitors.map((c) => c.oneEightyTurns.toString()).toList(),
      ),
      // High-score buckets are mutually exclusive (see
      // `X01HighScoreBucketsProjection`); labels must match the actual
      // range so they don't read as cumulative "100+" / "140+" (#290).
      _StatRow(
        category: l10n.historyStat6099,
        values: competitors.map((c) => c.sixtyPlusTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.historyStat100139,
        values: competitors
            .map((c) => c.oneHundredPlusTurns.toString())
            .toList(),
      ),
      _StatRow(
        category: l10n.historyStat140179,
        values: competitors
            .map((c) => c.oneFortyPlusTurns.toString())
            .toList(),
      ),
    ];
  }

  List<_StatRow> _cricketRows(
      AppLocalizations l10n, List<LegCompetitorStats> competitors) {
    return [
      _StatRow(
        category: l10n.historyStatAvgMpr,
        values: competitors
            .map((c) => StatFormatter.fmtDouble(c.marksPerRound, decimals: 2))
            .toList(),
        highlightWinner: true,
      ),
      _StatRow(
        category: l10n.historyStatFirst9Mpr,
        values: competitors
            .map((c) =>
                StatFormatter.fmtDouble(c.firstNineMarksPerRound, decimals: 2))
            .toList(),
      ),
      _StatRow(
        category: l10n.historyStat5Marks,
        values: competitors.map((c) => c.fiveMarkTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.historyStat6Marks,
        values: competitors.map((c) => c.sixMarkTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.historyStat7Marks,
        values: competitors.map((c) => c.sevenMarkTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.historyStat8Marks,
        values: competitors.map((c) => c.eightMarkTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.historyStat9Marks,
        values: competitors.map((c) => c.nineMarkTurns.toString()).toList(),
      ),
    ];
  }

}

class _StatRow {
  final String category;
  final List<String> values;
  final bool highlightWinner;

  _StatRow({
    required this.category,
    required this.values,
    this.highlightWinner = false,
  });
}
