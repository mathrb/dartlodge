import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/checkout_table.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/active_game_provider.dart';
import '../widgets/cap_winner_selection_dialog_widget.dart';
import '../widgets/dart_input_grid_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_status_bar_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';
import '../widgets/player_score_section_widget.dart';

class X01BoardPage extends ConsumerStatefulWidget {
  const X01BoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<X01BoardPage> createState() => _X01BoardPageState();
}

class _X01BoardPageState extends ConsumerState<X01BoardPage>
    with TickerProviderStateMixin {
  late final AnimationController _bustFlashController;
  late final Animation<double> _bustFlashAnim;

  @override
  void initState() {
    super.initState();
    _bustFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _bustFlashAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 500,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 300,
      ),
    ]).animate(_bustFlashController);
  }

  @override
  void dispose() {
    _bustFlashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Bust listener — fires on showBust false→true transition
    ref.listen(activeGameProvider(widget.gameId), (prev, next) {
      final prevShowBust = prev?.value?.showBust ?? false;
      final nextShowBust = next.value?.showBust ?? false;
      if (!prevShowBust && nextShowBust) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cs.errorContainer,
            duration: const Duration(seconds: 2),
            content: Text(
              'BUST',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: cs.onErrorContainer),
            ),
          ),
        );
        _bustFlashController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ref
                .read(activeGameProvider(widget.gameId).notifier)
                .dismissBust();
          }
        });
      }
    });

    ref.listen(activeGameProvider(widget.gameId), (prev, next) {
      final prevComplete = prev?.value?.gameState.isComplete ?? false;
      final nextComplete = next.value?.gameState.isComplete ?? false;
      if (!prevComplete && nextComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.go('/post-game/${widget.gameId}');
        });
      }
    });

    ref.listen(activeGameProvider(widget.gameId), (prev, next) {
      final prevLeg = prev?.value?.pendingLegWinnerId;
      final nextLeg = next.value?.pendingLegWinnerId;
      if (prevLeg == null && nextLeg != null) {
        final gs = next.value!.gameState;
        final winner = gs.competitors.firstWhere(
          (c) => c.competitorId == nextLeg,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => LegCompleteModalWidget(
              winnerName: winner.name,
              legNumber: gs.currentLegIndex,
              onNextLeg: () => ref
                  .read(activeGameProvider(widget.gameId).notifier)
                  .dismissLegModal(),
            ),
          );
        });
      }
    });

    ref.listen(activeGameProvider(widget.gameId), (prev, next) {
      final prevCap = prev?.value?.pendingCapSelection ?? false;
      final nextCap = next.value?.pendingCapSelection ?? false;
      if (!prevCap && nextCap) {
        final gs = next.value!.gameState;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => CapWinnerSelectionDialogWidget(
              competitors: gs.competitors,
              onSelect: (id) => ref
                  .read(activeGameProvider(widget.gameId).notifier)
                  .selectCapWinner(id),
            ),
          );
        });
      }
    });

    final asyncState = ref.watch(activeGameProvider(widget.gameId));

    return asyncState.when(
      loading: () => Scaffold(
        body: LoadingSpinnerWidget(color: cs.primary),
      ),
      error: (err, _) => Scaffold(
        body: ErrorRetryWidget(
          title: 'Error',
          message: '$err',
          onRetry: () => ref.invalidate(activeGameProvider(widget.gameId)),
        ),
      ),
      data: (activeGameState) {
        if (activeGameState == null) {
          return const Scaffold(
            body: Center(child: Text('Game not found')),
          );
        }

        final gameState = activeGameState.gameState;
        final activeCompetitor =
            gameState.competitors[gameState.currentTurnIndex];
        final dartsThrownInTurn = gameState.dartsThrownInTurn;
        final canUndo = dartsThrownInTurn > 0 ||
            gameState.competitors.any((c) => c.dartThrows.isNotEmpty);
        final canNext = !gameState.isComplete;
        final currentScore = activeCompetitor.score;

        // Current turn darts: last dartsThrownInTurn items from active
        // competitor's dartThrows list
        final allDarts = activeCompetitor.dartThrows;
        final currentTurnDarts =
            dartsThrownInTurn == 0 || allDarts.length < dartsThrownInTurn
                ? <String>[]
                : allDarts.sublist(allDarts.length - dartsThrownInTurn);

        final roundInLeg = gameState.currentRoundInLeg;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) => _confirmBack(context),
          child: Scaffold(
          appBar: AppHeader(
            boardMode: true,
            showBack: true,
            onBack: () => _confirmBack(context),
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
                    configLabel: '${gameState.startingScore}',
                    currentLegIndex: gameState.currentLegIndex,
                    legsToWin: gameState.legsToWin,
                    roundInLeg: roundInLeg,
                    totalRounds: gameState.x01TotalRounds,
                    currentTurnDarts: currentTurnDarts,
                  ),
                  PlayerScoreSectionWidget(
                    gameState: gameState,
                    bustFlashAnim: _bustFlashAnim,
                  ),
                  _CheckoutBanner(score: currentScore, outStrategy: gameState.outStrategy),
                  Expanded(
                    child: DartInputGridWidget(
                      onSegmentTapped: (segment) => ref
                          .read(activeGameProvider(widget.gameId).notifier)
                          .processDart(segment),
                      enabled: !gameState.isComplete && gameState.turnActive,
                    ),
                  ),
                  _BottomActionBar(
                    canUndo: canUndo,
                    canNext: canNext,
                    isMultiplayer: gameState.competitors.length > 1,
                    onUndo: () => ref
                        .read(activeGameProvider(widget.gameId).notifier)
                        .undoDart(),
                    onNextRound: () => ref
                        .read(activeGameProvider(widget.gameId).notifier)
                        .advanceTurn(),
                  ),
                ],
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

// ── Private widgets ────────────────────────────────────────────────────────────

class _CheckoutBanner extends StatelessWidget {
  const _CheckoutBanner({required this.score, required this.outStrategy});

  final int score;
  final String outStrategy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inRange = score >= minCheckoutScore(outStrategy) &&
        score <= maxCheckoutScore(outStrategy);
    final suggestion =
        inRange ? checkoutSuggestionForStrategy(score, outStrategy) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: inRange ? 2 : 0,
                color: cs.primaryFixed,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CHECKOUT',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: inRange
                              ? cs.onSurfaceVariant
                              : cs.onSurfaceVariant.withValues(alpha: 0.35),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        suggestion ?? 'Suggestions appear in checkout range',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: inRange
                              ? cs.primaryFixed
                              : cs.onSurfaceVariant.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.canUndo,
    required this.canNext,
    required this.isMultiplayer,
    required this.onUndo,
    required this.onNextRound,
  });

  final bool canUndo;
  final bool canNext;
  final bool isMultiplayer;
  final VoidCallback onUndo;
  final VoidCallback onNextRound;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primaryFixed,
                  foregroundColor: AppColors.onPrimaryFixed,
                  disabledBackgroundColor:
                      cs.primaryFixed.withValues(alpha: AppTheme.opacityDisabled),
                  disabledForegroundColor:
                      AppColors.onPrimaryFixed.withValues(alpha: AppTheme.opacityDisabled),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                onPressed: canNext ? onNextRound : null,
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



