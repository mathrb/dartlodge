import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/active_cricket_game_provider.dart';
import '../widgets/cap_winner_selection_dialog_widget.dart';
import '../widgets/cricket_unified_table_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_complete_modal_widget.dart';
import '../widgets/game_status_bar_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';
import '../widgets/pulsing_next_button_widget.dart';

class CricketBoardPage extends ConsumerStatefulWidget {
  const CricketBoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<CricketBoardPage> createState() => _CricketBoardPageState();
}

class _CricketBoardPageState extends ConsumerState<CricketBoardPage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    ref.listen(activeCricketGameProvider(widget.gameId), (prev, next) {
      final prevValue = prev?.value;
      final nextValue = next.value;
      if (nextValue == null) return;
      final gs = nextValue.gameState;

      final prevCap = prevValue?.pendingCapSelection ?? false;
      if (!prevCap && nextValue.pendingCapSelection) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => CapWinnerSelectionDialogWidget(
              competitors: gs.competitors,
              onSelect: (id) => ref
                  .read(activeCricketGameProvider(widget.gameId).notifier)
                  .selectCapWinner(id),
            ),
          );
        });
      }

      final prevLeg = prevValue?.pendingLegWinnerId;
      final nextLeg = nextValue.pendingLegWinnerId;
      if (prevLeg == null && nextLeg != null) {
        final winner =
            gs.competitors.firstWhere((c) => c.competitorId == nextLeg);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => LegCompleteModalWidget(
              winnerName: winner.name,
              legNumber: gs.currentLegIndex,
              onNextLeg: () => ref
                  .read(activeCricketGameProvider(widget.gameId).notifier)
                  .dismissLegModal(),
            ),
          );
        });
      }

      final prevComplete = prevValue?.gameState.isComplete ?? false;
      if (!prevComplete && gs.isComplete) {
        final winnerId = nextValue.pendingGameWinnerId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (winnerId == null) {
            context.go('/post-game/${widget.gameId}');
            return;
          }
          final winner =
              gs.competitors.firstWhere((c) => c.competitorId == winnerId);
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
    });

    final asyncState = ref.watch(activeCricketGameProvider(widget.gameId));

    return asyncState.when(
      loading: () => const Scaffold(
        body: LoadingSpinnerWidget(),
      ),
      error: (err, _) => Scaffold(
        body: ErrorRetryWidget(
          title: 'Error',
          message: '$err',
          onRetry: () =>
              ref.invalidate(activeCricketGameProvider(widget.gameId)),
        ),
      ),
      data: (activeGameState) {
        if (activeGameState == null) {
          return const Scaffold(
            body: Center(child: Text('Game not found')),
          );
        }

        final gameState = activeGameState.gameState;

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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) => _confirmBack(context),
          child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
            children: [
              AppHeader(
                showBack: true,
                onBack: () => _confirmBack(context),
                trailing: InkWell(
                  onTap: () => _showEndGameDialog(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  splashColor: AppTheme.kineticSplashColor,
                  highlightColor: AppTheme.kineticSplashColor,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.settings_outlined,
                      color: cs.onSurface,
                      semanticLabel: 'Game options',
                    ),
                  ),
                ),
              ),
              GameStatusBarWidget(
                configLabel: variantLabel,
                currentLegIndex: gameState.currentLegIndex,
                legsToWin: gameState.legsToWin,
                roundInLeg: gameState.currentRoundInLeg,
                totalRounds: gameState.cricketTotalRounds,
                currentTurnDarts: currentTurnDarts,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLarge),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(
                          color:
                              cs.outlineVariant.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.40),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CricketUnifiedTableWidget(
                        gameState: gameState,
                        onSegmentTapped:
                            (gameState.isComplete || !gameState.turnActive)
                                ? (_) {}
                                : (segment) =>
                                    notifier.processDart(segment),
                        onMiss:
                            (gameState.isComplete || !gameState.turnActive)
                                ? () {}
                                : () => notifier.processDart('MISS'),
                      ),
                    ),
                  ),
                ),
              ),
              _BottomActionBar(
                canUndo: canUndo,
                canNext: canNext,
                isMultiplayer: gameState.competitors.length > 1,
                dartsThrownInTurn: dartsThrownInTurn,
                pulseNext: canNext && !gameState.turnActive,
                onUndo: () => notifier.undoDart(),
                onNextRound: () => notifier.nextPlayer(),
              ),
            ],
          ),
          ),
          ),
        );
      },
    );
  }

  void _confirmBack(BuildContext context) {
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
    required this.pulseNext,
    required this.onUndo,
    required this.onNextRound,
  });

  final bool canUndo;
  final bool canNext;
  final bool isMultiplayer;
  final int dartsThrownInTurn;
  final bool pulseNext;
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
          color: cs.surfaceContainerHighest.withValues(alpha: AppTheme.opacityBottomBarBackground),
          border: Border(
            top: BorderSide(
              color: cs.surfaceContainer.withValues(alpha: AppTheme.opacityBottomBarTopEdge),
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
                      color: cs.outlineVariant.withValues(alpha: AppTheme.opacityGhostBorderStrong),
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
              child: PulsingNextButtonWidget(
                label: isMultiplayer ? 'NEXT PLAYER' : 'NEXT ROUND',
                onPressed: canNext ? handleAdvance : null,
                pulse: pulseNext,
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
