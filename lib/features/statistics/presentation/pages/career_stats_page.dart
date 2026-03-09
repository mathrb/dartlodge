import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_darts/features/players/presentation/providers/players_provider.dart';
import 'package:my_darts/features/statistics/domain/entities/player_stats.dart';
import 'package:my_darts/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:my_darts/features/statistics/presentation/widgets/stats_card_widget.dart';

class CareerStatsPage extends ConsumerWidget {
  final String playerId;

  const CareerStatsPage({required this.playerId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider(playerId));
    final statsAsync = ref.watch(playerStatsProvider(playerId));

    final playerName = playerAsync.whenOrNull(data: (p) => p?.name) ?? 'Player';

    return Scaffold(
      appBar: AppBar(title: Text('$playerName — Career Stats')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(playerStatsProvider(playerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => _StatsBody(stats: stats),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final PlayerStats stats;

  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Summary'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              StatsCardWidget(
                label: '3-Dart Avg',
                value: StatsCardWidget.format(stats.threeDartAverage),
              ),
              StatsCardWidget(
                label: 'Checkout %',
                value: StatsCardWidget.format(stats.checkoutPercentage),
              ),
              StatsCardWidget(
                label: 'Win Rate %',
                value: StatsCardWidget.format(stats.winRate),
              ),
              StatsCardWidget(
                label: 'Darts / Leg',
                value: StatsCardWidget.format(stats.dartsPerLeg),
              ),
              StatsCardWidget(
                label: 'Legs Played',
                value: StatsCardWidget.formatInt(stats.totalGames),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionHeader('Highlights'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatsCardWidget(
                  label: 'Highest Checkout',
                  value: StatsCardWidget.formatInt(stats.highestCheckout),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatsCardWidget(
                  label: 'Best Turn',
                  value: StatsCardWidget.formatInt(stats.highestTurnScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionHeader('Trends'),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Trend data coming soon')),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Legs Won: ${stats.gamesWon} / ${stats.totalGames}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
