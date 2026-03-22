import 'package:flutter/material.dart';

import '../../../../core/utils/stat_formatter.dart';
import '../../domain/entities/player_stats.dart';
import 'stats_card_widget.dart';

class LeaderboardRowWidget extends StatelessWidget {
  final int rank;
  final PlayerStats stats;
  final String metric;

  const LeaderboardRowWidget({
    required this.rank,
    required this.stats,
    required this.metric,
    super.key,
  });

  String _metricValue() {
    switch (metric) {
      case 'threeDartAverage':
        return StatsCardWidget.format(stats.threeDartAverage);
      case 'checkoutPercentage':
        return StatFormatter.fmtPct(stats.checkoutPercentage, isRatio: false);
      case 'winRate':
        return StatFormatter.fmtPct(stats.winRate);
      case 'dartsPerLeg':
        return StatsCardWidget.format(stats.dartsPerLeg);
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isFirst ? Colors.amber : null,
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isFirst ? Colors.black : null,
          ),
        ),
      ),
      title: Text(stats.playerId),
      subtitle: Text('${stats.totalGames} games played'),
      trailing: Text(
        _metricValue(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
