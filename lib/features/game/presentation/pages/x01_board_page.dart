import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/checkout_table.dart';
import '../providers/active_game_provider.dart';
import '../widgets/dart_indicator_widget.dart';
import '../widgets/dart_input_grid_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
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
    final tt = Theme.of(context).textTheme;

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
              style: AppTextStyles.headingSmall
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

    // Leg complete listener
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

    final asyncState = ref.watch(activeGameProvider(widget.gameId));

    return asyncState.when(
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $err'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.invalidate(activeGameProvider(widget.gameId)),
                child: const Text('Retry'),
              ),
            ],
          ),
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
        final canNext = !gameState.turnActive && !gameState.isComplete;
        final currentScore = activeCompetitor.score;

        // Current turn darts: last dartsThrownInTurn items from active
        // competitor's dartThrows list
        final allDarts = activeCompetitor.dartThrows;
        final currentTurnDarts = dartsThrownInTurn == 0 || allDarts.length < dartsThrownInTurn
            ? <String>[]
            : allDarts.sublist(allDarts.length - dartsThrownInTurn);

        // Winner name for win banner
        final pendingGameWinnerId = activeGameState.pendingGameWinnerId;
        String? winnerName;
        if (pendingGameWinnerId != null) {
          winnerName = gameState.competitors
              .firstWhere((c) => c.competitorId == pendingGameWinnerId)
              .name;
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  '${gameState.startingScore}',
                  style: AppTextStyles.headingSmall
                      .copyWith(color: cs.onBackground),
                ),
                Text(
                  'Leg ${gameState.currentLegIndex + 1} of ${gameState.legsToWin}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: cs.onSurfaceVariant),
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
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Game board body
              Column(
                children: [
                  DartIndicatorWidget(currentTurnDarts: currentTurnDarts),
                  PlayerScoreSectionWidget(
                    gameState: gameState,
                    bustFlashAnim: _bustFlashAnim,
                  ),
                  _CheckoutBanner(score: currentScore),
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
                    onNextRound: () {
                      final notifier = ref
                          .read(activeGameProvider(widget.gameId).notifier);
                      notifier.dismissBust();
                      notifier.dismissLegModal();
                      notifier.startNextTurn();
                    },
                  ),
                ],
              ),
              // Win banner (always in stack; slides in when winner set)
              IgnorePointer(
                ignoring: pendingGameWinnerId == null,
                child: _WinBannerWidget(
                  visible: pendingGameWinnerId != null,
                  winnerName: winnerName ?? '',
                  lastDart: gameState.competitors
                      .expand((c) => [if (c.competitorId == pendingGameWinnerId && c.dartThrows.isNotEmpty) c.dartThrows.last])
                      .firstOrNull,
                  onPostGame: () =>
                      context.go('/post-game/${widget.gameId}'),
                  onPlayAgain: () => context.go(GameRoutes.home),
                ),
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

// ── Private widgets ────────────────────────────────────────────────────────────

class _CheckoutBanner extends StatelessWidget {
  const _CheckoutBanner({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = score >= 2 && score <= 170;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Visibility(
        visible: visible,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceVariant,
            border: Border(
              left: BorderSide(color: cs.primary, width: 2),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: cs.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                checkoutSuggestion(score) ?? '',
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onBackground),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _ControlTile(
                    label: 'UNDO',
                    enabled: canUndo,
                    onTap: onUndo,
                    hasBorderRight: true,
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: _ControlTile(
                    label: isMultiplayer ? 'NEXT PLAYER' : 'NEXT ROUND',
                    enabled: canNext,
                    onTap: onNextRound,
                    hasBorderRight: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.hasBorderRight,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool hasBorderRight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tile = GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            right: hasBorderRight
                ? BorderSide(color: cs.outline, width: 1)
                : BorderSide.none,
            bottom: BorderSide(color: cs.outline, width: 1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(color: cs.onSurface),
        ),
      ),
    );
    return enabled ? tile : Opacity(opacity: 0.38, child: tile);
  }
}

class _WinBannerWidget extends StatelessWidget {
  const _WinBannerWidget({
    required this.visible,
    required this.winnerName,
    required this.lastDart,
    required this.onPostGame,
    required this.onPlayAgain,
  });

  final bool visible;
  final String winnerName;
  final String? lastDart;
  final VoidCallback onPostGame;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColorsDark.winContainer : AppColors.winContainer;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: ColoredBox(
        color: bgColor,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                winnerName.toUpperCase(),
                style: AppTextStyles.displayLarge.copyWith(color: AppColors.win),
              ),
              if (lastDart != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Final Score: 0  ·  Checkout: $lastDart',
                  style: AppTextStyles.headingMedium.copyWith(color: AppColors.win),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onPostGame,
                child: const Text('Post-Game Summary'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onPlayAgain,
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

