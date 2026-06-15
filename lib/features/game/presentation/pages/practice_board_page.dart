import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/game/dart_input_sink.dart';
import '../../../../core/providers/auto_scorer_providers.dart';
import '../../../../core/providers/board_camera_preview_provider.dart';
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
import '../widgets/practice_players_strip_widget.dart';
import '../widgets/practice_target_display_widget.dart';
import '../widgets/prominent_dart_band_widget.dart';
import '../widgets/pulsing_next_button_widget.dart';

enum _DrillAction { endDrill, settings }

/// Routes auto-scorer-detected darts into the active practice game (#427).
/// `advanceTurn` backs the opt-in board-clear auto-advance; it no-ops when the
/// game is complete and bumps `activeTurnSignal` like the manual NEXT button so
/// the tracker's per-turn cap resets in lock-step. Practice is single-competitor
/// with no bust/leg/game-win modal to protect, so `isComplete` is the only guard.
class _PracticeDartInputSink implements DartInputSink {
  _PracticeDartInputSink(this._ref, this._gameId);
  final WidgetRef _ref;
  final String _gameId;

  @override
  void submitDart(String segment) => _ref
      .read(activePracticeProvider(_gameId).notifier)
      .processDart(segment, inputMethod: 'camera');

  @override
  void advanceTurn() {
    final s = _ref.read(activePracticeProvider(_gameId)).value;
    // No-op when complete, or when the current turn has no darts yet: Catch 40's
    // internal same-target auto-advance (inside processDart) already starts a
    // fresh turn without bumping activeTurnSignal, so a board-clear here would
    // otherwise advance again and emit a spurious 0-dart TurnEnded.
    if (s == null ||
        s.gameState.isComplete ||
        s.gameState.dartsThrownInTurn == 0) {
      return;
    }
    _ref.read(activePracticeProvider(_gameId).notifier).startNextTurn();
    _ref.read(activeTurnSignalProvider.notifier).bump();
  }
}

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
    // Register the auto-scorer→game emit sink (#427), post-frame to avoid
    // mutating a provider during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(activeDartInputSinkProvider.notifier)
            .bind(_PracticeDartInputSink(ref, widget.gameId));
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for natural completion transitions and navigate to the post-game
    // summary — mirroring x01/cricket boards. Manual "End Drill" also routes
    // to the post-game summary (#289/#291), but it does so explicitly from
    // the menu handler below: `endDrill()` sets `wasEndedManually: true` and
    // this listener no-ops for that case so the two navigations don't race.
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

    // Catch 40 bust feedback (#325): flash a BUST snackbar when the
    // showBust flag transitions false→true, then clear the flag so it
    // doesn't fire again on unrelated rebuilds. Mirrors the x01 board's
    // bust handling.
    ref.listen<AsyncValue<ActivePracticeState?>>(
      activePracticeProvider(widget.gameId),
      (prev, next) {
        final prevShowBust = prev?.value?.showBust ?? false;
        final nextShowBust = next.value?.showBust ?? false;
        if (prevShowBust || !nextShowBust) return;

        final cs = Theme.of(context).colorScheme;
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
        Future.delayed(const Duration(seconds: 2), () {
          if (!context.mounted) return;
          ref
              .read(activePracticeProvider(widget.gameId).notifier)
              .dismissBust();
        });
      },
    );

    final asyncState = ref.watch(activePracticeProvider(widget.gameId));
    final autoScoringOn = ref.watch(autoScoringEnabledProvider).value ?? false;
    final cameraPreview = ref.watch(boardCameraPreviewBuilderProvider);

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
        final cameraFirst = autoScoringOn && cameraPreview != null;
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
                        // After endDrill() the game is is_complete=true,
                        // so route to the post-game summary the same way
                        // a natural completion does — gives the user the
                        // hero card + per-player breakdown (and, for
                        // multi-player ATC/Shanghai, the podium added in
                        // #279/#296). Previously navigated to home, which
                        // dropped the drill on the floor with no feedback
                        // (#289, #291).
                        if (context.mounted) {
                          context.go(GameRoutes.postGame(widget.gameId));
                        }
                      case _DrillAction.settings:
                        if (context.mounted) {
                          context.push(GameRoutes.settings);
                        }
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
                    // Settings entry so users don't have to abandon the
                    // drill to reach theme/preferences (#342). `push`
                    // (not `go`) preserves the active-game route so
                    // the back arrow returns to the board.
                    const PopupMenuItem(
                      value: _DrillAction.settings,
                      child: Text('Settings'),
                    ),
                  ],
                ),
              ),
              GameStatusBarWidget(
                configLabel: _modeName(gs.gameType),
                roundInLeg: displayedRound,
                // Checkout Practice's `_totalRounds` is the success target,
                // not an attempt cap — pairing it with the attempt-count
                // numerator produced misleading "ROUND 4 / 3" output (#327).
                // Drop the denominator here; success progress moves into
                // the target display's secondary metric instead.
                totalRounds: isCheckout ? null : _totalRounds(gs),
                currentTurnDarts: currentTurnDarts,
                // Camera-first (#445) hides the darts here — they move to the
                // prominent dart band below. Manual practice has no per-dart
                // correction on the bar (unchanged).
                onDartTapped: null,
                showDarts: !cameraFirst,
              ),
              // Camera-first hides the aim dartboard (the camera IS the board).
              if (!cameraFirst)
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
                // Camera-first (#445): enlarge the key target to the hero size.
                heroSize: cameraFirst,
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
                    // Per-round count, not session-cumulative (#328).
                    // `dartsThrownInTurn` jumps to 3 on bust/checkout
                    // because the engine pads the slots, so count the
                    // non-empty entries in the trailing `dartsThrownInTurn`
                    // slots of `dartThrows` to exclude sentinel pads
                    // (consistent with the X01 board's per-turn dart-chip
                    // logic).
                    ? _checkoutDartsThisRound(competitor, gs)
                    : competitor.practiceAttempts,
                practiceSuccesses: competitor.practiceSuccesses,
                roundScore: roundScore,
                catch40DartsOnTarget: gs.catch40DartsOnTarget,
                catch40TargetRemaining: gs.catch40TargetRemaining,
              ),
              if (isShanghai)
                _ShanghaiBonus(show: practiceState.showShanghaiBonus),
              // Camera-first (#445): the multi-player progress strip (ATC /
              // Shanghai) → the prominent dart band → the camera region (a
              // collapsed ~96px vignette by default, tap-expands to fill, #480).
              // Manual entry / correction lives in the band's modal.
              if (cameraFirst) ...[
                if ((isAtc || isShanghai) && gs.competitors.length > 1)
                  PracticePlayersStripWidget(
                    players: [
                      for (int i = 0; i < gs.competitors.length; i++)
                        if (i != gs.currentTurnIndex)
                          (
                            name: gs.competitors[i].name,
                            value: isAtc
                                // ATC initialises currentTarget to 1; 0 is not
                                // a valid target, so fall back to the first.
                                ? (gs.competitors[i].currentTarget ?? 1)
                                : gs.competitors[i].score,
                          ),
                    ],
                  ),
                ProminentDartBandWidget(
                  currentTurnDarts: currentTurnDarts,
                  // A thrown slot opens correction; an empty slot opens manual
                  // entry for a dart the camera missed (#427).
                  onDartTapped: gs.isComplete
                      ? null
                      : (index) => _onSlotTapped(
                          context, gs, index, effectiveTarget, doublesOnly),
                  tapEmptySlots: !gs.isComplete && gs.turnActive,
                ),
                Expanded(child: cameraPreview(context, widget.gameId)),
              ] else if (isCatch40 || isCheckout)
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
                // Shanghai rounds are tied to the round-number target —
                // tapping NEXT ROUND with 0 darts thrown silently skips
                // that round, which reads as a mis-tap rather than an
                // intentional pass (#289 / #303).
                //
                // #303 left ATC ungated because its strategic-skip was
                // judged intentional at the time. The audit (#336) later
                // flagged the resulting asymmetry, and we're choosing the
                // mis-tap protection over strategic-skip: a deliberate
                // pass remains available by throwing a MISS, while the
                // accidental 0-dart NEXT ROUND tap that hands the turn
                // over silently is now blocked. Other practice modes
                // (Bob's 27 / Catch 40 / Checkout) keep their existing
                // behaviour.
                showNextRound: !gs.isComplete &&
                    !((isShanghai || isAtc) && gs.dartsThrownInTurn == 0),
                showNextTarget: isCatch40 &&
                    (gs.catch40TargetRemaining == 0 ||
                        gs.catch40DartsOnTarget >= 6) &&
                    !gs.isComplete,
                pulseNext: !gs.isComplete && !gs.turnActive,
                onUndo: notifier.undoDart,
                onNextRound: () async {
                  await notifier.startNextTurn();
                  // Reset the auto-scorer's per-turn cap in lock-step (#380).
                  ref.read(activeTurnSignalProvider.notifier).bump();
                },
              ),
            ],
          ),
          ),
          ),
        );
      },
    );
  }

  /// Camera-first dart-indicator tap (#427): a thrown slot opens correction,
  /// an empty slot opens manual entry for a dart the camera missed. Both host
  /// the standard practice input buttons in a modal.
  void _onSlotTapped(BuildContext context, GameState gs, int index,
      int? effectiveTarget, bool doublesOnly) {
    final notifier = ref.read(activePracticeProvider(widget.gameId).notifier);
    if (index < gs.dartsThrownInTurn) {
      // Correcting a recorded dart stays available after the turn ends
      // (turnActive == false once 3 darts are thrown) — #438.
      _showSegmentSheet(context,
          title: 'Correct dart ${index + 1}',
          gameType: gs.gameType,
          currentTarget: effectiveTarget,
          doublesOnly: doublesOnly,
          requireActiveTurn: false,
          isCorrection: true,
          onSegment: (seg) => notifier.correctTurnDart(index, seg));
    } else {
      // Manual entry must not add a 4th dart, so it stays gated on the turn.
      _showSegmentSheet(context,
          title: 'Enter dart',
          gameType: gs.gameType,
          currentTarget: effectiveTarget,
          doublesOnly: doublesOnly,
          requireActiveTurn: true,
          isCorrection: false,
          onSegment: (seg) => notifier.processDart(seg));
    }
  }

  /// Modal hosting the standard [PracticeInputButtonsWidget] — the camera-first
  /// replacement for the always-visible input. Watches the live turn so the
  /// buttons disable if the turn ends while the sheet is open.
  ///
  /// [requireActiveTurn] gates the buttons on `turnActive`: true for manual
  /// entry (must not add a 4th dart), false for correcting a recorded dart
  /// (allowed after the turn ends, before it is advanced — #438).
  ///
  /// [isCorrection] makes the sheet offer the full board picker instead of the
  /// target-scoped bar, so a false-positive advance can be corrected to the
  /// real segment thrown (#500).
  void _showSegmentSheet(
    BuildContext context, {
    required String title,
    required GameType gameType,
    required int? currentTarget,
    required bool doublesOnly,
    required bool requireActiveTurn,
    required bool isCorrection,
    required void Function(String segment) onSegment,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(title, style: AppTextStyles.titleMedium),
            ),
            SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.55,
              child: Consumer(
                builder: (ctx, ref, _) {
                  final s =
                      ref.watch(activePracticeProvider(widget.gameId)).value;
                  final active = s != null &&
                      !s.gameState.isComplete &&
                      (!requireActiveTurn || s.gameState.turnActive);
                  return PracticeInputButtonsWidget(
                    gameType: gameType,
                    currentTarget: currentTarget,
                    doublesOnly: doublesOnly,
                    enabled: active,
                    isCorrection: isCorrection,
                    onDartThrown: (seg) {
                      onSegment(seg);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

  /// Darts thrown in the CURRENT checkout-practice round, excluding the
  /// engine's empty-slot sentinel pads that fire on bust or checkout. The
  /// engine sets `dartsThrownInTurn = 3` whenever it pads, so we use that
  /// as a slice into the trailing `dartThrows` entries and count only the
  /// non-empty ones (#328).
  static int _checkoutDartsThisRound(
      CompetitorState competitor, GameState gs) {
    final n = gs.dartsThrownInTurn;
    if (n == 0) return 0;
    final darts = competitor.dartThrows;
    if (darts.length < n) {
      // Defensive: alignment between dartsThrownInTurn and dartThrows.length
      // is an engine invariant. If it ever drifts, fall back to the
      // whole-list non-empty count rather than throwing.
      return darts.where((d) => d.isNotEmpty).length;
    }
    return darts
        .skip(darts.length - n)
        .where((d) => d.isNotEmpty)
        .length;
  }
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
