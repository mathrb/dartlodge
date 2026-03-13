import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/models/game_state.dart';
import '../providers/active_practice_provider.dart';
import '../widgets/dartboard_highlight_widget.dart';
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
        final isAtc = gs.gameType == GameType.aroundTheClock;
        final isBobs27 = gs.gameType == GameType.bobs27;
        final isCatch40 = gs.gameType == GameType.catch40;
        final doublesOnly = isAtc && gs.aroundTheClockVariant == 'doublesOnly';
        final effectiveTarget = isBobs27 ? competitor.practiceRound : competitor.currentTarget;
        final roundScore = isCatch40
            ? _computeRoundScore(competitor.dartThrows, gs.dartsThrownInTurn)
            : 0;

        // Completion modal
        if (practiceState.pendingGameWinnerId != null) {
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
                  'Rounds attempted: ${gs.catch40TotalRounds}\n'
                  'Rounds passed (≥40): ${competitor.practiceSuccesses}\n'
                  'Total score across all rounds: ${competitor.score}',
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
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.go(GameRoutes.home)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _modeName(gs.gameType),
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  _progressText(gs, competitor),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<_DrillAction>(
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
            ],
          ),
          body: Column(
            children: [
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
                inputEnabled: !gs.isComplete && gs.dartsThrownInTurn < 3,
                showNextRound: gs.dartsThrownInTurn == 3 && !gs.isComplete,
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

  static String _progressText(GameState gs, CompetitorState c) =>
      switch (gs.gameType) {
        GameType.aroundTheClock => 'Number: ${c.practiceRound} / 20',
        GameType.bobs27 => 'Target: D${c.practiceRound}',
        GameType.shanghai =>
          'Round: ${c.practiceRound} / ${gs.shanghaiTotalRounds}',
        GameType.catch40 =>
          'Round ${c.practiceRound} / ${gs.catch40TotalRounds}',
        GameType.checkoutPractice =>
          '${c.practiceSuccesses}/${c.practiceAttempts} checkouts',
        _ => '',
      };

  static int _totalRounds(GameState gs) => switch (gs.gameType) {
        GameType.aroundTheClock => 20,
        GameType.bobs27 => 20,
        GameType.shanghai => gs.shanghaiTotalRounds,
        GameType.catch40 => gs.catch40TotalRounds,
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
  });

  final GameType gameType;
  final bool canUndo;
  final bool inputEnabled;
  final bool showNextRound;
  final VoidCallback onUndo;
  final VoidCallback onMiss;
  final Future<void> Function() onNextRound;
  final Future<void> Function() onEndDrill;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCheckout = gameType == GameType.checkoutPractice;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.undo),
                label: Text(
                  'Undo',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                onPressed: canUndo ? onUndo : null,
              ),
              OutlinedButton(
                onPressed: inputEnabled ? onMiss : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  side: BorderSide(color: colorScheme.outline),
                ),
                child: const Text('MISS'),
              ),
              if (isCheckout)
                FilledButton(
                  onPressed: showNextRound ? onEndDrill : null,
                  child: const Text('END DRILL'),
                )
              else
                FilledButton(
                  onPressed: showNextRound ? onNextRound : null,
                  child: const Text('NEXT ROUND'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
