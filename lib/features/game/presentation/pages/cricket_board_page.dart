import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../features/statistics/presentation/widgets/stats_overlay_widget.dart';
import '../providers/active_cricket_game_provider.dart';
import '../widgets/cricket_grid_widget.dart';
import '../widgets/cricket_score_sidebar_widget.dart';
import '../widgets/dart_indicator_widget.dart';
import '../widgets/game_complete_modal_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';

class CricketBoardPage extends ConsumerStatefulWidget {
  const CricketBoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<CricketBoardPage> createState() => _CricketBoardPageState();
}

class _CricketBoardPageState extends ConsumerState<CricketBoardPage> {
  bool _showStatsOverlay = false;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(activeCricketGameProvider(widget.gameId));

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
                    .read(activeCricketGameProvider(widget.gameId).notifier)
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
                onViewStats: () => context.go('/post-game/${widget.gameId}'),
              ),
            );
          });
        }

        final variantLabel = switch (gameState.cricketVariant) {
          'cut-throat' => 'Cut Throat',
          'no-score' => 'No Score',
          _ => 'Standard',
        };

        final boardBody = Column(
          children: [
            DartIndicatorWidget(dartsThrown: gameState.dartsThrownInTurn),
            CricketScoreSidebarWidget(gameState: gameState),
            Expanded(
              child: CricketGridWidget(
                gameState: gameState,
                onSegmentTapped: gameState.isComplete
                    ? (_) {}
                    : (segment) => ref
                        .read(activeCricketGameProvider(widget.gameId).notifier)
                        .processDart(segment),
              ),
            ),
            _BottomBar(
              enabled: !gameState.isComplete,
              canUndo: !gameState.isComplete &&
                  (gameState.dartsThrownInTurn > 0 ||
                      gameState.competitors
                          .any((c) => c.dartThrows.isNotEmpty)),
              onUndo: () => ref
                  .read(activeCricketGameProvider(widget.gameId).notifier)
                  .undoDart(),
              onMiss: () => ref
                  .read(activeCricketGameProvider(widget.gameId).notifier)
                  .processDart('MISS'),
              onNextRound: () => ref
                  .read(activeCricketGameProvider(widget.gameId).notifier)
                  .dismissLegModal(),
            ),
          ],
        );

        final stackChildren = <Widget>[boardBody];

        if (_showStatsOverlay) {
          stackChildren.add(
            GestureDetector(
              onTap: () => setState(() => _showStatsOverlay = false),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          );
          stackChildren.add(
            Align(
              alignment: Alignment.bottomCenter,
              child: StatsOverlayWidget(
                gameId: widget.gameId,
                onDismiss: () => setState(() => _showStatsOverlay = false),
              ),
            ),
          );
        }

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
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => setState(() => _showStatsOverlay = !_showStatsOverlay),
            child: const Icon(Icons.bar_chart),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: stackChildren,
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.enabled,
    required this.canUndo,
    required this.onUndo,
    required this.onMiss,
    required this.onNextRound,
  });

  final bool enabled;
  final bool canUndo;
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
            onPressed: canUndo ? onUndo : null,
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
