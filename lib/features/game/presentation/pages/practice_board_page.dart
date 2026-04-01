import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/models/game_state.dart';
import '../providers/active_practice_provider.dart';
import '../widgets/dartboard_highlight_widget.dart';
import '../widgets/game_status_bar_widget.dart';
import '../widgets/practice_input_buttons_widget.dart';
import '../widgets/practice_target_display_widget.dart';

enum _DrillAction { resetDrill, endDrill }

class PracticeBoardPage extends ConsumerWidget {
  const PracticeBoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(activePracticeProvider(gameId));

    return asyncState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load drill.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(activePracticeProvider(gameId)),
              child: Text(
                'Retry',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ]),
        ),
      ),
      data: (practiceState) {
        if (practiceState == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Game not found'),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back'),
                ),
              ]),
            ),
          );
        }

        final gs = practiceState.gameState;
        final notifier = ref.read(activePracticeProvider(gameId).notifier);
        final competitor = gs.competitors[gs.currentTurnIndex];
        final allDarts = competitor.dartThrows;
        final currentTurnDarts =
            gs.dartsThrownInTurn == 0 || allDarts.length < gs.dartsThrownInTurn
                ? <String>[]
                : allDarts.sublist(allDarts.length - gs.dartsThrownInTurn);
        final isAtc = gs.gameType == GameType.aroundTheClock;
        final isBobs27 = gs.gameType == GameType.bobs27;
        final isCatch40 = gs.gameType == GameType.catch40;
        final isShanghai = gs.gameType == GameType.shanghai;
        final doublesOnly = isAtc && gs.aroundTheClockVariant == 'doublesOnly';
        final effectiveTarget = (isBobs27 || isShanghai)
            ? competitor.practiceRound
            : competitor.currentTarget;
        final roundScore = isCatch40
            ? _computeRoundScore(competitor.dartThrows, gs.dartsThrownInTurn)
            : 0;

        // Completion modal — Shanghai check first (winner may be null for solo)
        if (isShanghai && gs.isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final delay = practiceState.showShanghaiBonus
                ? const Duration(milliseconds: 1300)
                : Duration.zero;
            await Future.delayed(delay);
            if (!context.mounted) return;
            final score = competitor.score;
            final shanghaiCount = competitor.practiceSuccesses;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                ),
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Drill Complete!',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                content: Text(
                  'Total score: $score\n'
                  'Shanghai bonuses: $shanghaiCount'
                  '${shanghaiCount > 0 ? '\nNice shooting!' : ''}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(GameRoutes.home);
                      notifier.dismissGameModal();
                    },
                    child: const Text('NEW DRILL'),
                  ),
                ],
              ),
            );
          });
        } else if (practiceState.pendingGameWinnerId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            if (isAtc) {
              final totalDarts = competitor.dartThrows.length;
              final totalTurns = (totalDarts + 2) ~/ 3;
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    'Drill Complete!',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  content: Text(
                    'You completed Around the Clock in $totalTurns turns ($totalDarts darts)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(GameRoutes.home);
                        notifier.dismissGameModal();
                      },
                      child: const Text('NEW DRILL'),
                    ),
                  ],
                ),
              );
            } else {
              final winner = gs.competitors.firstWhere(
                (c) => c.competitorId == practiceState.pendingGameWinnerId,
              );
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    '${winner.name} wins!',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(GameRoutes.home);
                        notifier.dismissGameModal();
                      },
                      child: const Text('NEW DRILL'),
                    ),
                  ],
                ),
              );
            }
          });
        } else if (isCatch40 && gs.isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Drill Complete!',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                content: Text(
                  'Total score: ${competitor.score} (max 120)\n'
                  'Targets checked out: ${competitor.practiceSuccesses} / 40',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(GameRoutes.home);
                      notifier.dismissGameModal();
                    },
                    child: const Text('NEW DRILL'),
                  ),
                ],
              ),
            );
          });
        } else if (gs.isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            if (isBobs27) {
              final score = competitor.score;
              final drillEnded = score <= 0;
              final roundReached = competitor.practiceRound - 1;
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    drillEnded ? 'Drill Ended' : 'Drill Complete!',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  content: Text(
                    drillEnded
                        ? 'Your score went to zero. You reached round $roundReached. Final score: $score'
                        : 'Final score: $score',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(GameRoutes.home);
                        notifier.dismissGameModal();
                      },
                      child: const Text('NEW DRILL'),
                    ),
                  ],
                ),
              );
            } else {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    'Drill complete!',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  content: Text(
                    'Attempts: ${competitor.practiceAttempts}\n'
                    'Successes: ${competitor.practiceSuccesses}',
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(GameRoutes.home);
                        notifier.dismissGameModal();
                      },
                      child: const Text('NEW DRILL'),
                    ),
                  ],
                ),
              );
            }
          });
        }

        return Scaffold(
          appBar: AppHeader(
            boardMode: true,
            showBack: true,
            onBack: () => context.go(GameRoutes.home),
            trailing: PopupMenuButton<_DrillAction>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (action) async {
                switch (action) {
                  case _DrillAction.resetDrill:
                    await notifier.resetDrill();
                  case _DrillAction.endDrill:
                    await notifier.endDrill();
                    if (context.mounted) context.go(GameRoutes.home);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _DrillAction.resetDrill,
                  child: Text('Reset Drill'),
                ),
                PopupMenuItem(
                  value: _DrillAction.endDrill,
                  child: Text('End Drill'),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              GameStatusBarWidget(
                configLabel: _modeName(gs.gameType),
                currentLegIndex: 0,
                legsToWin: 1,
                roundInLeg: competitor.practiceRound,
                totalRounds: _totalRounds(gs),
                currentTurnDarts: currentTurnDarts,
              ),
              Expanded(
                child: DartboardHighlightWidget(
                  currentTarget: effectiveTarget,
                  doublesOnly: doublesOnly,
                  bobs27: isBobs27,
                  noHighlight: isCatch40,
                ),
              ),
              PracticeTargetDisplayWidget(
                gameType: gs.gameType,
                currentTarget: effectiveTarget,
                practiceRound: competitor.practiceRound,
                totalRounds: _totalRounds(gs),
                score: competitor.score,
                practiceAttempts: competitor.practiceAttempts,
                practiceSuccesses: competitor.practiceSuccesses,
                roundScore: roundScore,
              ),
              if (isShanghai)
                _ShanghaiBonus(show: practiceState.showShanghaiBonus),
              if (isCatch40)
                Expanded(
                  flex: 2,
                  child: PracticeInputButtonsWidget(
                    gameType: gs.gameType,
                    currentTarget: effectiveTarget,
                    doublesOnly: doublesOnly,
                    enabled: !gs.isComplete &&
                        gs.dartsThrownInTurn < 3 &&
                        gs.turnActive,
                    onDartThrown: (seg) => notifier.processDart(seg),
                  ),
                )
              else
                PracticeInputButtonsWidget(
                  gameType: gs.gameType,
                  currentTarget: effectiveTarget,
                  doublesOnly: doublesOnly,
                  enabled: !gs.isComplete && gs.dartsThrownInTurn < 3,
                  onDartThrown: (seg) => notifier.processDart(seg),
                ),
              _BottomBar(
                gameType: gs.gameType,
                canUndo: !gs.isComplete &&
                    (gs.dartsThrownInTurn > 0 ||
                        gs.competitors.any((c) => c.dartThrows.isNotEmpty)),
                inputEnabled: !gs.isComplete && gs.dartsThrownInTurn < 3 && (!isCatch40 || gs.turnActive),
                showNextRound: !gs.isComplete,
                showNextTarget: isCatch40 &&
                    (gs.catch40TargetRemaining == 0 ||
                        gs.catch40DartsOnTarget >= 6) &&
                    !gs.isComplete,
                onUndo: notifier.undoDart,
                onMiss: () => notifier.processDart('MISS'),
                onNextRound: notifier.startNextTurn,
                onEndDrill: notifier.endDrill,
              ),
            ],
          ),
        );
      },
    );
  }

  static int _computeRoundScore(List<String> dartThrows, int dartsThrownInTurn) {
    if (dartsThrownInTurn == 0) return 0;
    final current = dartThrows.sublist(dartThrows.length - dartsThrownInTurn);
    return current.map(_dartScoreValue).fold(0, (a, b) => a + b);
  }

  static int _dartScoreValue(String s) {
    if (s == 'MISS') return 0;
    if (s == 'DB') return 50;
    if (s == 'SB') return 25;
    if (s.startsWith('D')) return int.parse(s.substring(1)) * 2;
    if (s.startsWith('T')) return int.parse(s.substring(1)) * 3;
    return int.parse(s);
  }

  static String _modeName(GameType type) => switch (type) {
        GameType.aroundTheClock => 'Around the Clock',
        GameType.bobs27 => "Bob's 27",
        GameType.shanghai => 'Shanghai',
        GameType.catch40 => 'Catch 40',
        GameType.checkoutPractice => 'Checkout Practice',
        _ => 'Practice',
      };

  static int _totalRounds(GameState gs) => switch (gs.gameType) {
        GameType.aroundTheClock => 20,
        GameType.bobs27 => 20,
        GameType.shanghai => gs.shanghaiTotalRounds,
        GameType.catch40 => 40,
        GameType.checkoutPractice => gs.checkoutPracticeOrder.length,
        _ => 0,
      };
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.gameType,
    required this.canUndo,
    required this.inputEnabled,
    required this.showNextRound,
    required this.onUndo,
    required this.onMiss,
    required this.onNextRound,
    required this.onEndDrill,
    this.showNextTarget = false,
  });

  final GameType gameType;
  final bool canUndo;
  final bool inputEnabled;
  final bool showNextRound;
  final bool showNextTarget;
  final VoidCallback onUndo;
  final VoidCallback onMiss;
  final Future<void> Function() onNextRound;
  final Future<void> Function() onEndDrill;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCheckout = gameType == GameType.checkoutPractice;
    final isCatch40 = gameType == GameType.catch40;

    final nextEnabled = isCatch40 ? showNextTarget : showNextRound;
    final nextLabel = isCatch40
        ? 'NEXT TARGET'
        : isCheckout
            ? 'END DRILL'
            : 'NEXT ROUND';
    final VoidCallback? onNext = nextEnabled
        ? (isCheckout ? () => onEndDrill() : () => onNextRound())
        : null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(
            color: cs.surfaceContainer.withValues(alpha: 0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: SafeArea(
        top: false,
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
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(Icons.undo, color: cs.onSurface),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Miss — square button
            Opacity(
              opacity: inputEnabled ? 1.0 : 0.38,
              child: InkWell(
                onTap: inputEnabled ? onMiss : null,
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
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(Icons.close, color: cs.onSurface, semanticLabel: 'Miss'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Next — wide primary neon button
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
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward, semanticLabel: ''),
                label: Text(nextLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShanghaiBonus extends StatefulWidget {
  const _ShanghaiBonus({required this.show});

  final bool show;

  @override
  State<_ShanghaiBonus> createState() => _ShanghaiBonusState();
}

class _ShanghaiBonusState extends State<_ShanghaiBonus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600), // 300ms scale-in + 1000ms hold + 300ms fade
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.1875, curve: Curves.easeOut), // 0–300ms / 1600ms ≈ 0.1875
      ),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.8125, 1.0, curve: Curves.easeIn), // 1300–1600ms / 1600ms ≈ 0.8125
      ),
    );
  }

  @override
  void didUpdateWidget(_ShanghaiBonus old) {
    super.didUpdateWidget(old);
    if (widget.show && !old.show) {
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 0.0;
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _ctrl.forward();
        });
      } else {
        _ctrl.forward(from: 0.0).then((_) {
          // controller is at 1.0, banner has faded out
        });
      }
    } else if (!widget.show && old.show) {
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _ctrl.isDismissed) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final opacity = widget.show && _ctrl.isDismissed ? 1.0 : _opacity.value;
        final scale = widget.show && _ctrl.isDismissed ? 1.0 : _scale.value;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'SHANGHAI!',
              style: AppTextStyles.displayLarge.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
