import 'package:flutter/material.dart';

import '../utils/app_text_styles.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/name_formatter.dart';
import '../utils/stat_formatter.dart';
import '../../features/statistics/domain/entities/game_stats.dart';

/// Renders the post-game summary body — winner card, opponent cards, and
/// stats breakdown table — without any page chrome (no header, no footer).
class GameSummarySectionWidget extends StatelessWidget {
  const GameSummarySectionWidget({required this.gameStats, super.key});

  final GameStats gameStats;

  CompetitorStats? _findWinner() {
    if (gameStats.byCompetitor.isEmpty) return null;
    final maxLegs = gameStats.byCompetitor
        .map((c) => c.legsWon)
        .reduce((a, b) => a > b ? a : b);
    if (maxLegs == 0) return null;
    final leaders =
        gameStats.byCompetitor.where((c) => c.legsWon == maxLegs).toList();
    return leaders.length == 1 ? leaders.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final winner = _findWinner();
    final isCricket = gameStats.gameType == GameType.cricket.name;
    final isCountUp = gameStats.gameType == GameType.countUp.name;
    final opponents = winner == null
        ? gameStats.byCompetitor
        : gameStats.byCompetitor
            .where((c) => c.competitorId != winner.competitorId)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (winner != null) ...[
          _WinnerCard(
            winner: winner,
            isCricket: isCricket,
            isCountUp: isCountUp,
          ),
          const SizedBox(height: 16),
        ],
        if (opponents.isNotEmpty) ...[
          ...opponents.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OpponentCard(stats: c, isCricket: isCricket),
              )),
          const SizedBox(height: 16),
        ],
        _StatsBreakdownSection(
          allCompetitors: gameStats.byCompetitor,
          winnerId: winner?.competitorId,
          isCricket: isCricket,
          isCountUp: isCountUp,
        ),
      ],
    );
  }
}

// ── Winner Card ───────────────────────────────────────────────────────────────

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.winner,
    required this.isCricket,
    required this.isCountUp,
  });

  final CompetitorStats winner;
  final bool isCricket;
  final bool isCountUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border(
            left: BorderSide(color: cs.primaryFixed, width: 4),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -24,
                        top: -24,
                        child: Icon(
                          Icons.emoji_events,
                          size: 120,
                          color: cs.onSurface.withValues(alpha: 0.04),
                          semanticLabel: null,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.primaryFixed,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull),
                                ),
                                child: Text(
                                  'WINNER',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onPrimaryFixed,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.stars,
                                color: cs.primaryFixed,
                                size: 20,
                                semanticLabel: 'Winner star',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            winner.competitorName.toUpperCase(),
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (!isCountUp)
                            Text(
                              '${winner.legsWon} LEG${winner.legsWon == 1 ? '' : 'S'} WON',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  border: Border(
                    left: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BigStat(
                      label: isCricket ? 'AVG MPR' : 'AVG PPR',
                      value: isCricket
                          ? StatFormatter.fmtDouble(winner.marksPerRound,
                              decimals: 2)
                          : StatFormatter.fmtDouble(winner.threeDartAverage),
                      color: cs.primaryFixed,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      width: 48,
                      color: cs.outlineVariant.withValues(
                          alpha: AppTheme.opacityGhostBorderStrong),
                    ),
                    const SizedBox(height: 16),
                    _BigStat(
                      label: 'DARTS',
                      value: '${winner.totalDartsThrown}',
                      color: cs.onSurface,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.scoreMedium(context).copyWith(color: color),
        ),
      ],
    );
  }
}

// ── Opponent Card ─────────────────────────────────────────────────────────────

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({required this.stats, required this.isCricket});

  final CompetitorStats stats;
  final bool isCricket;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border(
          left: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.competitorName.toUpperCase(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'OPPONENT',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              _SmallStat(
                label: isCricket ? 'MPR' : 'PPR',
                value: isCricket
                    ? StatFormatter.fmtDouble(stats.marksPerRound, decimals: 2)
                    : StatFormatter.fmtDouble(stats.threeDartAverage),
              ),
              const SizedBox(width: 24),
              _SmallStat(
                label: 'DARTS',
                value: '${stats.totalDartsThrown}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.scoreSmall(context).copyWith(
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Stats Breakdown Table ─────────────────────────────────────────────────────

class _StatsBreakdownSection extends StatelessWidget {
  const _StatsBreakdownSection({
    required this.allCompetitors,
    required this.winnerId,
    required this.isCricket,
    required this.isCountUp,
  });

  final List<CompetitorStats> allCompetitors;
  final String? winnerId;
  final bool isCricket;
  final bool isCountUp;

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
              'STATISTICS BREAKDOWN',
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
              color: cs.outlineVariant.withValues(
                  alpha: AppTheme.opacityGhostBorderLight),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _StatsTable(
              allCompetitors: allCompetitors,
              winnerId: winnerId,
              isCricket: isCricket,
              isCountUp: isCountUp,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({
    required this.allCompetitors,
    required this.winnerId,
    required this.isCricket,
    required this.isCountUp,
  });

  final List<CompetitorStats> allCompetitors;
  final String? winnerId;
  final bool isCricket;
  final bool isCountUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final noHighlight = allCompetitors.map((_) => false).toList();
    final countUpRows = <_StatRow>[
      _StatRow(
        category: 'Avg PPR',
        values: allCompetitors
            .map((c) => StatFormatter.fmtDouble(c.threeDartAverage))
            .toList(),
        highlights:
            allCompetitors.map((c) => c.competitorId == winnerId).toList(),
      ),
      _StatRow(
        category: '180s',
        values:
            allCompetitors.map((c) => c.oneEightyTurns.toString()).toList(),
        highlights: noHighlight,
      ),
      _StatRow(
        category: '140+',
        values: allCompetitors
            .map((c) => c.oneFortyPlusTurns.toString())
            .toList(),
        highlights: noHighlight,
      ),
      _StatRow(
        category: '100+',
        values: allCompetitors
            .map((c) => c.oneHundredPlusTurns.toString())
            .toList(),
        highlights: noHighlight,
      ),
      _StatRow(
        category: '60+',
        values:
            allCompetitors.map((c) => c.sixtyPlusTurns.toString()).toList(),
        highlights: noHighlight,
      ),
    ];
    final rows = isCountUp
        ? countUpRows
        : isCricket
            ? <_StatRow>[
                _StatRow(
                  category: 'Avg MPR',
                  values: allCompetitors
                      .map((c) =>
                          StatFormatter.fmtDouble(c.marksPerRound, decimals: 2))
                      .toList(),
                  highlights: allCompetitors
                      .map((c) => c.competitorId == winnerId)
                      .toList(),
                ),
                _StatRow(
                  category: 'First 9 MPR',
                  values: allCompetitors
                      .map((c) => StatFormatter.fmtDouble(
                          c.firstNineMarksPerRound,
                          decimals: 2))
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '5 Marks',
                  values: allCompetitors
                      .map((c) => c.fiveMarkTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '6 Marks',
                  values: allCompetitors
                      .map((c) => c.sixMarkTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '7 Marks',
                  values: allCompetitors
                      .map((c) => c.sevenMarkTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '8 Marks',
                  values: allCompetitors
                      .map((c) => c.eightMarkTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '9 Marks',
                  values: allCompetitors
                      .map((c) => c.nineMarkTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
              ]
            : <_StatRow>[
                _StatRow(
                  category: 'Avg PPR',
                  values: allCompetitors
                      .map((c) => StatFormatter.fmtDouble(c.threeDartAverage))
                      .toList(),
                  highlights: allCompetitors
                      .map((c) => c.competitorId == winnerId)
                      .toList(),
                ),
                _StatRow(
                  category: 'Checkout',
                  values: allCompetitors
                      .map((c) => StatFormatter.fmtPct(c.checkoutPercentage,
                          isRatio: false))
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: 'Best Out',
                  values: allCompetitors
                      .map((c) => c.highestCheckout != null
                          ? '${c.highestCheckout}'
                          : '—')
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '180s',
                  values: allCompetitors
                      .map((c) => c.oneEightyTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '60+',
                  values: allCompetitors
                      .map((c) => c.sixtyPlusTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '100+',
                  values: allCompetitors
                      .map((c) => c.oneHundredPlusTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
                _StatRow(
                  category: '140+',
                  values: allCompetitors
                      .map((c) => c.oneFortyPlusTurns.toString())
                      .toList(),
                  highlights: noHighlight,
                ),
              ];

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
              child: Text('CATEGORY', style: headerStyle),
            ),
            ...allCompetitors.map((c) {
              final isWinner = c.competitorId == winnerId;
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
                      isWinner ? 'WINNER' : 'OPPONENT',
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
                ...List.generate(allCompetitors.length, (i) {
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

class _StatRow {
  const _StatRow({
    required this.category,
    required this.values,
    required this.highlights,
  });

  final String category;
  final List<String> values;
  final List<bool> highlights;
}
