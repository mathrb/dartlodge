import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/game_stats.dart';
import '../providers/statistics_provider.dart';

class PostGameSummaryPage extends ConsumerWidget {
  const PostGameSummaryPage({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(liveGameStatsProvider(gameId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Summary'),
        automaticallyImplyLeading: false,
      ),
      body: asyncStats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (gameStats) {
          if (gameStats == null) {
            return const Center(child: Text('No stats available'));
          }
          return _SummaryBody(gameStats: gameStats);
        },
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.gameStats});

  final GameStats gameStats;

  CompetitorStats? _winner() {
    if (gameStats.byCompetitor.isEmpty) return null;
    return gameStats.byCompetitor.reduce(
      (a, b) => a.legsWon >= b.legsWon ? a : b,
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = _winner();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...gameStats.byCompetitor.map(
            (cs) => _CompetitorCard(
              stats: cs,
              isWinner: winner != null && cs.competitorId == winner.competitorId,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go('/game-setup'),
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompetitorCard extends StatelessWidget {
  const _CompetitorCard({required this.stats, required this.isWinner});

  final CompetitorStats stats;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isWinner
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stats.competitorName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (isWinner)
                  Chip(
                    label: const Text('Winner'),
                    backgroundColor: Colors.amber,
                    labelStyle: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                  label: 'Avg',
                  value: stats.threeDartAverage.toStringAsFixed(1),
                ),
                _StatColumn(
                  label: 'Legs Won',
                  value: '${stats.legsWon}',
                ),
                _StatColumn(
                  label: 'Darts',
                  value: '${stats.totalDartsThrown}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
