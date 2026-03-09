import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/history/presentation/providers/game_detail_provider.dart';
import 'package:my_darts/features/history/presentation/state/game_detail_state.dart';
import 'package:my_darts/features/history/presentation/widgets/game_summary_card_widget.dart';
import 'package:my_darts/features/history/presentation/widgets/leg_breakdown_table_widget.dart';
import 'package:my_darts/features/statistics/domain/entities/game_stats.dart';
// Cross-feature import: StatsCardWidget is a pure display widget with no domain logic
import 'package:my_darts/features/statistics/presentation/widgets/stats_card_widget.dart';

class GameDetailPage extends ConsumerWidget {
  final String gameId;

  const GameDetailPage({required this.gameId, super.key});

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDateTime(DateTime dt) =>
      '${dt.day} ${_monthAbbr[dt.month - 1]} ${dt.year}, '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(gameDetailProvider(gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('Game Detail')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Game not found'));
          }
          return _buildBody(context, detail);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, GameDetailState detail) {
    final game = detail.game!;
    final theme = Theme.of(context);
    final winner = game.winnerCompetitorId;

    final sortedCompetitors = [...detail.competitors]..sort((a, b) {
        if (a.competitorId == winner) return -1;
        if (b.competitorId == winner) return 1;
        return 0;
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchHeader(context, game, sortedCompetitors, winner, theme),
          if (detail.gameStats != null) ...[
            const SizedBox(height: 16),
            _buildStatsSection(context, detail.gameStats!, sortedCompetitors, theme),
          ],
          const SizedBox(height: 16),
          Text(
            'Leg Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LegBreakdownTableWidget(
            events: detail.events,
            darts: detail.darts,
            competitors: detail.competitors,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHeader(
    BuildContext context,
    Game game,
    List<Competitor> sortedCompetitors,
    String? winner,
    ThemeData theme,
  ) {
    final variant = game.config.maybeMap(
      x01: (c) => '${c.startingScore}',
      cricket: (c) => c.variant,
      aroundTheClock: (c) => c.variant,
      orElse: () => '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    GameSummaryCardWidget.gameTypeName(game.gameType),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (variant.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(variant, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            if (game.endTime != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatDateTime(game.endTime!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            ...sortedCompetitors.map((c) {
              final isWinner = c.competitorId == winner;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    if (isWinner)
                      const Icon(Icons.emoji_events,
                          size: 18, color: Colors.amber),
                    if (isWinner) const SizedBox(width: 6),
                    Text(
                      c.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isWinner ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    GameStats gameStats,
    List<Competitor> sortedCompetitors,
    ThemeData theme,
  ) {
    final statsByComp = {
      for (final cs in gameStats.byCompetitor) cs.competitorId: cs,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stats',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedCompetitors.map((c) {
          final cs = statsByComp[c.competitorId];
          if (cs == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatsCardWidget(
                      label: '3-Dart Avg',
                      value: StatsCardWidget.format(cs.threeDartAverage),
                    ),
                    StatsCardWidget(
                      label: 'Legs Won',
                      value: StatsCardWidget.formatInt(cs.legsWon),
                    ),
                    StatsCardWidget(
                      label: 'Total Darts',
                      value: StatsCardWidget.formatInt(cs.totalDartsThrown),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
