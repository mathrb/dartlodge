import 'package:flutter/material.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/entities/dart_throw.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';

class LegBreakdownTableWidget extends StatefulWidget {
  final List<GameEvent> events;
  final List<DartThrow> darts;
  final List<Competitor> competitors;

  const LegBreakdownTableWidget({
    required this.events,
    required this.darts,
    required this.competitors,
    super.key,
  });

  @override
  State<LegBreakdownTableWidget> createState() =>
      _LegBreakdownTableWidgetState();
}

class _LegSummary {
  final int legNumber;
  final String winnerName;
  final int dartsThrown;
  final List<DartThrow> legDarts;

  const _LegSummary({
    required this.legNumber,
    required this.winnerName,
    required this.dartsThrown,
    required this.legDarts,
  });
}

class _LegBreakdownTableWidgetState extends State<LegBreakdownTableWidget> {
  final Set<int> _expandedLegs = {};

  List<_LegSummary> _buildLegs() {
    final sortedEvents = [...widget.events]
      ..sort((a, b) => a.localSequence.compareTo(b.localSequence));

    final dartsByTurn = <int, List<DartThrow>>{};
    for (final d in widget.darts) {
      dartsByTurn.putIfAbsent(d.turnNumber, () => []).add(d);
    }

    final legs = <_LegSummary>[];
    int prevSeq = 0;
    int legNumber = 1;

    for (final event in sortedEvents) {
      if (event.eventType != 'LegCompleted') continue;

      final winnerId = event.payload['winner_competitor_id'] as String?;
      final winnerComp = widget.competitors.firstWhere(
        (c) => c.competitorId == winnerId,
        orElse: () => widget.competitors.isNotEmpty
            ? widget.competitors.first
            : const Competitor(
                competitorId: '',
                gameId: '',
                type: CompetitorType.solo,
                name: 'Unknown',
                players: [],
              ),
      );

      final legTurnNums = sortedEvents
          .where((e) =>
              e.localSequence > prevSeq &&
              e.localSequence < event.localSequence &&
              e.eventType == 'DartThrown')
          .map((e) => e.payload['turn_number'] as int?)
          .whereType<int>()
          .toSet();

      final legDarts = [
        for (final tn in legTurnNums) ...?dartsByTurn[tn],
      ]..sort((a, b) {
          final t = a.turnNumber.compareTo(b.turnNumber);
          return t != 0 ? t : a.dartNumber.compareTo(b.dartNumber);
        });

      legs.add(_LegSummary(
        legNumber: legNumber++,
        winnerName: winnerComp.name,
        dartsThrown: legDarts.length,
        legDarts: legDarts,
      ));
      prevSeq = event.localSequence;
    }

    return legs;
  }

  List<Widget> _buildTurnWidgets(_LegSummary leg, ThemeData theme) {
    final byTurn = <int, List<DartThrow>>{};
    for (final d in leg.legDarts) {
      byTurn.putIfAbsent(d.turnNumber, () => []).add(d);
    }
    final turnNums = byTurn.keys.toList()..sort();
    return turnNums.map((tn) {
      final turnDarts = byTurn[tn]!
        ..sort((a, b) => a.dartNumber.compareTo(b.dartNumber));
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          turnDarts.map((d) => d.segment).join(' '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final legs = _buildLegs();
    final theme = Theme.of(context);

    if (legs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No legs completed'),
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(48),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(60),
        3: FixedColumnWidth(40),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          children: [
            _headerCell('Leg'),
            _headerCell('Winner'),
            _headerCell('Darts'),
            const SizedBox.shrink(),
          ],
        ),
        for (final leg in legs) ...[
          _legRow(leg, theme),
          if (_expandedLegs.contains(leg.legNumber))
            _expandedRow(leg, theme),
        ],
      ],
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  TableRow _legRow(_LegSummary leg, ThemeData theme) {
    final isExpanded = _expandedLegs.contains(leg.legNumber);
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
        ),
      ),
      children: [
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
          child: Text('${leg.dartsThrown}'),
        ),
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
      ],
    );
  }

  TableRow _expandedRow(_LegSummary leg, ThemeData theme) {
    return TableRow(
      children: [
        const SizedBox.shrink(),
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildTurnWidgets(leg, theme),
          ),
        ),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
      ],
    );
  }
}
