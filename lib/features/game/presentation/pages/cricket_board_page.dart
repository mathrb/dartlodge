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
import '../../domain/models/game_state.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/active_cricket_game_provider.dart';
import '../sound/wire_game_sounds.dart';
import '../widgets/cap_winner_selection_dialog_widget.dart';
import '../widgets/cricket_marks_strip_widget.dart';
import '../widgets/cricket_unified_table_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/game_status_bar_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';
import '../widgets/live_average.dart';
import '../widgets/prominent_dart_band_widget.dart';
import '../widgets/pulsing_next_button_widget.dart';

/// Trailing-menu actions on the active-game board (#331). Mirrors the
/// X01 board's enum; kept local to each board so the menu shape can
/// diverge per-game without coupling.
enum _BoardMenuAction { endGame, settings, reportBug }

/// Routes camera-detected darts into the active Cricket game (#382). Bound in
/// the core [activeDartInputSinkProvider] while the capture page is open, so the
/// auto_scorer feature emits without importing the game feature.
class _CricketDartInputSink implements DartInputSink {
  _CricketDartInputSink(this._ref, this._gameId);
  final WidgetRef _ref;
  final String _gameId;

  @override
  void submitDart(String segment, {double? x, double? y}) => _ref
      .read(activeCricketGameProvider(_gameId).notifier)
      .processDart(segment, inputMethod: 'camera', x: x, y: y);

  @override
  void advanceTurn() {
    // No-op when a modal/celebration is pending or the game is over, so an
    // auto-advance on board-clear never dismisses a leg/game-win modal. The
    // non-interactive advance intentionally skips Cricket's "<3 darts" confirm
    // dialog — a detected board clear means the throw is done.
    final s = _ref.read(activeCricketGameProvider(_gameId)).value;
    if (s == null ||
        s.gameState.isComplete ||
        s.pendingLegWinnerId != null ||
        s.pendingGameWinnerId != null ||
        s.pendingCapSelection) {
      return;
    }
    _ref.read(activeCricketGameProvider(_gameId).notifier).nextPlayer();
    _ref.read(activeTurnSignalProvider.notifier).bump();
  }
}

class CricketBoardPage extends ConsumerStatefulWidget {
  const CricketBoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<CricketBoardPage> createState() => _CricketBoardPageState();
}

class _CricketBoardPageState extends ConsumerState<CricketBoardPage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // Bind this game as the dart sink so the auto-scorer overlay (when active)
    // emits detected darts into it (#382). No unbind on dispose — the sink's
    // only consumer is the overlay on this board, so a stale sink is never
    // invoked; the next board rebinds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(activeDartInputSinkProvider.notifier)
            .bind(_CricketDartInputSink(ref, widget.gameId));
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

    // Sound effects: per-mark ticks (single/triple), hit/miss fallback; cricket
    // has no bust.
    wireCricketSounds(
      ref,
      activeCricketGameProvider(widget.gameId),
      gameStateOf: (s) => s?.gameState,
    );

    ref.listen(activeCricketGameProvider(widget.gameId), (prev, next) {
      final prevValue = prev?.value;
      final nextValue = next.value;
      if (nextValue == null) return;
      final gs = nextValue.gameState;

      final prevCap = prevValue?.pendingCapSelection ?? false;
      if (!prevCap && nextValue.pendingCapSelection) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => CapWinnerSelectionDialogWidget(
              competitors: gs.competitors,
              onSelect: (id) => ref
                  .read(activeCricketGameProvider(widget.gameId).notifier)
                  .selectCapWinner(id),
            ),
          );
        });
      }

      final prevLeg = prevValue?.pendingLegWinnerId;
      final nextLeg = nextValue.pendingLegWinnerId;
      if (prevLeg == null && nextLeg != null) {
        final winner =
            gs.competitors.firstWhere((c) => c.competitorId == nextLeg);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => LegCompleteModalWidget(
              winnerName: winner.name,
              legNumber: gs.currentLegIndex,
              onNextLeg: () => ref
                  .read(activeCricketGameProvider(widget.gameId).notifier)
                  .dismissLegModal(),
            ),
          );
        });
      }

      final prevComplete = prevValue?.gameState.isComplete ?? false;
      if (!prevComplete && gs.isComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.go(GameRoutes.postGame(widget.gameId));
        });
      }
    });

    final asyncState = ref.watch(activeCricketGameProvider(widget.gameId));
    final autoScoringOn = ref.watch(autoScoringEnabledProvider).value ?? false;
    final cameraPreview = ref.watch(boardCameraPreviewBuilderProvider);

    return asyncState.when(
      loading: () => const Scaffold(
        body: LoadingSpinnerWidget(),
      ),
      error: (err, _) => Scaffold(
        body: ErrorRetryWidget(
          title: l10n.commonError,
          message: '$err',
          onRetry: () =>
              ref.invalidate(activeCricketGameProvider(widget.gameId)),
        ),
      ),
      data: (activeGameState) {
        if (activeGameState == null) {
          return Scaffold(
            body: Center(child: Text(l10n.gameNotFound)),
          );
        }

        final gameState = activeGameState.gameState;

        // Header label composes scoring + target mode so players can tell
        // at a glance whether they're on Random / Crazy / Fixed targets in
        // addition to the scoring variant (#332). Match the format the
        // variant picker uses (`variant_selection_page.dart`):
        //   - Fixed scoring=cut-throat/no-score → "Cut Throat" / "No Score"
        //   - Fixed scoring=standard            → "Standard"
        //   - Random/Crazy + standard scoring   → "Random" / "Crazy"
        //   - Random/Crazy + non-standard      → "Random · Cut Throat", …
        final scoringLabel = switch (gameState.cricketScoring) {
          'cut-throat' => 'Cut Throat',
          'no-score' => 'No Score',
          _ => 'Standard',
        };
        final targetModeLabel = switch (gameState.cricketTargetMode) {
          'random' => 'Random',
          'crazy' => 'Crazy',
          _ => null,
        };
        final variantLabel = targetModeLabel == null
            ? scoringLabel
            : (gameState.cricketScoring == 'standard'
                ? targetModeLabel
                : '$targetModeLabel · $scoringLabel');

        final activeCompetitor =
            gameState.competitors[gameState.currentTurnIndex];
        final allDarts = activeCompetitor.dartThrows;
        final n = gameState.dartsThrownInTurn;
        final currentTurnDarts = n == 0 || allDarts.length < n
            ? <String>[]
            : allDarts.sublist(allDarts.length - n);

        final notifier =
            ref.read(activeCricketGameProvider(widget.gameId).notifier);

        final dartsThrownInTurn = gameState.dartsThrownInTurn;
        final canUndo = dartsThrownInTurn > 0 ||
            gameState.competitors.any((c) => c.dartThrows.isNotEmpty);
        final canNext = !gameState.isComplete;
        final cameraFirst = autoScoringOn && cameraPreview != null;

        // Targets in the unified table's display order (descending + Bull),
        // and each competitor's per-target mark counts, for the compact
        // camera-first marks strip.
        final displayTargets = [
          ...([...gameState.cricketTargets]..sort((a, b) => b.compareTo(a))),
          25,
        ];
        List<CricketMarksRow> marksRows() => [
              for (var i = 0; i < gameState.competitors.length; i++)
                (
                  name: gameState.competitors[i].name,
                  marks: [
                    for (final t in displayTargets)
                      gameState.competitors[i]
                              .marksPerNumber[t == 25 ? 'Bull' : '$t'] ??
                          0,
                  ],
                  score: gameState.competitors[i].score,
                  isActive: i == gameState.currentTurnIndex,
                  // Live MPR (#696) on the game's actual target set (+ Bull),
                  // matching the manual table's per-player MPR.
                  mpr: cricketLiveMprDisplay(
                    gameState.competitors[i],
                    targets: {...gameState.cricketTargets, 25},
                  ),
                ),
            ];

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
                // Three-dot menu — see #331 in x01_board_page.dart for
                // rationale (gear icon implied Settings while the action
                // was End Game).
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
                configLabel: variantLabel,
                currentLegIndex: gameState.currentLegIndex,
                legsToWin: gameState.legsToWin,
                roundInLeg: gameState.currentRoundInLeg,
                totalRounds: gameState.cricketTotalRounds,
                currentTurnDarts: currentTurnDarts,
                // Manual mode: tap a thrown dart to correct it (#376).
                // Camera-first (#444) hides the darts here — they move to the
                // prominent dart band below.
                onDartTapped: gameState.isComplete || cameraFirst
                    ? null
                    : (index) =>
                        _showCorrectionSheet(context, gameState, index),
                showDarts: !cameraFirst,
              ),
              if (cameraFirst) ...[
                // Camera-first (#444): marks strip keeps every player's marks +
                // score visible, then the prominent dart band, then the camera
                // region (a collapsed ~96px vignette by default, tap-expands to
                // fill, #480). Manual entry / correction lives in the band's
                // modal.
                CricketMarksStripWidget(
                  targets: displayTargets,
                  rows: marksRows(),
                  showScore: gameState.cricketScoring != 'no-score',
                ),
                ProminentDartBandWidget(
                  currentTurnDarts: currentTurnDarts,
                  // A thrown slot opens correction; an empty slot opens manual
                  // entry for a dart the camera missed (#427).
                  onDartTapped: gameState.isComplete
                      ? null
                      : (index) => _onSlotTapped(
                          context, gameState, index, dartsThrownInTurn),
                  tapEmptySlots:
                      !gameState.isComplete && gameState.turnActive,
                ),
                Expanded(child: cameraPreview(context, widget.gameId)),
              ] else
                // Manual mode keeps the full scoring table.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLarge),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLarge),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: AppTheme.shadowAlphaCard),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CricketUnifiedTableWidget(
                          gameState: gameState,
                          onSegmentTapped: (gameState.isComplete ||
                                  !gameState.turnActive)
                              ? (_) {}
                              : (segment) => notifier.processDart(segment),
                          onMiss: (gameState.isComplete ||
                                  !gameState.turnActive)
                              ? () {}
                              : () => notifier.processDart('MISS'),
                        ),
                      ),
                    ),
                  ),
                ),
              _BottomActionBar(
                canUndo: canUndo,
                canNext: canNext,
                isMultiplayer: gameState.competitors.length > 1,
                dartsThrownInTurn: dartsThrownInTurn,
                pulseNext: canNext && !gameState.turnActive,
                onUndo: () => notifier.undoDart(),
                onNextRound: () {
                  notifier.nextPlayer();
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

  void _confirmBack(BuildContext context) => _showEndConfirm(context);

  /// Per-dart correction (#376): tapping dart [dartIndex] of the current turn
  /// opens the cricket scoring grid; picking a number (or MISS) replaces that
  /// dart and closes the sheet. The notifier resolves the dart's event id and
  /// recomputes state.
  void _showCorrectionSheet(
      BuildContext context, GameState gameState, int dartIndex) {
    final notifier =
        ref.read(activeCricketGameProvider(widget.gameId).notifier);
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
              height: MediaQuery.of(sheetContext).size.height * 0.6,
              child: CricketUnifiedTableWidget(
                gameState: gameState,
                // Correction sheet (#590): keep closed rows tappable so a dart
                // that closed the number can be re-targeted (e.g. T12 → single
                // 12). The correction re-applies through the engine.
                allowClosedRows: true,
                onSegmentTapped: (segment) {
                  notifier.correctTurnDart(dartIndex, segment);
                  Navigator.of(sheetContext).pop();
                },
                onMiss: () {
                  notifier.correctTurnDart(dartIndex, 'MISS');
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
  void _onSlotTapped(BuildContext context, GameState gameState, int index,
      int dartsThrownInTurn) {
    if (index < dartsThrownInTurn) {
      _showCorrectionSheet(context, gameState, index);
    } else {
      _showEntrySheet(context);
    }
  }

  /// Manual-entry modal hosting the cricket scoring table — the camera-first
  /// replacement for the always-visible table. Submits the picked segment (or
  /// MISS) as the next dart. Watches the live turn so it disables if the turn
  /// ends while open (e.g. the camera fills the 3rd dart).
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
              height: MediaQuery.of(sheetContext).size.height * 0.6,
              child: Consumer(
                builder: (ctx, ref, _) {
                  final s =
                      ref.watch(activeCricketGameProvider(widget.gameId)).value;
                  if (s == null) return const SizedBox.shrink();
                  final notifier = ref.read(
                      activeCricketGameProvider(widget.gameId).notifier);
                  final active =
                      !s.gameState.isComplete && s.gameState.turnActive;
                  return CricketUnifiedTableWidget(
                    gameState: s.gameState,
                    onSegmentTapped: active
                        ? (segment) {
                            // Manual entry = camera missed this dart; capture
                            // the frame as labelled training data (#537).
                            ref
                                .read(activeCaptureCorrectionSinkProvider)
                                ?.captureManualEntry(segment: segment);
                            notifier.processDart(segment);
                            Navigator.of(sheetContext).pop();
                          }
                        : (_) {},
                    onMiss: active
                        ? () {
                            ref
                                .read(activeCaptureCorrectionSinkProvider)
                                ?.captureManualEntry(segment: 'MISS');
                            notifier.processDart('MISS');
                            Navigator.of(sheetContext).pop();
                          }
                        : () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndGameDialog(BuildContext context) => _showEndConfirm(context);

  void _showEndConfirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EndGameDialogWidget(
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          // Mark the game as abandoned (winner=null) so it appears in
          // history. Without this, the game stays `is_complete=0` until
          // the next game starts and the lazy abandonment in
          // GameSetupNotifier.startGame fires — leaving a discoverability
          // gap if the user just exits (issue #252).
          await ref
              .read(activeCricketGameProvider(widget.gameId).notifier)
              .endGame();
          if (!context.mounted) return;
          context.go(GameRoutes.home);
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.canUndo,
    required this.canNext,
    required this.isMultiplayer,
    required this.dartsThrownInTurn,
    required this.pulseNext,
    required this.onUndo,
    required this.onNextRound,
  });

  final bool canUndo;
  final bool canNext;
  final bool isMultiplayer;
  final int dartsThrownInTurn;
  final bool pulseNext;
  final VoidCallback onUndo;
  final VoidCallback onNextRound;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // #627: NEXT is gated on ≥1 dart (mis-tap guard, consistent across all
    // boards) and advances with no confirmation — `nextPlayer()` silently
    // fills the unthrown darts with MISS. A deliberate pass = throw a MISS.
    final canAdvance = canNext && dartsThrownInTurn > 0;

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
                onPressed: canAdvance ? onNextRound : null,
                pulse: pulseNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

