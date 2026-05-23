import 'package:flutter/material.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/utils/name_formatter.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/history/domain/turn_breakdown.dart';

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

  List<String> _columns() {
    switch (gameType) {
      case GameType.x01:
        return ['Round', 'Start', 'Darts', 'Turn', 'Remaining'];
      case GameType.cricket:
        return ['Round', 'Marks', 'Darts'];
      case GameType.bobs27:
        return ['Round', 'Target', 'Darts', 'Hits', 'Score', 'Total'];
      case GameType.catch40:
        return ['Round', 'Target', 'Darts', 'Score', 'Total', 'Done'];
      case GameType.shanghai:
        return ['Round', 'Darts', 'Score', 'Shanghai', 'Total'];
      case GameType.checkoutPractice:
        return ['Turn', 'Start', 'Darts', 'Total', 'End'];
      case GameType.countUp:
        return ['Round', 'Darts', 'Score', 'Total'];
      case GameType.aroundTheClock:
        return ['Round', 'Darts', 'Score'];
    }
  }

  List<Widget> _cellsFor(TurnRow row, ThemeData theme) {
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

    switch (gameType) {
      case GameType.x01:
        final flags = <String>[];
        if (row.bust) flags.add('BUST');
        if (row.checkout) flags.add('CHECKOUT');
        return [
          txt(StatFormatter.fmtInt(row.round)),
          txt(StatFormatter.fmtInt(row.startingScore)),
          dartsCell(),
          txt(
            '${row.turnScore}${flags.isEmpty ? '' : ' · ${flags.join(' / ')}'}',
            color: row.bust
                ? cs.error
                : row.checkout
                    ? cs.primary
                    : null,
            weight: row.bust || row.checkout ? FontWeight.bold : null,
          ),
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
            semanticLabel:
                row.targetCompleted == true ? 'Completed' : 'Not completed',
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
        final flags = <String>[];
        if (row.bust) flags.add('BUST');
        if (row.checkout) flags.add('CHECKOUT');
        return [
          txt(StatFormatter.fmtInt(row.round)),
          txt(StatFormatter.fmtInt(row.startingScore)),
          dartsCell(),
          txt(
            '${row.turnScore}${flags.isEmpty ? '' : ' · ${flags.join(' / ')}'}',
            color: row.bust
                ? cs.error
                : row.checkout
                    ? cs.primary
                    : null,
            weight: row.bust || row.checkout ? FontWeight.bold : null,
          ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final columns = _columns();
    final showCompetitor = !singleCompetitor;
    final headers = [
      if (showCompetitor) 'Player',
      ...columns,
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          horizontalMargin: 12,
          headingRowHeight: 36,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 64,
          headingTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
          columns: [
            for (final h in headers) DataColumn(label: Text(h.toUpperCase())),
          ],
          rows: [
            for (final row in turns)
              DataRow(
                cells: [
                  if (showCompetitor)
                    DataCell(Text(
                      NameFormatter.shortName(row.competitorName),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                  for (final cell in _cellsFor(row, theme)) DataCell(cell),
                ],
              ),
          ],
        ),
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

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          horizontalMargin: 12,
          headingRowHeight: 36,
          headingTextStyle: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
          columns: const [
            DataColumn(label: Text('SEGMENT')),
            DataColumn(label: Text('HITS')),
            DataColumn(label: Text('ATTEMPTS')),
            DataColumn(label: Text('RATE')),
          ],
          rows: [
            for (final s in segments)
              DataRow(
                cells: [
                  DataCell(Text(s.segmentLabel)),
                  DataCell(Text('${s.hits}')),
                  DataCell(Text('${s.attempts}')),
                  DataCell(Text(
                    s.attempts == 0
                        ? '—'
                        : StatFormatter.fmtPct(s.hitRate, isRatio: true),
                  )),
                ],
              ),
          ],
        ),
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
        // Never wrap or ellipsize the chip text — at 412px the parent
        // DataCell can squeeze the column and Flutter would otherwise
        // render "MISS" as "MI…". The DataTable already wraps in a
        // horizontal SingleChildScrollView, so letting the chip overflow
        // its column lets the user scroll to it rather than seeing it
        // chopped (#285).
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
