import 'dart:async';

import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/model_compatibility.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/aim_outcome.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/calibration_alert.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace_store.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/model_update_provider.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/aim_confirmed_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/camera_zoom_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/detection_thresholds_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/session_recording_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/setup_tips_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/technical_display_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_setup_tips_view.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/contribution_counter_widget.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_yolo_view.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Scoreboard-primary assist-mode camera widget (#377 §5.2). Three layouts:
/// the band variant (`expand: false`, via the core `boardOverlayBuilder` seam)
/// is a slim row under the header (Cricket); the camera-first variant
/// (`expand: true`, via `boardCameraPreviewBuilder`, #427) defaults to a
/// collapsed ~96px VIGNETTE while running (#480) and only fills the flexible
/// body region while tap-expanded (X01). Detection runs on a live `YOLOView`
/// preview shown while running (native streaming inference — YOLOView must be
/// mounted to run, so unlike the old headless path there is now an in-game
/// preview). The one-time aim step is a transient fullscreen `YOLOView` route.
///
/// Web-safe SHELL: it imports only the conditional `auto_scorer_yolo_view.dart`
/// seam (stub on web), NEVER `ultralytics_yolo`/`camera` — `main.dart` imports
/// this file directly, so it stays on the web build path.
///
/// Emits detected darts through the core `DartInputSink` (bound by the board),
/// so it never imports the game feature.
class AutoScorerBoardOverlay extends ConsumerStatefulWidget {
  final String gameId;

  /// Camera-first layout (#427): when true the running preview fills the
  /// available height (the board places this in an `Expanded`) instead of the
  /// slim ~140px band. Idle/aim states are unchanged.
  final bool expand;

  const AutoScorerBoardOverlay(
      {super.key, required this.gameId, this.expand = false});

  @override
  ConsumerState<AutoScorerBoardOverlay> createState() =>
      _AutoScorerBoardOverlayState();
}

enum _Mode { idle, aim, running }

/// How long to wait after the aim route returns before mounting the running
/// preview's `YOLOView`, so the aim route's reverse transition (~300ms Material
/// default) and the asynchronous native camera teardown that outlives the aim
/// view's `_controller.stop()` finish first — only one CameraX session is ever
/// bound at a time. One-time cost per camera start (not per-frame),
/// imperceptible after "Done aiming". See [_AutoScorerBoardOverlayState._start].
const Duration _kAimToRunningHandoffDelay = Duration(milliseconds: 500);

/// Camera-first vignette (#480): collapsed preview height. The preview is
/// near-useless during play once calibrated, so by default it shrinks to this
/// band and the freed space goes to the at-distance game info (#478/#479).
const double kAutoScorerVignettePreviewHeight = 96;

/// How long an expanded preview stays up without interaction before it
/// auto-collapses back to the vignette (#480). A detected dart (or a turn
/// advance) collapses it immediately — any game activity means the player is
/// done checking the framing.
const Duration kAutoScorerVignetteAutoCollapse = Duration(seconds: 10);

class _AutoScorerBoardOverlayState
    extends ConsumerState<AutoScorerBoardOverlay> {
  _Mode _mode = _Mode.idle;
  bool _starting = false;
  AutoScorerSession? _session;

  /// The model resolved once at [_start] (bundled or a staged OTA file, #715),
  /// passed as a prop into the `YOLOView` views + used for the session's
  /// `modelVersion`. Snapshotted so the model never hot-swaps mid-session.
  ResolvedModel? _resolvedModel;
  int _turnOrdinal = 1;
  String? _error;

  /// Camera-first vignette state (#480): false = collapsed ~96px band
  /// (default), true = preview fills the flexible region (tap-to-expand,
  /// auto-collapses — see [kAutoScorerVignetteAutoCollapse]). Lives INSIDE the
  /// overlay (not a constructor parameter like [AutoScorerBoardOverlay.expand])
  /// so flipping it never rebuilds the overlay from outside with new
  /// constructor args — that would restructure the subtree and risk a native
  /// `YOLOView` remount (#467 class of bugs). [_previewKey] preserves the
  /// preview's element/state across the two wrapper shapes.
  bool _vignetteExpanded = false;
  Timer? _collapseTimer;
  final GlobalKey _previewKey = GlobalKey(debugLabel: 'auto-scorer-preview');

  /// Tracker status for the chip. A [ValueNotifier] (not setState) so the live
  /// `onResult` stream (~3 Hz) updates only the chip — never rebuilding the
  /// `YOLOView` preview (which would churn / risk a native remount). The one
  /// exception (#480): a dart detected while the vignette is expanded fires a
  /// single `_collapseVignette()` setState — bounded by user expansion, never
  /// per-frame, and safe because [_previewKey] preserves the preview element.
  final ValueNotifier<TrackerStatus> _status = ValueNotifier(
    const TrackerStatus(
        phase: TrackerPhase.noCalibration, dartsOnBoard: 0, dartsThisTurn: 0),
  );

  /// Training frames persisted for THIS GAME (#742), mirrored from the running
  /// session's counter so the counter widget can pulse as it rises. A notifier
  /// for the same reason as [_status]: it ticks on an async capture path and
  /// must not rebuild the `YOLOView` preview.
  ///
  /// Each camera session counts from zero, so [_contributionsBase] carries what
  /// earlier sessions of this game already contributed: stopping and restarting
  /// the camera mid-game must not look like the contribution was undone.
  final ValueNotifier<int> _contributions = ValueNotifier(0);
  int _contributionsBase = 0;

  /// Whether this camera session has ever had the board calibrated (#741).
  /// Seeded by an aim step that ended with the four markers, then latched by
  /// any preview status whose phase [phaseImpliesCalibration]. It is what
  /// separates "never recognised — learning mode" (calm) from "recognised,
  /// then lost" (the red alert). Reset with the session in [_stop] / [_fail].
  ///
  /// Camera-session scoped on purpose: a game that skips the aim step (#687)
  /// starts at false even though a previous game in this app run may have been
  /// calibrated. That flag says the player confirmed their framing, not that
  /// the board was recognised (it is set for "Continue without auto-scoring"
  /// too), so it is no evidence to seed from — and a session that has genuinely
  /// not seen the board yet is learning mode, which is the honest reading.
  ///
  /// A plain field, not its own notifier: it only ever changes together with a
  /// [_status] update (or before the preview mounts), so the chip's
  /// [ValueListenableBuilder] already rebuilds at exactly the right moments.
  bool _everCalibrated = false;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _contributions.dispose();
    _status.dispose();
    _session?.dispose();
    super.dispose();
  }

  void _expandVignette() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(kAutoScorerVignetteAutoCollapse, _collapseVignette);
    setState(() => _vignetteExpanded = true);
  }

  void _collapseVignette() {
    _collapseTimer?.cancel();
    _collapseTimer = null;
    if (!mounted || !_vignetteExpanded) return;
    setState(() => _vignetteExpanded = false);
  }

  /// idle → (one-time tips) → aim (fullscreen YOLOView) → running (inline preview).
  Future<void> _start() async {
    // Capture l10n up-front — _fail can be reached after awaits where using
    // `context` would be unsafe.
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _starting = true;
    });
    try {
      final tipsSeen = await ref.read(autoScorerSetupTipsSeenProvider.future);
      if (!mounted) return;
      if (!tipsSeen) {
        final proceed = await Navigator.of(context).push<bool>(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const AutoScorerSetupTipsView(),
        ));
        if (!mounted) return;
        if (proceed == null) {
          setState(() => _starting = false);
          return;
        }
        if (proceed) {
          await ref
              .read(autoScorerSetupTipsSeenProvider.notifier)
              .setSeen(true);
          if (!mounted) return;
        }
      }
      if (!kAutoScorerYoloSupported) {
        _fail(l10n.autoScorerNotAvailable);
        return;
      }
      final store = await ref.read(captureStoreProvider.future);
      if (!mounted) return;
      // Session-trace recording (#490): opt-in + device-only. When on, give the
      // session a trace store + a fresh session id so it records this run.
      SessionTraceStore? traceStore;
      String? recordingSessionId;
      if (await ref.read(sessionRecordingEnabledProvider.future)) {
        if (!mounted) return;
        final ts = await ref.read(sessionTraceStoreProvider.future);
        if (ts.isSupported) {
          traceStore = ts;
          recordingSessionId = const Uuid().v4();
        }
      }
      if (!mounted) return;
      // Resolve the effective model once (#715): a staged OTA download if valid,
      // else the bundled asset. Snapshotted here so the whole session uses one
      // consistent (path, version) pair and the model never hot-swaps mid-game.
      final resolved = await ref.read(resolvedModelProvider.future);
      if (!mounted) return;
      _resolvedModel = resolved;
      // No predict detector: YOLOView loads its own model. The session just
      // wires the tracker + capture; start() prunes captures to the cap.
      final session = AutoScorerSession(
        captureStore: store,
        modelVersion: resolved.version,
        traceStore: traceStore,
        recordingSessionId: recordingSessionId,
        recordingGameId: widget.gameId,
      );
      // Acknowledge each stored training frame (#742). Fired from the async
      // capture paths, so it can land after this shell is gone — or after this
      // session was stopped and another started, which is why it checks that
      // the reporting session is still the current one. Without that, a save
      // still in flight at Stop would write its old session's total back over
      // the new session's count (and pulse for a capture that isn't part of
      // it).
      session.onCapturePersisted = (total) {
        if (mounted && identical(_session, session)) {
          _contributions.value = _contributionsBase + total;
        }
      };
      await session.start();
      if (!mounted) return;
      _session = session;
      // Skip the one-time aim step if it was already completed this app run
      // (#687): the running preview re-derives the board transform live from
      // every frame's calibration points, so the aim view is only a positioning
      // confidence gate — scoring is unaffected by skipping it. The "Re-aim"
      // button in the running preview re-runs it if the phone/board moved. No
      // prior camera session to drain here (the aim view didn't bind), so the
      // running preview can mount immediately — no handoff delay needed.
      if (ref.read(autoScorerAimConfirmedProvider)) {
        setState(() {
          _mode = _Mode.running;
          _starting = false;
        });
        return;
      }
      setState(() => _mode = _Mode.aim);
      final outcome = await _runAimView(session);
      if (!mounted) return;
      if (outcome == AimOutcome.cancelled) {
        _stop();
      } else {
        ref.read(autoScorerAimConfirmedProvider.notifier).set(true);
        await Future<void>.delayed(_kAimToRunningHandoffDelay);
        if (!mounted) return;
        setState(() {
          _mode = _Mode.running;
          _starting = false;
        });
      }
    } catch (e) {
      _fail(l10n.autoScorerSetupFailed('$e'));
    }
  }

  /// A staged OTA model failed to load natively (#715). The view already fell
  /// back to the bundled asset for this session; persist the quarantine (delete
  /// + clear staged state) so future sessions also use bundled, and refresh the
  /// resolver. No-op unless a staged model was in play.
  Future<void> _onModelLoadFailed() async {
    final resolved = _resolvedModel;
    if (resolved == null || resolved.origin != ModelOrigin.staged) return;
    // Refresh the snapshot so any later mount this session (e.g. the preview
    // after an aim-view failure, or a re-aim) uses the bundled path/version —
    // otherwise it would re-point at the just-quarantined staged file.
    if (mounted) setState(() => _resolvedModel = kBundledResolvedModel);
    final service = await ref.read(modelUpdateServiceProvider.future);
    await service.quarantine(resolved.version);
    if (!mounted) return;
    ref.invalidate(resolvedModelProvider);
  }

  /// Push the fullscreen aim step and return how it ended. Shared by the
  /// initial [_start] flow and the in-preview [_reAim] button.
  ///
  /// The outcome also (re)seeds [_everCalibrated]: confirming with the four
  /// markers proves the board was recognised, while "Continue without
  /// auto-scoring" is the player choosing to play in learning mode (#741) — so
  /// a re-aim that ends there drops back to learning mode until the tracker
  /// itself reports a calibrated phase.
  ///
  /// That reset is deliberate, including after a session that HAD been
  /// calibrated: the player just re-aimed, could not reacquire the board, and
  /// confirmed a dialog saying they will score by hand. Keeping the red alert
  /// up for the rest of that game would be the exact permanent alarm #741
  /// exists to remove — they have already acted on it.
  Future<AimOutcome> _runAimView(AutoScorerSession session) async {
    final calConf =
        ref.read(autoScorerCalConfidenceProvider).value ?? kDefaultConfidence;
    final dartConf =
        ref.read(autoScorerDartConfidenceProvider).value ?? kDefaultConfidence;
    final initialZoom =
        (ref.read(autoScorerCameraZoomProvider).value ?? kDefaultCameraZoom)
            .clamp(1.0, 5.0);
    // Debug-only opt-in (#738): the plain preview is what a player gets.
    final showOverlays =
        ref.read(autoScorerTechnicalDisplayProvider).value ?? false;
    final outcome =
        await Navigator.of(context).push<AimOutcome>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AutoScorerYoloAimView(
        session: session,
        gameId: widget.gameId,
        modelPath: _resolvedModel!.path,
        calConfidence: calConf,
        dartConfidence: dartConf,
        initialZoom: initialZoom,
        showOverlays: showOverlays,
        onZoomChanged: (z) =>
            ref.read(autoScorerCameraZoomProvider.notifier).set(z),
        onModelLoadFailed: _onModelLoadFailed,
      ),
    ));
    // A system back gesture pops null — same as Cancel.
    final result = outcome ?? AimOutcome.cancelled;
    if (result != AimOutcome.cancelled) {
      _everCalibrated = result == AimOutcome.calibrated;
    }
    return result;
  }

  /// Re-run the aim step from the running preview (#687) — for when the phone or
  /// board has moved. Drop to aim (this unmounts the running preview, releasing
  /// the camera), wait out the native CameraX teardown so only one session is
  /// ever bound (the aim→running handoff comment applies in reverse here), then
  /// re-show the aim view. Cancelling resumes the existing session.
  Future<void> _reAim() async {
    final session = _session;
    if (session == null || _mode != _Mode.running) return;
    setState(() => _mode = _Mode.aim);
    await Future<void>.delayed(_kAimToRunningHandoffDelay);
    if (!mounted) return;
    final outcome = await _runAimView(session);
    if (!mounted) return;
    if (outcome != AimOutcome.cancelled) {
      ref.read(autoScorerAimConfirmedProvider.notifier).set(true);
    }
    // Confirmed or cancelled, resume the live preview after the handoff drain;
    // a cancelled re-aim must not abort the game.
    await Future<void>.delayed(_kAimToRunningHandoffDelay);
    if (!mounted) return;
    setState(() => _mode = _Mode.running);
  }

  void _fail(String message) {
    if (!mounted) return;
    ref.read(activeCaptureCorrectionSinkProvider.notifier).bind(null);
    _session?.dispose();
    _session = null;
    _collapseTimer?.cancel();
    _everCalibrated = false;
    _contributionsBase = _contributions.value;
    setState(() {
      _error = message;
      _starting = false;
      _mode = _Mode.idle;
      _vignetteExpanded = false;
    });
  }

  /// Stop detection and release the camera (back to idle). The inline preview
  /// unmounts on the mode switch → its YOLOView disposes the native camera.
  void _stop() {
    ref.read(activeCaptureCorrectionSinkProvider.notifier).bind(null);
    _session?.dispose();
    _session = null;
    _collapseTimer?.cancel();
    _everCalibrated = false;
    _contributionsBase = _contributions.value;
    setState(() {
      _mode = _Mode.idle;
      _starting = false;
      _vignetteExpanded = false;
    });
  }

  void _removeDarts() {
    final status = _session?.removeDarts();
    if (status != null) _status.value = status;
  }

  @override
  Widget build(BuildContext context) {
    // The board bumps this whenever the turn advances (its own next-turn button);
    // reset the tracker's per-turn cap in lock-step (#380). The tracker reset
    // itself needs no setState (the preview reads [_turnOrdinal] live for
    // capture handles), but a turn advance also collapses an expanded vignette
    // (#480) — game activity means the player is done checking the framing —
    // and THAT does setState (no-op while already collapsed, the common case).
    ref.listen<int>(activeTurnSignalProvider, (_, __) {
      _session?.onTurnAdvanced();
      _turnOrdinal += 1;
      _collapseVignette();
    });
    final scheme = Theme.of(context).colorScheme;
    final running = _mode == _Mode.running && _session != null;
    final preview = running
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AutoScorerYoloPreview(
              // GlobalKey: the preview keeps its element (and the native
              // camera binding) when the vignette flips between the collapsed
              // and expanded wrapper shapes (#480).
              key: _previewKey,
              session: _session!,
              gameId: widget.gameId,
              modelPath: _resolvedModel!.path,
              onModelLoadFailed: _onModelLoadFailed,
              expand: widget.expand,
              currentTurnOrdinal: () => _turnOrdinal,
              calConfidence:
                  ref.watch(autoScorerCalConfidenceProvider).value ??
                      kDefaultConfidence,
              dartConfidence:
                  ref.watch(autoScorerDartConfidenceProvider).value ??
                      kDefaultConfidence,
              initialZoom:
                  (ref.watch(autoScorerCameraZoomProvider).value ??
                          kDefaultCameraZoom)
                      .clamp(1.0, 5.0),
              showOverlays:
                  ref.watch(autoScorerTechnicalDisplayProvider).value ?? false,
              // Guard: an in-flight onResult from the preview's YOLOView
              // could fire as this shell is disposing; don't write to the
              // already-disposed notifier.
              onStatus: (s) {
                if (!mounted) return;
                // Latch the session's calibration memory (#741): reaching any
                // of these phases proves the board was recognised at least
                // once, so a later sustained loss is a real alert and not
                // learning mode.
                if (phaseImpliesCalibration(s.phase)) _everCalibrated = true;
                // A newly detected dart collapses an expanded vignette (#480).
                // Compare before updating the notifier so the delta is real.
                if (_vignetteExpanded &&
                    s.dartsOnBoard > _status.value.dartsOnBoard) {
                  _collapseVignette();
                }
                _status.value = s;
              },
            ),
          )
        : null;
    // The line under the bar row states what the player can do. In learning
    // mode the "tap a dart to correct" tip is moot — nothing is detected — so
    // it gives way to a plain statement of the situation (#741). It listens on
    // [_status] like the chip, because the learning-mode state changes with an
    // incoming status and not with a setState.
    final hint = running
        ? ValueListenableBuilder<TrackerStatus>(
            valueListenable: _status,
            builder: (context, status, __) {
              final l10n = AppLocalizations.of(context);
              final learning = calibrationAlertOf(
                      phase: status.phase, everCalibrated: _everCalibrated) ==
                  CalibrationAlert.learningMode;
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  learning
                      ? l10n.autoScorerLearningModeHint
                      : l10n.autoScorerTapToCorrect,
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              );
            },
          )
        : null;

    // Camera-first vignette (#480): collapsed by default — the preview is
    // near-useless during play once calibrated, so the freed space goes to the
    // at-distance game info above. The compact block sits at the TOP of the
    // camera slot, right under the dart band (a bottom-anchored vignette left
    // an ugly dead gap mid-screen — device-verified on rc112); the slack below
    // stays transparent. Tap expands the preview (auto-collapses on the next
    // detected dart / turn advance / ~10 s).
    if (widget.expand && preview != null && !_vignetteExpanded) {
      return Column(
        children: [
          Material(
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: AppLocalizations.of(context).autoScorerExpandPreview,
                    child: GestureDetector(
                      // The YOLOView platform view consumes touch events
                      // natively (it needs them for tapToFocus), so a plain
                      // parent GestureDetector never wins the gesture arena —
                      // taps died in the camera view (device-verified on
                      // rc112). IgnorePointer makes the collapsed preview
                      // inert so this opaque detector owns the whole surface —
                      // which costs nothing now that the preview carries no
                      // controls of its own (#745).
                      behavior: HitTestBehavior.opaque,
                      onTap: _expandVignette,
                      child: IgnorePointer(
                        child: SizedBox(
                          height: kAutoScorerVignettePreviewHeight,
                          width: double.infinity,
                          child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: preview),
                        ),
                      ),
                    ),
                  ),
                  _barRow(),
                  if (hint != null) hint,
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      );
    }

    final children = <Widget>[
      if (preview != null)
        // Camera-first (expanded vignette): the preview fills the flexible
        // region; band mode: fixed ~140px height (set inside
        // AutoScorerYoloPreview).
        widget.expand
            ? Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(bottom: 4), child: preview))
            : Padding(
                padding: const EdgeInsets.only(bottom: 4), child: preview),
      // In camera-first idle/aim there is no preview yet; centre the Start
      // action in the open space instead of pinning it to the top.
      if (widget.expand && preview == null)
        Expanded(child: Center(child: _barRow()))
      else
        _barRow(),
      if (hint != null) hint,
    ];
    return Material(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _barRow() {
    final l10n = AppLocalizations.of(context);
    if (_mode == _Mode.running) {
      return Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ValueListenableBuilder<TrackerStatus>(
                valueListenable: _status,
                builder: (_, status, __) => AutoScorerStatusChip(
                    status: status, everCalibrated: _everCalibrated),
              ),
            ),
          ),
          // Contribution counter (#742) — only while recording is on: with the
          // opt-in off nothing is ever captured, so a counter would be a
          // permanent zero promising something that isn't happening.
          if (ref.watch(dataCollectionEnabledProvider).value ?? false)
            ValueListenableBuilder<int>(
              valueListenable: _contributions,
              builder: (_, count, __) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ContributionCounter(count: count),
              ),
            ),
          IconButton(
            tooltip: l10n.autoScorerReAim,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _reAim,
          ),
          IconButton(
            tooltip: l10n.autoScorerRemoveDarts,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.cleaning_services),
            onPressed: _removeDarts,
          ),
          IconButton(
            tooltip: l10n.autoScorerStop,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: _stop,
          ),
        ],
      );
    }
    // idle / aim: a single Start action (plus the last error, if any). While the
    // aim modal is up, show a spinner behind it rather than re-exposing "Start".
    final scheme = Theme.of(context).colorScheme;
    final busy = _starting || _mode == _Mode.aim;
    return Row(
      children: [
        Expanded(
          child: Text(
            _error ?? l10n.autoScorerReady,
            style: TextStyle(
                color: _error != null ? scheme.error : scheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          FilledButton.tonalIcon(
            onPressed: _start,
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: Text(l10n.autoScorerStartCamera),
          ),
      ],
    );
  }
}
