import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final winner = _findWinner();
    final isCricket = gameStats.gameType == GameType.cricket.name;
    final isCountUp = gameStats.gameType == GameType.countUp.name;
    final opponents = winner == null
        ? gameStats.byCompetitor
        : gameStats.byCompetitor
            .where((c) => c.competitorId != winner.competitorId)
            .toList();
    // Count-Up's runner-ups all get "OPPONENT" today — but they're really
    // 2nd, 3rd, … by total score. Every competitor throws the same number
    // of darts (the configured round count × 3), so `threeDartAverage`
    // (PPR = totalScore / totalDarts × 3) is a faithful proxy for total
    // score and sorts the same way. Drives the per-card ordinal label
    // below (#261).
    if (isCountUp) {
      opponents.sort(
          (a, b) => b.threeDartAverage.compareTo(a.threeDartAverage));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (winner != null) ...[
          PostGameHeroCard(
            badge: l10n.summaryWinner.toUpperCase(),
            badgeIcon: Icons.stars,
            backgroundIcon: Icons.emoji_events,
            headline: winner.competitorName,
            subline: isCountUp
                ? null
                : l10n.summaryLegsWon(winner.legsWon).toUpperCase(),
            sideStats: [
              PostGameHeroStat(
                label: (isCricket ? l10n.statAvgMpr : l10n.statAvgPpr)
                    .toUpperCase(),
                value: isCricket
                    ? StatFormatter.fmtDouble(winner.marksPerRound,
                        decimals: 2)
                    : StatFormatter.fmtDouble(winner.threeDartAverage),
                emphasize: true,
              ),
              PostGameHeroStat(
                label: l10n.summaryDarts.toUpperCase(),
                value: '${winner.totalDartsThrown}',
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (opponents.isNotEmpty) ...[
          ...opponents.asMap().entries.map((entry) {
            final rank = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OpponentCard(
                stats: entry.value,
                isCricket: isCricket,
                // Count-Up: opponents are sorted by score above, so index 0
                // is 2nd place, index 1 is 3rd, etc. Other modes keep the
                // generic "OPPONENT" subtitle.
                label: isCountUp
                    ? '#${rank + 2}'
                    : l10n.summaryOpponent.toUpperCase(),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        Builder(builder: (_) {
          // Count-Up: order competitors by score (PPR proxy) descending so
          // columns appear left → right in the same order as the ordinal-
          // labelled cards above. CRITICAL: the same ordering must drive
          // BOTH columns and rows — `PostGameBreakdownRow.values` is
          // index-aligned to `columns`, so passing the unsorted list to
          // `_buildRows` would put each competitor's stats in the wrong
          // column header. Other modes keep the original order with a
          // binary WINNER / OPPONENT subtitle.
          final ordered = isCountUp
              ? ([...gameStats.byCompetitor]
                ..sort((a, b) =>
                    b.threeDartAverage.compareTo(a.threeDartAverage)))
              : gameStats.byCompetitor;
          return PostGameStatsBreakdown(
            columns: ordered.asMap().entries.map((entry) {
              final c = entry.value;
              final isWinner = c.competitorId == winner?.competitorId;
              final String subtitle;
              if (isCountUp) {
                subtitle =
                    isWinner ? l10n.summaryWinner.toUpperCase() : '#${entry.key + 1}';
              } else {
                subtitle = (isWinner ? l10n.summaryWinner : l10n.summaryOpponent)
                    .toUpperCase();
              }
              return PostGameBreakdownColumn(
                name: NameFormatter.shortName(c.competitorName),
                subtitle: subtitle,
                emphasize: isWinner,
              );
            }).toList(),
            rows: _buildRows(
              l10n: l10n,
              allCompetitors: ordered,
              winnerId: winner?.competitorId,
              isCricket: isCricket,
              isCountUp: isCountUp,
            ),
          );
        }),
      ],
    );
  }

  List<PostGameBreakdownRow> _buildRows({
    required AppLocalizations l10n,
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
          category: l10n.statAvgPpr,
          values: allCompetitors
              .map((c) => StatFormatter.fmtDouble(c.threeDartAverage))
              .toList(),
          highlights: winnerHighlights,
        ),
        PostGameBreakdownRow(
          category: l10n.stat180s,
          values:
              allCompetitors.map((c) => c.oneEightyTurns.toString()).toList(),
          highlights: noHighlight,
        ),
        // High-score buckets are mutually exclusive; labels match the
        // actual range so they don't read as cumulative "100+" / "140+"
        // (#290 finishes the rename started in #261 for the 60+ bucket).
        PostGameBreakdownRow(
          category: l10n.stat140179,
          values: allCompetitors
              .map((c) => c.oneFortyPlusTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: l10n.stat100139,
          values: allCompetitors
              .map((c) => c.oneHundredPlusTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: l10n.stat6099,
          values:
              allCompetitors.map((c) => c.sixtyPlusTurns.toString()).toList(),
          highlights: noHighlight,
        ),
      ];
    }

    if (isCricket) {
      return [
        PostGameBreakdownRow(
          category: l10n.statAvgMpr,
          values: allCompetitors
              .map((c) =>
                  StatFormatter.fmtDouble(c.marksPerRound, decimals: 2))
              .toList(),
          highlights: winnerHighlights,
        ),
        PostGameBreakdownRow(
          category: l10n.statFirst9Mpr,
          values: allCompetitors
              .map((c) => StatFormatter.fmtDouble(c.firstNineMarksPerRound,
                  decimals: 2))
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: l10n.stat5Marks,
          values: allCompetitors
              .map((c) => c.fiveMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: l10n.stat6Marks,
          values: allCompetitors
              .map((c) => c.sixMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: l10n.stat7Marks,
          values: allCompetitors
              .map((c) => c.sevenMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: l10n.stat8Marks,
          values: allCompetitors
              .map((c) => c.eightMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
        PostGameBreakdownRow(
          category: l10n.stat9Marks,
          values: allCompetitors
              .map((c) => c.nineMarkTurns.toString())
              .toList(),
          highlights: noHighlight,
        ),
      ];
    }

    return [
      PostGameBreakdownRow(
        category: l10n.statAvgPpr,
        values: allCompetitors
            .map((c) => StatFormatter.fmtDouble(c.threeDartAverage))
            .toList(),
        highlights: winnerHighlights,
      ),
      PostGameBreakdownRow(
        category: l10n.statCheckout,
        values: allCompetitors
            .map((c) =>
                StatFormatter.fmtPct(c.checkoutPercentage, isRatio: false))
            .toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: l10n.statBestOut,
        values: allCompetitors
            .map((c) =>
                c.highestCheckout != null ? '${c.highestCheckout}' : '—')
            .toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: l10n.stat180s,
        values:
            allCompetitors.map((c) => c.oneEightyTurns.toString()).toList(),
        highlights: noHighlight,
      ),
      // High-score buckets are mutually exclusive; labels match the
      // actual range so they don't read as cumulative "100+" / "140+"
      // (#290 finishes the rename started in #261 for the 60+ bucket).
      PostGameBreakdownRow(
        category: l10n.stat6099,
        values:
            allCompetitors.map((c) => c.sixtyPlusTurns.toString()).toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: l10n.stat100139,
        values: allCompetitors
            .map((c) => c.oneHundredPlusTurns.toString())
            .toList(),
        highlights: noHighlight,
      ),
      PostGameBreakdownRow(
        category: l10n.stat140179,
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
  const _OpponentCard({
    required this.stats,
    required this.isCricket,
    this.label = 'OPPONENT',
  });

  final CompetitorStats stats;
  final bool isCricket;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

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
                  label,
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
                label: l10n.summaryDarts.toUpperCase(),
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
