import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/utils/name_formatter.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/core/widgets/post_game_stats_breakdown_widget.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/history/domain/turn_breakdown.dart';
import 'package:dart_lodge/features/history/presentation/widgets/turn_breakdown_table_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// Summary-row column widths. The middle "winner" column flexes; the rest are
/// fixed so every leg row lines up under the header.
const double _kLegColWidth = 48;
const double _kDartsColWidth = 60;
const double _kChevronColWidth = 40;

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

    // A Column of per-leg blocks rather than one global Table: the expanded
    // detail (stats breakdown + turn breakdown) renders full-width below its
    // summary row instead of being trapped inside the "winner" column cell of
    // a shared table (Flutter's Table has no colspan), which squeezed it to a
    // fraction of the screen (#693 fixed the top breakdown; this matches it).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _headerRow(theme, l10n),
        for (final leg in widget.legs) ...[
          _legRow(leg, theme),
          if (_expandedLegs.contains(leg.legNumber))
            _expandedSection(leg, theme, l10n),
        ],
      ],
    );
  }

  Widget _headerRow(ThemeData theme, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          SizedBox(width: _kLegColWidth, child: _headerCell(l10n.historyColLeg)),
          Expanded(child: _headerCell(l10n.historyWinner)),
          SizedBox(
              width: _kDartsColWidth, child: _headerCell(l10n.historyColDarts)),
          if (_expandable) const SizedBox(width: _kChevronColWidth),
        ],
      ),
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  Widget _legRow(LegStatsBreakdown leg, ThemeData theme) {
    final isExpanded = _expandedLegs.contains(leg.legNumber);
    final totalDarts =
        leg.byCompetitor.fold<int>(0, (s, c) => s + c.dartsThrown);
    final row = Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: _kLegColWidth, child: _cell('${leg.legNumber}')),
          Expanded(child: _cell(leg.winnerName)),
          SizedBox(width: _kDartsColWidth, child: _cell('$totalDarts')),
          if (_expandable)
            SizedBox(
              width: _kChevronColWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
    if (!_expandable) return row;
    return InkWell(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedLegs.remove(leg.legNumber);
        } else {
          _expandedLegs.add(leg.legNumber);
        }
      }),
      child: row,
    );
  }

  Widget _cell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(text),
      );

  Widget _expandedSection(
      LegStatsBreakdown leg, ThemeData theme, AppLocalizations l10n) {
    final showStatsTable = widget.gameType == GameType.x01 ||
        widget.gameType == GameType.cricket;
    final breakdown = _turnBreakdownByLeg[leg.legNumber];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showStatsTable) _legStatsBreakdown(leg, l10n),
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
    );
  }

  /// Renders the per-leg stats on the same fill-width-or-scroll shell as the
  /// top "Statistics Breakdown" (#693), with its section title suppressed.
  Widget _legStatsBreakdown(LegStatsBreakdown leg, AppLocalizations l10n) {
    final competitors = leg.byCompetitor;
    if (competitors.isEmpty) return const SizedBox.shrink();

    final isCricket = widget.gameType == GameType.cricket;
    final columns = competitors.map((c) {
      final isWinner = c.competitorId == leg.winnerCompetitorId;
      return PostGameBreakdownColumn(
        name: NameFormatter.shortName(c.competitorName),
        subtitle:
            (isWinner ? l10n.historyWinner : l10n.historyOpponent).toUpperCase(),
        emphasize: isWinner,
      );
    }).toList();

    final statRows =
        isCricket ? _cricketRows(l10n, competitors) : _x01Rows(l10n, competitors);
    final rows = statRows
        .map((r) => PostGameBreakdownRow(
              category: r.category,
              values: r.values,
              highlights: [
                for (final c in competitors)
                  r.highlightWinner &&
                      c.competitorId == leg.winnerCompetitorId,
              ],
            ))
        .toList();

    return PostGameStatsBreakdown(
      showHeader: false,
      columns: columns,
      rows: rows,
    );
  }

  List<_StatRow> _x01Rows(
      AppLocalizations l10n, List<LegCompetitorStats> competitors) {
    return [
      _StatRow(
        category: l10n.statAvgPpr,
        values: competitors
            .map((c) => StatFormatter.fmtDouble(c.threeDartAverage))
            .toList(),
        highlightWinner: true,
      ),
      _StatRow(
        category: l10n.statCheckout,
        values: competitors
            .map((c) =>
                StatFormatter.fmtPct(c.checkoutPercentage, isRatio: false))
            .toList(),
      ),
      _StatRow(
        category: l10n.statBestOut,
        values: competitors
            .map((c) => c.highestCheckout != null
                ? '${c.highestCheckout}'
                : '—')
            .toList(),
      ),
      _StatRow(
        category: l10n.stat180s,
        values:
            competitors.map((c) => c.oneEightyTurns.toString()).toList(),
      ),
      // High-score buckets are mutually exclusive (see
      // `X01HighScoreBucketsProjection`); labels must match the actual
      // range so they don't read as cumulative "100+" / "140+" (#290).
      _StatRow(
        category: l10n.stat6099,
        values: competitors.map((c) => c.sixtyPlusTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.stat100139,
        values: competitors
            .map((c) => c.oneHundredPlusTurns.toString())
            .toList(),
      ),
      _StatRow(
        category: l10n.stat140179,
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
        category: l10n.statAvgMpr,
        values: competitors
            .map((c) => StatFormatter.fmtDouble(c.marksPerRound, decimals: 2))
            .toList(),
        highlightWinner: true,
      ),
      _StatRow(
        category: l10n.statFirst9Mpr,
        values: competitors
            .map((c) =>
                StatFormatter.fmtDouble(c.firstNineMarksPerRound, decimals: 2))
            .toList(),
      ),
      _StatRow(
        category: l10n.stat5Marks,
        values: competitors.map((c) => c.fiveMarkTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.stat6Marks,
        values: competitors.map((c) => c.sixMarkTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.stat7Marks,
        values: competitors.map((c) => c.sevenMarkTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.stat8Marks,
        values: competitors.map((c) => c.eightMarkTurns.toString()).toList(),
      ),
      _StatRow(
        category: l10n.stat9Marks,
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
