import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../features/statistics/presentation/widgets/stats_overlay_widget.dart';
import '../providers/active_cricket_game_provider.dart';
import '../widgets/cricket_unified_table_widget.dart';
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

        final activeCompetitor =
            gameState.competitors[gameState.currentTurnIndex];
        final allDarts = activeCompetitor.dartThrows;
        final n = gameState.dartsThrownInTurn;
        final currentTurnDarts = n == 0 || allDarts.length < n
            ? <String>[]
            : allDarts.sublist(allDarts.length - n);

        final notifier =
            ref.read(activeCricketGameProvider(widget.gameId).notifier);

        final boardBody = SingleChildScrollView(
          child: Column(
            children: [
              DartIndicatorWidget(currentTurnDarts: currentTurnDarts),
              CricketUnifiedTableWidget(
                gameState: gameState,
                onSegmentTapped: gameState.isComplete
                    ? (_) {}
                    : (segment) => notifier.processDart(segment),
                onMiss: () => notifier.processDart('MISS'),
                onUndo: () => notifier.undoDart(),
                onNextPlayer: () => notifier.nextPlayer(),
              ),
            ],
          ),
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
            automaticallyImplyLeading: false,
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
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'end') _showEndGameDialog(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'end',
                    child: Text('End Game'),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.small(
            backgroundColor:
                Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor:
                Theme.of(context).colorScheme.onSecondaryContainer,
            onPressed: () =>
                setState(() => _showStatsOverlay = !_showStatsOverlay),
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

  void _showEndGameDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _EndGameDialog(
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          context.go(GameRoutes.home);
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

class _EndGameDialog extends StatelessWidget {
  const _EndGameDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('End Game?'),
      content: Text(
        'The current game will be abandoned.',
        style: tt.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: cs.onSurface),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          onPressed: onConfirm,
          child: const Text('End Game'),
        ),
      ],
    );
  }
}
