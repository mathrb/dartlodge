import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../domain/entities/player_stats.dart';
import 'stats_card_row_widget.dart';
import 'stats_card_widget.dart';

/// The headline at the top of the X01 and Cricket stats tabs: the numbers a
/// player checks first. X01 = 3-dart average (PPR) and checkout %; Cricket =
/// MPR and hit rate. A line below gives legs won / played and the number of
/// games.
///
/// Two cards, not three: at 412 px a third of the row is too narrow for a
/// `scoreSmall` value such as "30.4%", so three cards would stack for most
/// players (StatsCardRowWidget).
class SummaryCardsRowWidget extends StatelessWidget {
  final PlayerStats stats;

  const SummaryCardsRowWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isCricket = stats.gameType == GameType.cricket;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsCardRowWidget(
          cards: isCricket
              ? [
                  StatsCardWidget(
                    label: 'MPR',
                    value: StatFormatter.fmtDouble(
                      stats.marksPerTurn,
                      decimals: 2,
                    ),
                  ),
                  StatsCardWidget(
                    label: l10n.statsHitRate,
                    value: StatFormatter.fmtPct(stats.hitRate),
                  ),
                ]
              : [
                  StatsCardWidget(
                    label: 'PPR',
                    value: StatFormatter.fmtDouble(stats.threeDartAverage),
                  ),
                  StatsCardWidget(
                    label: l10n.statsCheckoutPct,
                    value: StatFormatter.fmtPct(
                      stats.checkoutPercentage,
                      isRatio: false,
                    ),
                  ),
                ],
        ),
        Padding(
          // Lines up with the cards' text (Card margin 4 + padding 12).
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space1,
            AppSpacing.space4,
            0,
          ),
          child: Text(
            '${l10n.statsLegsWonOfPlayed(stats.legsWon, stats.legsPlayed)}'
            ' · ${l10n.statsGamesCount(stats.totalGames)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
