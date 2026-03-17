import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import 'stats_card_widget.dart';

class SummaryCardsRowWidget extends StatelessWidget {
  final PlayerStats stats;

  const SummaryCardsRowWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatsCardWidget(
            label: 'Legs Played',
            value: stats.legsPlayed.toString(),
          ),
        ),
        Expanded(
          child: StatsCardWidget(
            label: 'Legs Won',
            value: stats.legsWon.toString(),
          ),
        ),
        Expanded(
          child: StatsCardWidget(
            label: 'Games Played',
            value: stats.totalGames.toString(),
          ),
        ),
      ],
    );
  }
}
