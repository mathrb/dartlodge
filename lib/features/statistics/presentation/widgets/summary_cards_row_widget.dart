import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../domain/entities/player_stats.dart';
import 'stats_card_row_widget.dart';
import 'stats_card_widget.dart';

class SummaryCardsRowWidget extends StatelessWidget {
  final PlayerStats stats;

  const SummaryCardsRowWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StatsCardRowWidget(
      cards: [
        StatsCardWidget(
          label: l10n.statsLegsPlayed,
          value: stats.legsPlayed.toString(),
        ),
        StatsCardWidget(
          label: l10n.statsLegsWon,
          value: stats.legsWon.toString(),
        ),
        StatsCardWidget(
          label: l10n.statsGamesPlayed,
          value: stats.totalGames.toString(),
        ),
      ],
    );
  }
}
