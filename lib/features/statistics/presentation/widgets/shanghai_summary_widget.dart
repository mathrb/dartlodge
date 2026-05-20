import 'package:flutter/material.dart';

import '../../../../core/widgets/post_game_hero_card_widget.dart';
import '../../../../core/widgets/post_game_stats_breakdown_widget.dart';
import '../../../game/domain/models/game_result.dart';

/// Post-game summary for Shanghai — hero card showing the total score and
/// a breakdown table with the four result rows.
///
/// Shares the chrome (`PostGameHeroCard`, `PostGameStatsBreakdown`) with the
/// x01/cricket summary so a single visual language covers every game type.
class ShanghaiSummaryWidget extends StatelessWidget {
  const ShanghaiSummaryWidget({super.key, required this.result});

  final ShanghaiResult result;

  @override
  Widget build(BuildContext context) {
    final noHighlight = [false];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostGameHeroCard(
          headline: result.competitorName,
          subline: 'Shanghai',
          sideStats: [
            PostGameHeroStat(
              label: 'TOTAL SCORE',
              value: '${result.totalScore}',
              emphasize: true,
            ),
            PostGameHeroStat(
              label: 'SHANGHAIS',
              value: '${result.shanghaiBonuses}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        PostGameStatsBreakdown(
          columns: const [
            PostGameBreakdownColumn(name: 'Result'),
          ],
          rows: [
            PostGameBreakdownRow(
              category: 'Total score',
              values: ['${result.totalScore}'],
              highlights: noHighlight,
            ),
            PostGameBreakdownRow(
              category: 'Shanghai bonuses',
              values: ['${result.shanghaiBonuses}'],
              highlights: noHighlight,
            ),
            PostGameBreakdownRow(
              category: 'Best round',
              values: ['${result.bestRound}'],
              highlights: noHighlight,
            ),
            PostGameBreakdownRow(
              category: 'Rounds played',
              values: ['${result.roundsPlayed}'],
              highlights: noHighlight,
            ),
          ],
        ),
      ],
    );
  }
}
