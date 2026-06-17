import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/post_game_hero_card_widget.dart';
import '../../../../core/widgets/post_game_stats_breakdown_widget.dart';
import '../../../game/domain/models/game_result.dart';

/// Post-game summary for Shanghai — hero card for the leader (or winner)
/// plus a per-player breakdown so non-winners aren't hidden when multiple
/// competitors play (#279). Solo games (single competitor) still render
/// the hero plus the legacy result rows for visual continuity.
///
/// Shares the chrome (`PostGameHeroCard`, `PostGameStatsBreakdown`) with the
/// x01/cricket summary so a single visual language covers every game type.
class ShanghaiSummaryWidget extends StatelessWidget {
  const ShanghaiSummaryWidget({super.key, required this.result});

  final ShanghaiResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final competitors = result.competitors;
    if (competitors.isEmpty) return const SizedBox.shrink();

    final winnerId = result.winnerCompetitorId;
    final winner = winnerId == null
        ? null
        : competitors
            .where((c) => c.competitorId == winnerId)
            .firstOrNull;
    // Lead is the winner if present, else the highest-scoring competitor
    // (already sorted top to bottom by `_buildShanghaiCompetitors`).
    final lead = winner ?? competitors.first;

    final hero = PostGameHeroCard(
      headline: lead.competitorName,
      subline: 'Shanghai',
      sideStats: [
        PostGameHeroStat(
          label: l10n.summaryTotalScore.toUpperCase(),
          value: '${lead.totalScore}',
          emphasize: true,
        ),
        PostGameHeroStat(
          label: l10n.statsShanghais.toUpperCase(),
          value: '${lead.shanghaiBonuses}',
        ),
      ],
    );

    // Solo path: keep the previous single-column breakdown unchanged.
    if (competitors.length == 1) {
      const noHighlight = [false];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hero,
          const SizedBox(height: 16),
          PostGameStatsBreakdown(
            columns: [PostGameBreakdownColumn(name: l10n.summaryResult)],
            rows: [
              PostGameBreakdownRow(
                category: l10n.summaryTotalScore,
                values: ['${lead.totalScore}'],
                highlights: noHighlight,
              ),
              PostGameBreakdownRow(
                category: l10n.summaryShanghaiBonuses,
                values: ['${lead.shanghaiBonuses}'],
                highlights: noHighlight,
              ),
              PostGameBreakdownRow(
                category: l10n.summaryBestRound,
                values: ['${lead.bestRound}'],
                highlights: noHighlight,
              ),
              PostGameBreakdownRow(
                category: l10n.summaryRoundsPlayed,
                values: ['${lead.roundsPlayed}'],
                highlights: noHighlight,
              ),
            ],
          ),
        ],
      );
    }

    final columns = [
      for (final c in competitors)
        PostGameBreakdownColumn(
          name: c.competitorName,
          subtitle:
              c.competitorId == winnerId ? l10n.summaryWinner.toUpperCase() : null,
          emphasize: c.competitorId == winnerId,
        ),
    ];
    PostGameBreakdownRow row(
        String category, String Function(ShanghaiCompetitorResult) cell) {
      return PostGameBreakdownRow(
        category: category,
        values: [for (final c in competitors) cell(c)],
        highlights: [for (final c in competitors) c.competitorId == winnerId],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hero,
        const SizedBox(height: 16),
        PostGameStatsBreakdown(
          columns: columns,
          rows: [
            row(l10n.summaryTotalScore, (c) => '${c.totalScore}'),
            row(l10n.summaryShanghaiBonuses, (c) => '${c.shanghaiBonuses}'),
            row(l10n.summaryBestRound, (c) => '${c.bestRound}'),
            row(l10n.summaryRoundsPlayed, (c) => '${c.roundsPlayed}'),
          ],
        ),
      ],
    );
  }
}
