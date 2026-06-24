import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';

import '../../../../app/app_router.dart';
import '../../../../core/feedback/report_bug.dart';
import '../../../../core/game/dart_input_sink.dart';
import '../../../../core/providers/auto_scorer_providers.dart';
import '../../../../core/providers/board_camera_preview_provider.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/active_count_up_provider.dart';
import '../sound/wire_game_sounds.dart';
import '../widgets/dart_input_grid_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_status_bar_widget.dart';
import '../widgets/hero_metric_widget.dart';
import '../widgets/live_average.dart';
import '../widgets/player_score_section_widget.dart';
import '../widgets/prominent_dart_band_widget.dart';
import '../widgets/pulsing_next_button_widget.dart';
import '../widgets/x01_other_players_strip_widget.dart';

/// Auto-scorer → Count-Up emit sink (#601). Mirrors the X01/practice boards so
/// the camera (and the Playwright sim bridge) can drive a Count-Up game.
/// Camera darts are tagged `inputMethod: 'camera'` so a later correction can
/// re-label the captured training frame (#658). Count-Up's `processDart` still
/// drops x/y — impact positions aren't tracked (no Count-Up heatmap yet, #571).
class _CountUpDartInputSink implements DartInputSink {
  _CountUpDartInputSink(this._ref, this._gameId);
  final WidgetRef _ref;
  final String _gameId;

  @override
  void submitDart(String segment, {double? x, double? y}) {
    // A fire-and-forget camera dart can arrive after the turn's 3rd dart (turn
    // no longer active, NEXT not yet tapped) or after the game completes.
    // Count-Up's processDart THROWS on an invalid dart (→ AsyncValue error →
    // the board swaps to the error screen), so drop it here — mirrors the
    // X01 camera guard (#538). The manual grid is already turnActive-gated.
    final s = _ref.read(activeCountUpProvider(_gameId)).value;
    if (s == null || s.gameState.isComplete || !s.gameState.turnActive) return;
    _ref
        .read(activeCountUpProvider(_gameId).notifier)
        .processDart(segment, inputMethod: 'camera');
  }

  @override
  void advanceTurn() {
    final s = _ref.read(activeCountUpProvider(_gameId)).value;
    // No-op when complete or before any dart this turn (a board-clear at turn
    // start must not skip the player). Mirrors the other boards' guard.
    if (s == null || s.gameState.isComplete || s.gameState.dartsThrownInTurn == 0) {
      return;
    }
    _ref.read(activeCountUpProvider(_gameId).notifier).advanceTurn();
    _ref.read(activeTurnSignalProvider.notifier).bump();
  }
}

/// Trailing-menu actions on the active count-up board (#331). Mirrors the
/// X01/Cricket boards so users can reach Settings without abandoning
/// their game.
enum _BoardMenuAction { endGame, settings, reportBug }

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
    // Register the auto-scorer→game emit sink (#601), post-frame to avoid
    // mutating a provider during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(activeDartInputSinkProvider.notifier)
            .bind(_CountUpDartInputSink(ref, widget.gameId));
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
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final autoScoringOn = ref.watch(autoScoringEnabledProvider).value ?? false;
    final cameraPreview = ref.watch(boardCameraPreviewBuilderProvider);

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
          title: l10n.commonError,
          message: '$err',
          onRetry: () => ref.invalidate(activeCountUpProvider(widget.gameId)),
        ),
      ),
      data: (activeState) {
        if (activeState == null) {
          return Scaffold(
            body: Center(child: Text(l10n.gameNotFound)),
          );
        }

        final gameState = activeState.gameState;
        final activeCompetitor =
            gameState.competitors[gameState.currentTurnIndex];
        final dartsThrownInTurn = gameState.dartsThrownInTurn;
        final canUndo = dartsThrownInTurn > 0 ||
            gameState.competitors.any((c) => c.dartThrows.isNotEmpty);
        // #627: NEXT gated on ≥1 dart (mis-tap guard, consistent across boards);
        // 1–2 darts advance silently with MISS-fill, no confirmation.
        final canNext =
            !gameState.isComplete && gameState.dartsThrownInTurn > 0;

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

        // Camera-first layout (#601): when auto-scoring is on and a board
        // camera preview is available, replace the manual grid with the hero
        // score + prominent dart band + live preview, mirroring X01.
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
                  // Three-dot menu — see #331 (gear icon misleadingly
                  // implied Settings while the action was End Game).
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
                        case _BoardMenuAction.reportBug:
                          showReportBugDialog(context);
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
                      // Report a Bug without leaving the game (#688). Gated on
                      // crash reporting being active this run, like Settings.
                      if (isBugReportingAvailable())
                        PopupMenuItem(
                          value: _BoardMenuAction.reportBug,
                          child: Text(l10n.settingsReportBug),
                        ),
                    ],
                  ),
                ),
                GameStatusBarWidget(
                  configLabel: 'COUNT-UP',
                  roundInLeg: gameState.currentRoundInLeg,
                  totalRounds: gameState.countUpTotalRounds,
                  currentTurnDarts: currentTurnDarts,
                  // Manual mode: tap a thrown dart to correct it (#657).
                  // Camera-first hides the darts here — they move to the
                  // prominent dart band below.
                  onDartTapped: gameState.isComplete || cameraFirst
                      ? null
                      : (index) => _showCorrectionSheet(context, index),
                  showDarts: !cameraFirst,
                ),
                if (cameraFirst) ...[
                  HeroMetricWidget(
                    value: '${activeCompetitor.score}',
                    label: activeCompetitor.name,
                  ),
                  if (gameState.competitors.length > 1)
                    X01OtherPlayersStripWidget(
                      players: [
                        for (int i = 0; i < gameState.competitors.length; i++)
                          if (i != gameState.currentTurnIndex)
                            (
                              name: gameState.competitors[i].name,
                              score: gameState.competitors[i].score,
                              // Live per-round average (#696), same helper as
                              // X01; for Count-Up it reads as the points/round.
                              ppr: x01LivePprDisplay(gameState.competitors[i]),
                            ),
                      ],
                    ),
                  ProminentDartBandWidget(
                    currentTurnDarts: currentTurnDarts,
                    // Empty slot → manual entry for a dart the camera missed.
                    onDartTapped: gameState.isComplete
                        ? null
                        : (index) => _onSlotTapped(context, index, dartsThrownInTurn),
                    tapEmptySlots: !gameState.isComplete && gameState.turnActive,
                  ),
                  Expanded(child: cameraPreview(context, widget.gameId)),
                ] else ...[
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
                ],
                _BottomActionBar(
                  canUndo: canUndo,
                  canNext: canNext,
                  isMultiplayer: gameState.competitors.length > 1,
                  pulseNext: canNext && turnDone,
                  onUndo: () => ref
                      .read(activeCountUpProvider(widget.gameId).notifier)
                      .undoDart(),
                  onNextRound: () {
                    ref
                        .read(activeCountUpProvider(widget.gameId).notifier)
                        .advanceTurn();
                    // Reset the auto-scorer's per-turn cap for the next player.
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

  /// Camera-first dart-indicator tap (#657): a thrown slot opens correction; an
  /// empty slot opens manual entry for a dart the camera missed.
  void _onSlotTapped(BuildContext context, int index, int dartsThrownInTurn) {
    if (index < dartsThrownInTurn) {
      _showCorrectionSheet(context, index);
    } else {
      _showEntrySheet(context);
    }
  }

  /// Per-dart correction (#657): tapping dart [dartIndex] of the current turn
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
                      .read(activeCountUpProvider(widget.gameId).notifier)
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

  /// Manual entry for a dart the camera missed: opens the standard input grid in
  /// a modal and submits the picked segment as the next dart of the turn.
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
              // the sheet is open (e.g. the camera fills the 3rd dart).
              child: Consumer(
                builder: (ctx, ref, _) {
                  final s =
                      ref.watch(activeCountUpProvider(widget.gameId)).value;
                  final enabled = s != null &&
                      !s.gameState.isComplete &&
                      s.gameState.turnActive;
                  return DartInputGridWidget(
                    enabled: enabled,
                    onSegmentTapped: (segment) {
                      // A manual entry means the camera missed this dart —
                      // capture the frame as labelled training data (#658).
                      ref
                          .read(activeCaptureCorrectionSinkProvider)
                          ?.captureManualEntry(segment: segment);
                      ref
                          .read(activeCountUpProvider(widget.gameId).notifier)
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
                    semanticLabel: l10n.gameUndoLastDart,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
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
