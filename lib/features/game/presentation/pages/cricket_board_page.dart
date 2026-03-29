import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../providers/active_cricket_game_provider.dart';
import '../widgets/cricket_unified_table_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_complete_modal_widget.dart';
import '../widgets/game_status_bar_widget.dart';
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
          'tactics' => 'Tactics',
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

        final dartsThrownInTurn = gameState.dartsThrownInTurn;
        final canUndo = dartsThrownInTurn > 0 ||
            gameState.competitors.any((c) => c.dartThrows.isNotEmpty);
        final canNext = !gameState.isComplete;

        return Scaffold(
          appBar: AppHeader(
            boardMode: true,
            showBack: true,
            onBack: () => context.go(GameRoutes.home),
            trailing: InkWell(
              onTap: () => _showEndGameDialog(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              splashColor: AppTheme.kineticSplashColor,
              highlightColor: AppTheme.kineticSplashColor,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                  semanticLabel: 'Game options',
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              GameStatusBarWidget(
                configLabel: variantLabel,
                currentLegIndex: gameState.currentLegIndex,
                legsToWin: gameState.legsToWin,
                roundInLeg: gameState.currentRoundInLeg,
                currentTurnDarts: currentTurnDarts,
              ),
              Expanded(
                child: CricketUnifiedTableWidget(
                  gameState: gameState,
                  onSegmentTapped: gameState.isComplete
                      ? (_) {}
                      : (segment) => notifier.processDart(segment),
                  onMiss: () => notifier.processDart('MISS'),
                ),
              ),
              _BottomActionBar(
                canUndo: canUndo,
                canNext: canNext,
                isMultiplayer: gameState.competitors.length > 1,
                dartsThrownInTurn: dartsThrownInTurn,
                onUndo: () => notifier.undoDart(),
                onNextRound: () => notifier.nextPlayer(),
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.canUndo,
    required this.canNext,
    required this.isMultiplayer,
    required this.dartsThrownInTurn,
    required this.onUndo,
    required this.onNextRound,
  });

  final bool canUndo;
  final bool canNext;
  final bool isMultiplayer;
  final int dartsThrownInTurn;
  final VoidCallback onUndo;
  final VoidCallback onNextRound;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Future<void> handleAdvance() async {
      if (dartsThrownInTurn >= 3) {
        onNextRound();
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => _AdvanceTurnConfirmDialog(
            dartsThrownInTurn: dartsThrownInTurn,
          ),
        );
        if (confirmed == true) onNextRound();
      }
    }

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          border: Border(
            top: BorderSide(
              color: cs.surfaceContainer.withValues(alpha: 0.3),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Row(
          children: [
            // Undo — square button
            Opacity(
              opacity: canUndo ? 1.0 : 0.38,
              child: InkWell(
                onTap: canUndo ? onUndo : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                splashColor: AppTheme.kineticSplashColor,
                highlightColor: AppTheme.kineticSplashColor,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.undo,
                    color: cs.onSurface,
                    semanticLabel: 'Undo last dart',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Next player / round — primary neon button
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primaryFixed,
                  foregroundColor: AppColors.onPrimaryFixed,
                  disabledBackgroundColor:
                      cs.primaryFixed.withValues(alpha: 0.38),
                  disabledForegroundColor:
                      AppColors.onPrimaryFixed.withValues(alpha: 0.38),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                onPressed: canNext ? handleAdvance : null,
                icon: const Icon(Icons.arrow_forward, semanticLabel: ''),
                label: Text(isMultiplayer ? 'NEXT PLAYER' : 'NEXT ROUND'),
              ),
            ),
          ],
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
