import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../providers/active_cricket_game_provider.dart';
import '../widgets/cricket_unified_table_widget.dart';
import '../widgets/dart_indicator_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_complete_modal_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';

class CricketBoardPage extends ConsumerStatefulWidget {
  const CricketBoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<CricketBoardPage> createState() => _CricketBoardPageState();
}

class _CricketBoardPageState extends ConsumerState<CricketBoardPage> {
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
          body: Column(
            children: [
              DartIndicatorWidget(currentTurnDarts: currentTurnDarts),
              Expanded(
                child: CricketUnifiedTableWidget(
                  gameState: gameState,
                  onSegmentTapped: gameState.isComplete
                      ? (_) {}
                      : (segment) => notifier.processDart(segment),
                  onMiss: () => notifier.processDart('MISS'),
                  onUndo: () => notifier.undoDart(),
                ),
              ),
              _CricketBottomBar(
                dartsThrownInTurn: gameState.dartsThrownInTurn,
                isMultiplayer: gameState.competitors.length > 1,
                onNextPlayer: () => notifier.nextPlayer(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEndGameDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EndGameDialogWidget(
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          context.go(GameRoutes.home);
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _CricketBottomBar extends StatelessWidget {
  const _CricketBottomBar({
    required this.dartsThrownInTurn,
    required this.isMultiplayer,
    required this.onNextPlayer,
  });

  final int dartsThrownInTurn;
  final bool isMultiplayer;
  final VoidCallback onNextPlayer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = isMultiplayer ? 'NEXT PLAYER' : 'NEXT ROUND';

    Future<void> handleAdvance() async {
      if (dartsThrownInTurn >= 3) {
        onNextPlayer();
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => _AdvanceTurnConfirmDialog(
            dartsThrownInTurn: dartsThrownInTurn,
          ),
        );
        if (confirmed == true) onNextPlayer();
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outline, width: 1)),
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: SizedBox.shrink()),
              GestureDetector(
                onTap: handleAdvance,
                child: Container(
                  width: 168,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      left: BorderSide(color: cs.outline, width: 1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: cs.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvanceTurnConfirmDialog extends StatelessWidget {
  const _AdvanceTurnConfirmDialog({required this.dartsThrownInTurn});
  final int dartsThrownInTurn;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Advance turn?'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: [screenWidth - 48, 320.0].reduce((a, b) => a < b ? a : b),
        ),
        child: Text(
          "You've only thrown $dartsThrownInTurn dart(s). Advance anyway?",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

