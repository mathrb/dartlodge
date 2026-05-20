import 'package:flutter/material.dart';

import '../utils/app_text_styles.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/name_formatter.dart';
import '../utils/stat_formatter.dart';
import '../../features/statistics/domain/entities/game_stats.dart';
import 'post_game_hero_card_widget.dart';
import 'post_game_stats_breakdown_widget.dart';

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
          PostGameHeroCard(
            badge: 'WINNER',
            badgeIcon: Icons.stars,
            backgroundIcon: Icons.emoji_events,
            headline: winner.competitorName,
            subline: isCountUp
                ? null
                : '${winner.legsWon} LEG${winner.legsWon == 1 ? '' : 'S'} WON',
            sideStats: [
              PostGameHeroStat(
                label: isCricket ? 'AVG MPR' : 'AVG PPR',
                value: isCricket
                    ? StatFormatter.fmtDouble(winner.marksPerRound,
                        decimals: 2)
                    : StatFormatter.fmtDouble(winner.threeDartAverage),
                emphasize: true,
              ),
              PostGameHeroStat(
                label: 'DARTS',
                value: '${winner.totalDartsThrown}',
              ),
            ],
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
        PostGameStatsBreakdown(
          columns: gameStats.byCompetitor.map((c) {
            final isWinner = c.competitorId == winner?.competitorId;
            return PostGameBreakdownColumn(
              name: NameFormatter.shortName(c.competitorName),
              subtitle: isWinner ? 'WINNER' : 'OPPONENT',
              emphasize: isWinner,
            );
          }).toList(),
          rows: _buildRows(
            allCompetitors: gameStats.byCompetitor,
            winnerId: winner?.competitorId,
            isCricket: isCricket,
            isCountUp: isCountUp,
          ),
        ),
      ],
    );
  }

  List<PostGameBreakdownRow> _buildRows({
    required List<CompetitorStats> allCompetitors,
    required String? winnerId,
    required bool isCricket,
    required bool isCountUp,
  }) {
    final noHighlight = allCompetitors.map((_) => false).toList();
    final winnerHighlights =
        allCompetitors.map((c) => c.competitorId == winnerId).toList();

    if (isCountUp) {
      return [
        PostGameBreakdownRow(
          category: 'Avg PPR',
          values: allCompetitors
              .map((c) => StatFormatter.fmtDouble(c.threeDartAverage))
              .toList(),
          highlights: winnerHighlights,
        ),
        PostGameBreakdownRow(
          category: '180s',
          values:
              allCompetitors.map((c) => c.oneEightyTurns.toString()).toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: '140+',
          values: allCompetitors
              .map((c) => c.oneFortyPlusTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: '100+',
          values: allCompetitors
              .map((c) => c.oneHundredPlusTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: '60+',
          values:
              allCompetitors.map((c) => c.sixtyPlusTurns.toString()).toList(),
          highlights: noHighlight,
        ),
      ];
    }

    if (isCricket) {
      return [
        PostGameBreakdownRow(
          category: 'Avg MPR',
          values: allCompetitors
              .map((c) =>
                  StatFormatter.fmtDouble(c.marksPerRound, decimals: 2))
              .toList(),
          highlights: winnerHighlights,
        ),
        PostGameBreakdownRow(
          category: 'First 9 MPR',
          values: allCompetitors
              .map((c) => StatFormatter.fmtDouble(c.firstNineMarksPerRound,
                  decimals: 2))
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: '5 Marks',
          values: allCompetitors
              .map((c) => c.fiveMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: '6 Marks',
          values: allCompetitors
              .map((c) => c.sixMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: '7 Marks',
          values: allCompetitors
              .map((c) => c.sevenMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: '8 Marks',
          values: allCompetitors
              .map((c) => c.eightMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: '9 Marks',
          values: allCompetitors
              .map((c) => c.nineMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
      ];
    }

    return [
      PostGameBreakdownRow(
        category: 'Avg PPR',
        values: allCompetitors
            .map((c) => StatFormatter.fmtDouble(c.threeDartAverage))
            .toList(),
        highlights: winnerHighlights,
      ),
      PostGameBreakdownRow(
        category: 'Checkout',
        values: allCompetitors
            .map((c) =>
                StatFormatter.fmtPct(c.checkoutPercentage, isRatio: false))
            .toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: 'Best Out',
        values: allCompetitors
            .map((c) =>
                c.highestCheckout != null ? '${c.highestCheckout}' : '—')
            .toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: '180s',
        values:
            allCompetitors.map((c) => c.oneEightyTurns.toString()).toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: '60+',
        values:
            allCompetitors.map((c) => c.sixtyPlusTurns.toString()).toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: '100+',
        values: allCompetitors
            .map((c) => c.oneHundredPlusTurns.toString())
            .toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: '140+',
        values: allCompetitors
            .map((c) => c.oneFortyPlusTurns.toString())
            .toList(),
        highlights: noHighlight,
      ),
    ];
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
          style: AppTextStyles.scoreSmall.copyWith(
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
