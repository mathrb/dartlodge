import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../features/statistics/presentation/widgets/stats_overlay_widget.dart';
import '../providers/active_game_provider.dart';
import '../widgets/bust_overlay_widget.dart';
import '../widgets/dart_indicator_widget.dart';
import '../widgets/dart_input_grid_widget.dart';
import '../widgets/game_complete_modal_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';
import '../widgets/player_score_section_widget.dart';

class X01BoardPage extends ConsumerStatefulWidget {
  const X01BoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<X01BoardPage> createState() => _X01BoardPageState();
}

class _X01BoardPageState extends ConsumerState<X01BoardPage> {
  bool _showStatsOverlay = false;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(activeGameProvider(widget.gameId));

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
                    .read(activeGameProvider(widget.gameId).notifier)
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

        Widget body = Column(
          children: [
            DartIndicatorWidget(dartsThrown: gameState.dartsThrownInTurn),
            PlayerScoreSectionWidget(gameState: gameState),
            Expanded(
              child: DartInputGridWidget(
                onSegmentTapped: (segment) => ref
                    .read(activeGameProvider(widget.gameId).notifier)
                    .processDart(segment),
                enabled: !gameState.isComplete,
              ),
            ),
            _BottomBar(
              canUndo: !gameState.isComplete &&
                  (gameState.dartsThrownInTurn > 0 ||
                      gameState.competitors
                          .any((c) => c.dartThrows.isNotEmpty)),
              onUndo: () =>
                  ref.read(activeGameProvider(widget.gameId).notifier).undoDart(),
              onNextRound: () {
                final notifier =
                    ref.read(activeGameProvider(widget.gameId).notifier);
                notifier.dismissBust();
                notifier.dismissLegModal();
              },
            ),
          ],
        );

        final stackChildren = <Widget>[body];

        if (activeGameState.showBust) {
          stackChildren.add(
            BustOverlayWidget(
              onDismiss: () => ref
                  .read(activeGameProvider(widget.gameId).notifier)
                  .dismissBust(),
            ),
          );
        }

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
                Text('${gameState.startingScore}'),
                Text(
                  'Leg ${gameState.currentLegIndex + 1} of ${gameState.legsToWin}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
              ),
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
    required this.canUndo,
    required this.onUndo,
    required this.onNextRound,
  });

  final bool canUndo;
  final VoidCallback onUndo;
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
          FilledButton(
            onPressed: onNextRound,
            child: const Text('NEXT ROUND'),
          ),
        ],
      ),
    );
  }
}
