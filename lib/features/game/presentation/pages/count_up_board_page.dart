import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/active_count_up_provider.dart';
import '../sound/wire_game_sounds.dart';
import '../widgets/dart_input_grid_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_status_bar_widget.dart';
import '../widgets/player_score_section_widget.dart';
import '../widgets/pulsing_next_button_widget.dart';

/// Trailing-menu actions on the active count-up board (#331). Mirrors the
/// X01/Cricket boards so users can reach Settings without abandoning
/// their game.
enum _BoardMenuAction { endGame, settings }

/// Active board page for count-up.
///
/// Mirrors [X01BoardPage] minus the X01-only chrome:
/// - no bust flash / banner
/// - no checkout suggestion
/// - no leg-complete modal (single leg)
/// - no round-cap selection (winner is auto-determined or null on tie)
class CountUpBoardPage extends ConsumerStatefulWidget {
  const CountUpBoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<CountUpBoardPage> createState() => _CountUpBoardPageState();
}

class _CountUpBoardPageState extends ConsumerState<CountUpBoardPage> {
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

    // Sound effects: hit/miss per dart (count-up has no bust).
    wireGameSounds(
      ref,
      activeCountUpProvider(widget.gameId),
      gameStateOf: (s) => s?.gameState,
    );

    // Game-end transition → navigate to post-game summary.
    ref.listen(activeCountUpProvider(widget.gameId), (prev, next) {
      final prevComplete = prev?.value?.gameState.isComplete ?? false;
      final nextComplete = next.value?.gameState.isComplete ?? false;
      if (!prevComplete && nextComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.go(GameRoutes.postGame(widget.gameId));
        });
      }
    });

    final asyncState = ref.watch(activeCountUpProvider(widget.gameId));

    return asyncState.when(
      loading: () => Scaffold(
        body: LoadingSpinnerWidget(color: cs.primary),
      ),
      error: (err, _) => Scaffold(
        body: ErrorRetryWidget(
          title: 'Error',
          message: '$err',
          onRetry: () => ref.invalidate(activeCountUpProvider(widget.gameId)),
        ),
      ),
      data: (activeState) {
        if (activeState == null) {
          return const Scaffold(
            body: Center(child: Text('Game not found')),
          );
        }

        final gameState = activeState.gameState;
        final activeCompetitor =
            gameState.competitors[gameState.currentTurnIndex];
        final dartsThrownInTurn = gameState.dartsThrownInTurn;
        final canUndo = dartsThrownInTurn > 0 ||
            gameState.competitors.any((c) => c.dartThrows.isNotEmpty);
        final canNext = !gameState.isComplete;

        // Current turn darts: trailing dartsThrownInTurn entries from the
        // active competitor's full throw list.
        final allDarts = activeCompetitor.dartThrows;
        final currentTurnDarts =
            dartsThrownInTurn == 0 || allDarts.length < dartsThrownInTurn
                ? <String>[]
                : allDarts.sublist(allDarts.length - dartsThrownInTurn);

        // Engine clears `turnActive` after the 3rd dart but before TurnEnded
        // is persisted. Treat that as "turn done — tap NEXT to continue".
        final turnDone = !gameState.turnActive && !gameState.isComplete;

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
                  // Three-dot menu — see #331 (gear icon misleadingly
                  // implied Settings while the action was End Game).
                  trailing: PopupMenuButton<_BoardMenuAction>(
                    icon: Icon(
                      Icons.more_vert,
                      color: cs.onSurface,
                      semanticLabel: 'Game options',
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _BoardMenuAction.endGame:
                          _showEndGameDialog(context);
                        case _BoardMenuAction.settings:
                          context.push(GameRoutes.settings);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _BoardMenuAction.endGame,
                        child: Text('End Game'),
                      ),
                      PopupMenuItem(
                        value: _BoardMenuAction.settings,
                        child: Text('Settings'),
                      ),
                    ],
                  ),
                ),
                GameStatusBarWidget(
                  configLabel: 'COUNT-UP',
                  roundInLeg: gameState.currentRoundInLeg,
                  totalRounds: gameState.countUpTotalRounds,
                  currentTurnDarts: currentTurnDarts,
                ),
                PlayerScoreSectionWidget(
                  gameState: gameState,
                  // No bust → no flash. Pass an always-zero animation.
                  bustFlashAnim: const AlwaysStoppedAnimation<double>(0.0),
                ),
                Expanded(
                  child: DartInputGridWidget(
                    onSegmentTapped: (segment) => ref
                        .read(activeCountUpProvider(widget.gameId).notifier)
                        .processDart(segment),
                    enabled: !gameState.isComplete && gameState.turnActive,
                  ),
                ),
                _BottomActionBar(
                  canUndo: canUndo,
                  canNext: canNext,
                  isMultiplayer: gameState.competitors.length > 1,
                  pulseNext: canNext && turnDone,
                  onUndo: () => ref
                      .read(activeCountUpProvider(widget.gameId).notifier)
                      .undoDart(),
                  onNextRound: () => ref
                      .read(activeCountUpProvider(widget.gameId).notifier)
                      .advanceTurn(),
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.canUndo,
    required this.canNext,
    required this.isMultiplayer,
    required this.pulseNext,
    required this.onUndo,
    required this.onNextRound,
  });

  final bool canUndo;
  final bool canNext;
  final bool isMultiplayer;
  final bool pulseNext;
  final VoidCallback onUndo;
  final VoidCallback onNextRound;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest
              .withValues(alpha: AppTheme.opacityBottomBarBackground),
          border: Border(
            top: BorderSide(
              color: cs.surfaceContainer
                  .withValues(alpha: AppTheme.opacityBottomBarTopEdge),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Row(
          children: [
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
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(
                          alpha: AppTheme.opacityGhostBorderStrong),
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
            Expanded(
              child: PulsingNextButtonWidget(
                label: isMultiplayer ? 'NEXT PLAYER' : 'NEXT ROUND',
                onPressed: canNext ? onNextRound : null,
                pulse: pulseNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
