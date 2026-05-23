import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../../domain/models/game_state.dart';
import '../providers/active_practice_provider.dart';
import '../state/active_practice_state.dart';
import '../widgets/dartboard_highlight_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_status_bar_widget.dart';
import '../widgets/practice_input_buttons_widget.dart';
import '../widgets/practice_target_display_widget.dart';
import '../widgets/pulsing_next_button_widget.dart';

enum _DrillAction { endDrill }

/// Defer used by the Shanghai-on-final-dart path so the inline `_ShanghaiBonus`
/// banner (1300ms animation) finishes before we navigate away. All other
/// completion paths navigate immediately.
const Duration _shanghaiBonusNavDelay = Duration(milliseconds: 1300);

class PracticeBoardPage extends ConsumerStatefulWidget {
  const PracticeBoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<PracticeBoardPage> createState() => _PracticeBoardPageState();
}

class _PracticeBoardPageState extends ConsumerState<PracticeBoardPage> {
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
    // Listen for natural completion transitions and navigate to the post-game
    // summary — mirroring x01/cricket boards. Manual "End Drill" sets
    // `wasEndedManually: true` on the practice state; the menu handler then
    // routes home directly, and this listener no-ops for that case.
    //
    // Shanghai-on-final-dart: when the inline `_ShanghaiBonus` banner is
    // still animating, delay the nav by 1.3s so the user sees the banner
    // before being whisked away.
    ref.listen<AsyncValue<ActivePracticeState?>>(
      activePracticeProvider(widget.gameId),
      (prev, next) {
        final prevValue = prev?.value;
        final nextValue = next.value;
        if (nextValue == null) return;
        if (nextValue.wasEndedManually) return;

        final gs = nextValue.gameState;
        final prevComplete = prevValue?.gameState.isComplete ?? false;
        if (prevComplete || !gs.isComplete) return;

        final delay = (gs.gameType == GameType.shanghai &&
                nextValue.showShanghaiBonus)
            ? _shanghaiBonusNavDelay
            : Duration.zero;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (delay != Duration.zero) await Future.delayed(delay);
          if (!context.mounted) return;
          context.go(GameRoutes.postGame(widget.gameId));
        });
      },
    );

    final asyncState = ref.watch(activePracticeProvider(widget.gameId));

    return asyncState.when(
      loading: () => const Scaffold(
        body: LoadingSpinnerWidget(),
      ),
      error: (err, _) => Scaffold(
        body: ErrorRetryWidget(
          title: 'Failed to load drill.',
          message: '$err',
          onRetry: () => ref.invalidate(activePracticeProvider(widget.gameId)),
        ),
      ),
      data: (practiceState) {
        if (practiceState == null) {
          return Scaffold(
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Game not found'),
                TextButton(
                  onPressed: () => context.go(GameRoutes.home),
                  child: const Text('Back'),
                ),
              ]),
            ),
          );
        }

        final gs = practiceState.gameState;
        final notifier = ref.read(activePracticeProvider(widget.gameId).notifier);
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
        final isCheckout = gs.gameType == GameType.checkoutPractice;
        final doublesOnly = isAtc && gs.aroundTheClockVariant == 'doublesOnly';
        // Bob's 27 bumps `practiceRound` on the 3rd-dart scoring path inside
        // the engine, but the next TurnStarted (which resets the input grid)
        // only fires when the user taps NEXT ROUND. Between those two
        // moments the input grid is disabled (`dartsThrownInTurn == 3`) yet
        // the engine state already shows round N+1 — so we'd display the
        // *next* round's target / counter against a locked grid, making the
        // user think their input was silently swallowed (#258). Decrement
        // the displayed round during that gap so the UI stays on the
        // just-played round until the user explicitly advances.
        //
        // Checkout Practice doesn't track attempts in `practiceRound` (the
        // engine never bumps it — undo replays skip TurnEnded and would
        // de-sync the counter), so we derive the attempt number purely
        // from `dartThrows.length` + `dartsThrownInTurn`: every completed
        // attempt fills 3 slots (the engine pads bust/checkout dart sets
        // to 3), and we step to the next attempt only after the user taps
        // NEXT ROUND (`dartsThrownInTurn == 0` with `len > 0`) (#261).
        // Shanghai and Catch 40 advance round state inside
        // `_applyTurnEnded` and don't need this adjustment.
        final int displayedRound;
        if (isBobs27 && gs.dartsThrownInTurn >= 3) {
          displayedRound = competitor.practiceRound - 1;
        } else if (isCheckout) {
          final dartsCount = competitor.dartThrows.length;
          if (dartsCount == 0) {
            displayedRound = 1;
          } else {
            final completedAttempts = (dartsCount / 3).ceil();
            // Bump only when the previous attempt has been formally ended
            // via NEXT ROUND (dartsThrownInTurn back to 0 with darts on
            // record); otherwise we're still mid-attempt.
            displayedRound = completedAttempts +
                (gs.dartsThrownInTurn == 0 ? 1 : 0);
          }
        } else {
          displayedRound = competitor.practiceRound;
        }
        final effectiveTarget = (isBobs27 || isShanghai)
            ? displayedRound
            : isCheckout
                ? competitor.score
                : competitor.currentTarget;
        final roundScore = isCatch40
            ? _computeRoundScore(competitor.dartThrows, gs.dartsThrownInTurn)
            : 0;

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
                trailing: PopupMenuButton<_DrillAction>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onSelected: (action) async {
                    switch (action) {
                      case _DrillAction.endDrill:
                        await notifier.endDrill();
                        if (context.mounted) context.go(GameRoutes.home);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _DrillAction.endDrill,
                      // Multi-player ATC / Shanghai is a competitive game,
                      // not a solo drill — match the label to the context.
                      child: Text(
                        gs.competitors.length > 1 ? 'End Game' : 'End Drill',
                      ),
                    ),
                  ],
                ),
              ),
              GameStatusBarWidget(
                configLabel: _modeName(gs.gameType),
                roundInLeg: displayedRound,
                totalRounds: _totalRounds(gs),
                currentTurnDarts: currentTurnDarts,
              ),
              Expanded(
                child: DartboardHighlightWidget(
                  currentTarget: effectiveTarget,
                  doublesOnly: doublesOnly,
                  bobs27: isBobs27,
                  noHighlight: isCatch40 || isCheckout,
                ),
              ),
              PracticeTargetDisplayWidget(
                gameType: gs.gameType,
                currentTarget: effectiveTarget,
                practiceRound: displayedRound,
                totalRounds: _totalRounds(gs),
                score: competitor.score,
                // Multi-player ATC / Shanghai: surface whose turn it is
                // (#276). Solo drills pass null and keep the previous
                // target-only chrome.
                currentPlayerName:
                    gs.competitors.length > 1 ? competitor.name : null,
                practiceAttempts: isCheckout
                    // Exclude the engine's empty-slot sentinel pads —
                    // showing the user "9 darts thrown" when they really
                    // only threw 7 (with 2 sentinels from a 1-dart bust)
                    // was the off-by-one called out in #261.
                    ? competitor.dartThrows
                        .where((d) => d.isNotEmpty)
                        .length
                    : competitor.practiceAttempts,
                practiceSuccesses: competitor.practiceSuccesses,
                roundScore: roundScore,
              ),
              if (isShanghai)
                _ShanghaiBonus(show: practiceState.showShanghaiBonus),
              if (isCatch40 || isCheckout)
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
                showNextRound: !gs.isComplete,
                showNextTarget: isCatch40 &&
                    (gs.catch40TargetRemaining == 0 ||
                        gs.catch40DartsOnTarget >= 6) &&
                    !gs.isComplete,
                pulseNext: !gs.isComplete && !gs.turnActive,
                onUndo: notifier.undoDart,
                onNextRound: notifier.startNextTurn,
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

  static int? _totalRounds(GameState gs) => switch (gs.gameType) {
        GameType.aroundTheClock => null, // completion-based, no round limit
        GameType.bobs27 => 20,
        GameType.shanghai => gs.shanghaiTotalRounds,
        GameType.catch40 => 40,
        GameType.checkoutPractice => gs.checkoutTargetSuccesses,
        _ => null,
      };
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.gameType,
    required this.canUndo,
    required this.showNextRound,
    required this.pulseNext,
    required this.onUndo,
    required this.onNextRound,
    this.showNextTarget = false,
  });

  final GameType gameType;
  final bool canUndo;
  final bool showNextRound;
  final bool showNextTarget;
  final bool pulseNext;
  final VoidCallback onUndo;
  final Future<void> Function() onNextRound;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCatch40 = gameType == GameType.catch40;

    final nextEnabled = isCatch40 ? showNextTarget : showNextRound;
    final nextLabel = isCatch40 ? 'NEXT TARGET' : 'NEXT ROUND';
    final VoidCallback? onNext = nextEnabled ? () => onNextRound() : null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: AppTheme.opacityBottomBarBackground),
        border: Border(
          top: BorderSide(
            color: cs.surfaceContainer.withValues(alpha: AppTheme.opacityBottomBarTopEdge),
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
                      color: cs.outlineVariant.withValues(alpha: AppTheme.opacityGhostBorderStrong),
                    ),
                  ),
                  child: Icon(Icons.undo, color: cs.onSurface),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Next — wide primary neon button
            Expanded(
              child: PulsingNextButtonWidget(
                label: nextLabel,
                onPressed: onNext,
                pulse: pulseNext,
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
