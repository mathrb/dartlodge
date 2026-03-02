import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../providers/active_cricket_game_provider.dart';
import '../widgets/cricket_grid_widget.dart';
import '../widgets/cricket_score_sidebar_widget.dart';
import '../widgets/dart_indicator_widget.dart';
import '../widgets/game_complete_modal_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';

class CricketBoardPage extends ConsumerWidget {
  const CricketBoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(activeCricketGameProvider(gameId));

    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (activeGameState) {
        if (activeGameState == null) {
          return const Scaffold(
            body: Center(child: Text('Game not found')),
          );
        }

        final gameState = activeGameState.gameState;

        if (activeGameState.pendingLegWinnerId != null) {
          final winner = gameState.competitors.firstWhere(
            (c) => c.competitorId == activeGameState.pendingLegWinnerId,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => LegCompleteModalWidget(
                winnerName: winner.name,
                legNumber: gameState.currentLegIndex,
                onNextLeg: () => ref
                    .read(activeCricketGameProvider(gameId).notifier)
                    .dismissLegModal(),
              ),
            );
          });
        } else if (activeGameState.pendingGameWinnerId != null) {
          final winner = gameState.competitors.firstWhere(
            (c) => c.competitorId == activeGameState.pendingGameWinnerId,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => GameCompleteModalWidget(
                winnerName: winner.name,
                onNewGame: () => context.go(GameRoutes.home),
                onViewStats: () => context.go('/stats'),
              ),
            );
          });
        }

        final variantLabel = switch (gameState.cricketVariant) {
          'cut-throat' => 'Cut Throat',
          'no-score' => 'No Score',
          _ => 'Standard',
        };

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cricket'),
                Text(
                  '$variantLabel · Leg ${gameState.currentLegIndex + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              DartIndicatorWidget(dartsThrown: gameState.dartsThrownInTurn),
              CricketScoreSidebarWidget(gameState: gameState),
              Expanded(
                child: CricketGridWidget(
                  gameState: gameState,
                  onSegmentTapped: gameState.isComplete
                      ? (_) {}
                      : (segment) => ref
                          .read(activeCricketGameProvider(gameId).notifier)
                          .processDart(segment),
                ),
              ),
              _BottomBar(
                enabled: !gameState.isComplete,
                onUndo: () => ref
                    .read(activeCricketGameProvider(gameId).notifier)
                    .undoDart(),
                onMiss: () => ref
                    .read(activeCricketGameProvider(gameId).notifier)
                    .processDart('MISS'),
                onNextRound: () => ref
                    .read(activeCricketGameProvider(gameId).notifier)
                    .dismissLegModal(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.enabled,
    required this.onUndo,
    required this.onMiss,
    required this.onNextRound,
  });

  final bool enabled;
  final VoidCallback onUndo;
  final VoidCallback onMiss;
  final VoidCallback onNextRound;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: enabled ? onUndo : null,
          ),
          OutlinedButton(
            onPressed: enabled ? onMiss : null,
            child: const Text('MISS'),
          ),
          FilledButton(
            onPressed: enabled ? onNextRound : null,
            child: const Text('NEXT ROUND'),
          ),
        ],
      ),
    );
  }
}
