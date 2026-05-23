import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_lodge/core/providers/statistics_providers.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';
import 'package:dart_lodge/core/widgets/loading_spinner_widget.dart';
import 'package:dart_lodge/features/history/presentation/providers/game_detail_provider.dart';
import 'package:dart_lodge/features/history/presentation/state/game_detail_state.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/utils/post_game_routing.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/practice_summary_widget.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/shanghai_summary_widget.dart';
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
          return _buildBody(context, ref, detail);
        },
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, GameDetailState detail) {
    final game = detail.game!;
    final theme = Theme.of(context);
    final winner = game.winnerCompetitorId;

    final sortedCompetitors = [...detail.competitors]..sort((a, b) {
        if (a.competitorId == winner) return -1;
        if (b.competitorId == winner) return 1;
        return 0;
      });

    // Leg Breakdown is only meaningful for the game-stats-backed types
    // (X01, Cricket, Count-Up) that play in legs. Practice drills and
    // Shanghai are scored across one continuous session — rendering an
    // empty "Leg Breakdown / No legs completed" section under the per-type
    // chrome is dead weight (#294).
    final showLegBreakdown = isGameStatsBacked(game.gameType.name);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchHeader(context, game, sortedCompetitors, winner, theme),
          const SizedBox(height: 16),
          _StatsSection(gameId: gameId, gameStats: detail.gameStats, game: game),
          if (showLegBreakdown) ...[
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
      cricket: (c) => switch (c.targetMode) {
        'random' => 'random ${c.scoring}',
        'crazy' => 'crazy ${c.scoring}',
        _ => c.scoring,
      },
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

/// Picks the right summary surface for [game]'s type — mirrors the
/// post-game summary's routing (#255). X01/cricket/count-up render the
/// shared `GameSummarySectionWidget` (PPR/checkout/180s for X01, MPR for
/// cricket, count-up panel for count-up); shanghai renders its dedicated
/// hero card; the four practice drills render `PracticeSummaryWidget`.
/// Without this branch, every game type rendered the X01-shaped chrome
/// (empty `—` / `0` rows, sometimes misleading PPR for drills).
class _StatsSection extends ConsumerWidget {
  const _StatsSection({
    required this.gameId,
    required this.gameStats,
    required this.game,
  });

  final String gameId;
  final GameStats? gameStats;
  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isGameStatsBacked(game.gameType.name)) {
      final stats = gameStats;
      if (stats == null) return const SizedBox.shrink();
      return GameSummarySectionWidget(gameStats: stats);
    }
    final asyncResult = ref.watch(gameResultProvider(gameId));
    return asyncResult.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('Error loading summary: $err'),
      ),
      data: (result) {
        if (result == null) return const SizedBox.shrink();
        return switch (result) {
          ShanghaiResult() => ShanghaiSummaryWidget(result: result),
          _ => PracticeSummaryWidget(result: result),
        };
      },
    );
  }
}
