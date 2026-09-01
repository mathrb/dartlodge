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
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_camera_bar_widget.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_yolo_view.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Scoreboard-primary assist-mode camera widget (#377 §5.2). One layout: the
/// running preview fills the flexible body region the board gives it (via
/// `boardCameraPreviewBuilder`, #427), and shrinks with it (#760). Detection
/// runs on that live `YOLOView` preview (native streaming inference — YOLOView
/// must be mounted to run, so unlike the old headless path there is an in-game
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

  const AutoScorerBoardOverlay({super.key, required this.gameId});

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

  /// Tracker status for the chip. A [ValueNotifier] (not setState) so the live
  /// `onResult` stream (~3 Hz) updates only the chip — never rebuilding the
  /// `YOLOView` preview (which would churn / risk a native remount).
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
  ///
  /// The halo is a second reader (#758) and pulls it live rather than through a
  /// rebuild, which is why the preview grades itself only after publishing the
  /// status that may have just latched this flag.
  bool _everCalibrated = false;

  @override
  void dispose() {
    _contributions.dispose();
    _status.dispose();
    _session?.dispose();
    super.dispose();
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
    _everCalibrated = false;
    _contributionsBase = _contributions.value;
    setState(() {
      _error = message;
      _starting = false;
      _mode = _Mode.idle;
    });
  }

  /// Stop detection and release the camera (back to idle). The inline preview
  /// unmounts on the mode switch → its YOLOView disposes the native camera.
  void _stop() {
    ref.read(activeCaptureCorrectionSinkProvider.notifier).bind(null);
    _session?.dispose();
    _session = null;
    _everCalibrated = false;
    _contributionsBase = _contributions.value;
    setState(() {
      _mode = _Mode.idle;
      _starting = false;
    });
  }

  void _removeDarts() {
    final status = _session?.removeDarts();
    if (status != null) _status.value = status;
  }

  @override
  Widget build(BuildContext context) {
    // The board bumps this whenever the turn advances (its own next-turn
    // button); reset the tracker's per-turn cap in lock-step (#380). No
    // setState: the preview reads [_turnOrdinal] live for capture handles.
    ref.listen<int>(activeTurnSignalProvider, (_, __) {
      _session?.onTurnAdvanced();
      _turnOrdinal += 1;
    });
    final scheme = Theme.of(context).colorScheme;
    final running = _mode == _Mode.running && _session != null;
    final preview = running
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AutoScorerYoloPreview(
              session: _session!,
              gameId: widget.gameId,
              modelPath: _resolvedModel!.path,
              onModelLoadFailed: _onModelLoadFailed,
              currentTurnOrdinal: () => _turnOrdinal,
              everCalibrated: () => _everCalibrated,
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

    // One camera view (#760). The preview takes the space the board gives it
    // and shrinks with it; there is no collapsed/expanded pair any more.
    //
    // This deliberately reverses #480, which collapsed the preview to a ~96px
    // vignette by default and gave the rest to the at-distance game info. That
    // choice was device-verified, but it was made between two ways of placing
    // the slack — never against having none: on device the leftover read as an
    // unfinished screen (#760). Giving the space back to the preview is what
    // the maintainer chose after seeing it. Do not reintroduce the pair.
    //
    // What happens when the board has very little room to give is #769, not
    // this: the preview simply gets less here, and it is never hidden — it IS
    // the detector, so hiding it would stop auto-scoring.
    final children = <Widget>[
      if (preview != null)
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(bottom: 4), child: preview)),
      // In idle/aim there is no preview yet; centre the Start action in the
      // open space instead of pinning it to the top.
      if (preview == null)
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
          children: children,
        ),
      ),
    );
  }

  Widget _barRow() {
    final l10n = AppLocalizations.of(context);
    if (_mode == _Mode.running) {
      final recording = ref.watch(dataCollectionEnabledProvider).value ?? false;
      // The whole row listens, not just the chip: the calibration alert decides
      // whether re-aim is surfaced beside it, and the counter appears with the
      // first capture (#761).
      return ValueListenableBuilder<TrackerStatus>(
        valueListenable: _status,
        builder: (_, status, __) => ValueListenableBuilder<int>(
          valueListenable: _contributions,
          builder: (_, count, __) => AutoScorerCameraBar(
            status: status,
            everCalibrated: _everCalibrated,
            contributions: count,
            showContributions: recording,
            onReAim: _reAim,
            onRemoveDarts: _removeDarts,
            onStop: _stop,
          ),
        ),
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
