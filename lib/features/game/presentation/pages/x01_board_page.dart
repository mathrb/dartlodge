import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../app/app_router.dart';
import '../../../../core/game/dart_input_sink.dart';
import '../../../../core/providers/auto_scorer_providers.dart';
import '../../../../core/providers/board_camera_preview_provider.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/checkout_table.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/active_game_provider.dart';
import '../sound/wire_game_sounds.dart';
import '../widgets/cap_winner_selection_dialog_widget.dart';
import '../widgets/dart_input_grid_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_status_bar_widget.dart';
import '../widgets/hero_metric_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';
import '../widgets/player_score_section_widget.dart';
import '../widgets/prominent_dart_band_widget.dart';
import '../widgets/pulsing_next_button_widget.dart';
import '../widgets/x01_other_players_strip_widget.dart';

/// Trailing-menu actions on the active-game board (#331). End Game keeps
/// the original gear-icon behaviour; Settings is a new sibling so users
/// can reach Settings without abandoning their game.
enum _BoardMenuAction { endGame, settings }

/// Routes camera-detected darts into the active X01 game (#382). Registered in
/// the core [activeDartInputSinkProvider] while the capture page is open, so the
/// auto_scorer feature emits without importing the game feature.
class _X01DartInputSink implements DartInputSink {
  _X01DartInputSink(this._ref, this._gameId);
  final WidgetRef _ref;
  final String _gameId;

  @override
  void submitDart(String segment, {double? x, double? y}) => _ref
      .read(activeGameProvider(_gameId).notifier)
      .processDart(segment, inputMethod: 'camera', x: x, y: y);

  @override
  void advanceTurn() {
    // No-op when a modal/celebration is pending or the game is over: advanceTurn
    // dismisses the bust/leg modals, so an auto-advance on board-clear must not
    // fire past a checkout/leg/game win the player hasn't acknowledged yet.
    final s = _ref.read(activeGameProvider(_gameId)).value;
    if (s == null ||
        s.gameState.isComplete ||
        s.showBust ||
        s.pendingLegWinnerId != null ||
        s.pendingGameWinnerId != null ||
        s.pendingCapSelection) {
      return;
    }
    _ref.read(activeGameProvider(_gameId).notifier).advanceTurn();
    _ref.read(activeTurnSignalProvider.notifier).bump();
  }
}

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
    WakelockPlus.enable();
    // Bind this game as the dart sink so the auto-scorer overlay (when active)
    // emits detected darts into it (#382). No unbind on dispose: the sink's
    // only consumer is the overlay, which lives on this board, so a stale sink
    // is never invoked — and mutating a provider during dispose is illegal. The
    // next board rebinds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(activeDartInputSinkProvider.notifier)
            .bind(_X01DartInputSink(ref, widget.gameId));
      }
    });
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
    WakelockPlus.disable();
    _bustFlashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Sound effects: hit/miss per dart, bust on a bust.
    wireGameSounds(
      ref,
      activeGameProvider(widget.gameId),
      gameStateOf: (s) => s?.gameState,
      bustOf: (s) => s?.showBust ?? false,
    );

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
          context.go(GameRoutes.postGame(widget.gameId));
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
    final autoScoringOn = ref.watch(autoScoringEnabledProvider).value ?? false;
    final cameraPreview = ref.watch(boardCameraPreviewBuilderProvider);

    return asyncState.when(
      loading: () => Scaffold(
        body: LoadingSpinnerWidget(color: cs.primary),
      ),
      error: (err, _) => Scaffold(
        body: ErrorRetryWidget(
          title: l10n.commonError,
          message: '$err',
          onRetry: () => ref.invalidate(activeGameProvider(widget.gameId)),
        ),
      ),
      data: (activeGameState) {
        if (activeGameState == null) {
          return Scaffold(
            body: Center(child: Text(l10n.gameNotFound)),
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
        final cameraFirst = autoScoringOn && cameraPreview != null;

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
                    // Three-dot menu (was a settings cog) because the icon
                    // convention strongly implied Settings while the action
                    // opened the End Game dialog (#331). Menu now exposes
                    // both End Game and Settings entries so users can reach
                    // either without abandoning their current state.
                    trailing: PopupMenuButton<_BoardMenuAction>(
                      icon: Icon(
                        Icons.more_vert,
                        color: cs.onSurface,
                        semanticLabel: l10n.gameOptionsSemantic,
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case _BoardMenuAction.endGame:
                            _showEndGameDialog(context);
                          case _BoardMenuAction.settings:
                            context.push(GameRoutes.settings);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _BoardMenuAction.endGame,
                          child: Text(l10n.gameMenuEndGame),
                        ),
                        PopupMenuItem(
                          value: _BoardMenuAction.settings,
                          child: Text(l10n.settingsTitle),
                        ),
                      ],
                    ),
                  ),
                  GameStatusBarWidget(
                    configLabel: '${gameState.startingScore}',
                    currentLegIndex: gameState.currentLegIndex,
                    legsToWin: gameState.legsToWin,
                    roundInLeg: roundInLeg,
                    totalRounds: gameState.x01TotalRounds,
                    currentTurnDarts: currentTurnDarts,
                    // Manual mode: tap a thrown dart to correct it (#376).
                    // Camera-first (#443) hides the darts here — they move to
                    // the prominent dart band below.
                    onDartTapped: gameState.isComplete || cameraFirst
                        ? null
                        : (index) => _showCorrectionSheet(context, index),
                    showDarts: !cameraFirst,
                  ),
                  if (cameraFirst) ...[
                    // Camera-first (#443): active player's remaining score as
                    // the at-distance hero, then checkout, the other players'
                    // scores, the prominent dart band, and the camera region (a
                    // collapsed ~96px vignette by default, tap-expands to fill,
                    // #480). Manual entry / correction lives in the band's modal.
                    HeroMetricWidget(
                      value: '${activeCompetitor.score}',
                      label: activeCompetitor.name,
                    ),
                    _CheckoutBanner(
                      score: currentScore,
                      outStrategy: gameState.outStrategy,
                      dartsThrownInTurn: dartsThrownInTurn,
                      large: true,
                    ),
                    if (gameState.competitors.length > 1)
                      X01OtherPlayersStripWidget(
                        players: [
                          for (int i = 0;
                              i < gameState.competitors.length;
                              i++)
                            if (i != gameState.currentTurnIndex)
                              (
                                name: gameState.competitors[i].name,
                                score: gameState.competitors[i].score,
                              ),
                        ],
                      ),
                    ProminentDartBandWidget(
                      currentTurnDarts: currentTurnDarts,
                      // A thrown slot opens correction; an empty slot opens
                      // manual entry for a dart the camera missed (#427).
                      onDartTapped: gameState.isComplete
                          ? null
                          : (index) =>
                              _onSlotTapped(context, index, dartsThrownInTurn),
                      // Empty-slot manual entry only while the turn is live —
                      // adding a dart to an inactive turn would throw.
                      tapEmptySlots:
                          !gameState.isComplete && gameState.turnActive,
                    ),
                    Expanded(child: cameraPreview(context, widget.gameId)),
                  ] else ...[
                    PlayerScoreSectionWidget(
                      gameState: gameState,
                      bustFlashAnim: _bustFlashAnim,
                    ),
                    _CheckoutBanner(
                      score: currentScore,
                      outStrategy: gameState.outStrategy,
                      dartsThrownInTurn: dartsThrownInTurn,
                    ),
                    Expanded(
                      child: DartInputGridWidget(
                        onSegmentTapped: (segment) => ref
                            .read(activeGameProvider(widget.gameId).notifier)
                            .processDart(segment),
                        enabled:
                            !gameState.isComplete && gameState.turnActive,
                      ),
                    ),
                  ],
                  _BottomActionBar(
                    canUndo: canUndo,
                    canNext: canNext,
                    isMultiplayer: gameState.competitors.length > 1,
                    pulseNext: canNext && !gameState.turnActive,
                    onUndo: () => ref
                        .read(activeGameProvider(widget.gameId).notifier)
                        .undoDart(),
                    onNextRound: () {
                      ref
                          .read(activeGameProvider(widget.gameId).notifier)
                          .advanceTurn();
                      // Tell the auto-scorer overlay (if active) to reset its
                      // per-turn cap, so emission isn't wedged for the next
                      // player (#380).
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

  void _confirmBack(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EndGameDialogWidget(
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          // Mark the game abandoned (winner=null) so it appears in history
          // AND the stats projection runner gets a clean reset at the game
          // boundary. Without this, the next won game's bestLegPpr would
          // accumulate darts from this abandoned game (#280). Mirrors the
          // cricket equivalent introduced for #252 / PR #262.
          await ref
              .read(activeGameProvider(widget.gameId).notifier)
              .endGame();
          if (!context.mounted) return;
          context.go(GameRoutes.home);
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  /// Per-dart correction (#376): tapping dart [dartIndex] of the current turn
  /// opens the input grid; picking a segment replaces that dart and closes the
  /// sheet. The notifier resolves the dart's event id and recomputes state.
  void _showCorrectionSheet(BuildContext context, int dartIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                AppLocalizations.of(context).gameCorrectDart(dartIndex + 1),
                style: AppTextStyles.titleMedium,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.55,
              child: DartInputGridWidget(
                onSegmentTapped: (segment) {
                  ref
                      .read(activeGameProvider(widget.gameId).notifier)
                      .correctTurnDart(dartIndex, segment);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Camera-first dart-indicator tap (#427): a thrown slot opens correction; an
  /// empty slot opens manual entry for a dart the camera missed.
  void _onSlotTapped(BuildContext context, int index, int dartsThrownInTurn) {
    if (index < dartsThrownInTurn) {
      _showCorrectionSheet(context, index);
    } else {
      _showEntrySheet(context);
    }
  }

  /// Manual-entry modal hosting the standard [DartInputGridWidget] — the
  /// camera-first replacement for the always-visible grid. Submits the picked
  /// segment as the next dart of the turn.
  void _showEntrySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(AppLocalizations.of(context).gameEnterDart,
                  style: AppTextStyles.titleMedium),
            ),
            SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.55,
              // Watch the live turn so the grid disables if the turn ends while
              // the sheet is open (e.g. the camera fills the 3rd dart) — guards
              // against submitting to a closed turn.
              child: Consumer(
                builder: (ctx, ref, _) {
                  final s = ref.watch(activeGameProvider(widget.gameId)).value;
                  final active = s != null &&
                      !s.gameState.isComplete &&
                      s.gameState.turnActive;
                  return DartInputGridWidget(
                    enabled: active,
                    onSegmentTapped: (segment) {
                      // A manual entry means the camera missed this dart —
                      // capture the frame as labelled training data (#537).
                      ref
                          .read(activeCaptureCorrectionSinkProvider)
                          ?.captureManualEntry(segment: segment);
                      ref
                          .read(activeGameProvider(widget.gameId).notifier)
                          .processDart(segment);
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

  void _showEndGameDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EndGameDialogWidget(
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          await ref
              .read(activeGameProvider(widget.gameId).notifier)
              .endGame();
          if (!context.mounted) return;
          context.go(GameRoutes.home);
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _CheckoutBanner extends StatelessWidget {
  const _CheckoutBanner({
    required this.score,
    required this.outStrategy,
    required this.dartsThrownInTurn,
    this.large = false,
  });

  final int score;
  final String outStrategy;
  final int dartsThrownInTurn;

  /// Camera-first (#478): render the suggestion at-distance readable (the
  /// player stands at the oche, ~2.4 m from the mounted phone). Manual mode
  /// keeps the compact banner.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inRange = score >= minCheckoutScore(outStrategy) &&
        score <= maxCheckoutScore(outStrategy);
    final rawSuggestion =
        inRange ? checkoutSuggestionForStrategy(score, outStrategy) : null;
    // Only surface suggestions reachable with the darts left in this turn —
    // a 3-dart route is misleading on the 3rd dart of a turn (#367).
    final remainingDarts = 3 - dartsThrownInTurn;
    final suggestion = (rawSuggestion != null &&
            dartsRequiredForCheckout(rawSuggestion) <= remainingDarts)
        ? rawSuggestion
        : null;
    final highlight = suggestion != null;

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
                width: highlight ? 2 : 0,
                color: cs.primaryFixed,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  // At 412px (Pixel 6A) the long suggestion-hint text used
                  // to butt up against the CHECKOUT label with no visible
                  // gap ("CHECKOUTSuggestions appear..."). Add a 12px gap
                  // and let the suggestion text ellipsise so the two labels
                  // never collide (#330).
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CHECKOUT',
                        style: (large
                                ? AppTextStyles.labelMedium
                                : AppTextStyles.labelSmall)
                            .copyWith(
                          color: highlight
                              ? cs.onSurfaceVariant
                              : cs.onSurfaceVariant.withValues(alpha: 0.35),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          suggestion ??
                              AppLocalizations.of(context).gameCheckoutHint,
                          // The at-distance bump applies only to a REAL
                          // suggestion: the placeholder at headlineMedium
                          // ellipsised ("Suggestions app…") on a 412dp screen
                          // (device-verified on rc112), and it's not an
                          // at-distance info anyway.
                          style: (large && highlight
                                  ? AppTextStyles.headlineMedium
                                  : AppTextStyles.labelLarge)
                              .copyWith(
                            color: highlight
                                ? cs.primaryFixed
                                : cs.onSurfaceVariant.withValues(alpha: 0.25),
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    final l10n = AppLocalizations.of(context);

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
                    semanticLabel: l10n.gameUndoLastDart,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Next player / round — primary neon button
            Expanded(
              child: PulsingNextButtonWidget(
                label: isMultiplayer ? l10n.gameNextPlayer : l10n.gameNextRound,
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



