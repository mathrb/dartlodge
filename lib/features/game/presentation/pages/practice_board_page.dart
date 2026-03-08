import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/models/game_state.dart';
import '../providers/active_practice_provider.dart';
import '../widgets/dartboard_highlight_widget.dart';
import '../widgets/practice_input_buttons_widget.dart';
import '../widgets/practice_target_display_widget.dart';

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
            Text('Error: $err'),
            TextButton(
              onPressed: () => ref.invalidate(activePracticeProvider(gameId)),
              child: const Text('Retry'),
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
                    child: const Text('Back')),
              ]),
            ),
          );
        }

        final gs = practiceState.gameState;
        final notifier =
            ref.read(activePracticeProvider(gameId).notifier);
        final competitor = gs.competitors[gs.currentTurnIndex];

        // Game winner modal
        if (practiceState.pendingGameWinnerId != null) {
          final winner = gs.competitors.firstWhere(
            (c) => c.competitorId == practiceState.pendingGameWinnerId,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: Text('${winner.name} wins!'),
                actions: [
                  TextButton(
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
          // Drill complete without a winner (e.g. endDrill called)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text('Drill complete!'),
                content: Text(
                  'Attempts: ${competitor.practiceAttempts}\n'
                  'Successes: ${competitor.practiceSuccesses}',
                ),
                actions: [
                  TextButton(
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
        }

        final doublesOnly = (gs.gameType == GameType.aroundTheClock &&
                gs.aroundTheClockVariant == 'doublesOnly') ||
            gs.gameType == GameType.bobs27;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_modeName(gs.gameType)),
                Text(
                  _progressText(gs, competitor),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            leading: BackButton(onPressed: () => context.go(GameRoutes.home)),
          ),
          body: Column(
            children: [
              Expanded(
                child: DartboardHighlightWidget(
                  currentTarget: competitor.currentTarget,
                  doublesOnly: doublesOnly,
                ),
              ),
              PracticeTargetDisplayWidget(
                gameType: gs.gameType,
                currentTarget: competitor.currentTarget,
                practiceRound: competitor.practiceRound,
                totalRounds: _totalRounds(gs),
                score: competitor.score,
                practiceAttempts: competitor.practiceAttempts,
                practiceSuccesses: competitor.practiceSuccesses,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PracticeInputButtonsWidget(
                  gameType: gs.gameType,
                  currentTarget: competitor.currentTarget,
                  enabled: !gs.isComplete && gs.dartsThrownInTurn < 3,
                  onDartThrown: (seg) => notifier.processDart(seg),
                ),
              ),
              _BottomBar(
                gameType: gs.gameType,
                canUndo: !gs.isComplete &&
                    (gs.dartsThrownInTurn > 0 ||
                        gs.competitors
                            .any((c) => c.dartThrows.isNotEmpty)),
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
        GameType.bobs27 => 'Target: D${c.currentTarget ?? 1}',
        GameType.shanghai =>
          'Round: ${c.practiceRound} / ${gs.shanghaiTotalRounds}',
        GameType.catch40 =>
          'Round: ${c.practiceRound} / ${gs.catch40TotalRounds}',
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
    final isCheckout = gameType == GameType.checkoutPractice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? onUndo : null,
          ),
          OutlinedButton(
            onPressed: inputEnabled ? onMiss : null,
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
    );
  }
}
