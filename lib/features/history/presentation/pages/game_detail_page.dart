import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';
import 'package:dart_lodge/core/widgets/loading_spinner_widget.dart';
import 'package:dart_lodge/features/history/presentation/providers/game_detail_provider.dart';
import 'package:dart_lodge/features/history/presentation/state/game_detail_state.dart';
import 'package:intl/intl.dart';
import 'package:dart_lodge/features/history/presentation/widgets/game_summary_card_widget.dart';
import 'package:dart_lodge/features/history/presentation/widgets/leg_breakdown_table_widget.dart';
import 'package:dart_lodge/core/widgets/game_summary_section_widget.dart';

class GameDetailPage extends ConsumerWidget {
  final String gameId;

  const GameDetailPage({required this.gameId, super.key});

  String _formatDateTime(DateTime dt) => DateFormat('d MMM y, HH:mm').format(dt);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(gameDetailProvider(gameId));

    return Scaffold(
      appBar: AppBar(title: const Text('Game Detail')),
      body: asyncState.when(
        loading: () => const LoadingSpinnerWidget(),
        error: (e, _) => ErrorRetryWidget(
          message: 'Error: $e',
          onRetry: () => ref.invalidate(gameDetailProvider(gameId)),
        ),
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
            GameSummarySectionWidget(gameStats: detail.gameStats!),
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
            legs: detail.legStats,
            game: game,
            competitors: detail.competitors,
            events: detail.events,
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
                      Icon(Icons.emoji_events,
                          size: 18, color: AppTheme.award(context)),
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

}
