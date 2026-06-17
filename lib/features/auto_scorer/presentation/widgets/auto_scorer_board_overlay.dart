import 'dart:async';

import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/camera_zoom_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/detection_thresholds_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/session_recording_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/setup_tips_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_setup_tips_view.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
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

  @override
  void dispose() {
    _collapseTimer?.cancel();
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
      // No predict detector: YOLOView loads its own model. The session just
      // wires the tracker + capture; start() prunes captures to the cap.
      final session = AutoScorerSession(
        captureStore: store,
        modelVersion: kAutoScorerModelVersion,
        traceStore: traceStore,
        recordingSessionId: recordingSessionId,
        recordingGameId: widget.gameId,
      );
      await session.start();
      if (!mounted) return;
      _session = session;
      final calConf =
          ref.read(autoScorerCalConfidenceProvider).value ?? kDefaultConfidence;
      final dartConf = ref.read(autoScorerDartConfidenceProvider).value ??
          kDefaultConfidence;
      final initialZoom =
          (ref.read(autoScorerCameraZoomProvider).value ?? kDefaultCameraZoom)
              .clamp(1.0, 5.0);
      setState(() => _mode = _Mode.aim);
      final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AutoScorerYoloAimView(
          session: session,
          gameId: widget.gameId,
          calConfidence: calConf,
          dartConfidence: dartConf,
          initialZoom: initialZoom,
          onZoomChanged: (z) =>
              ref.read(autoScorerCameraZoomProvider.notifier).set(z),
        ),
      ));
      if (!mounted) return;
      if (done == true) {
        // Serialise the camera handoff before mounting the running preview's
        // YOLOView. `AutoScorerYoloAimView._finish()` already calls
        // `await _controller.stop()` before its `Navigator.pop` (#419), but that
        // only requests the unbind: the native CameraX teardown (surface release
        // + the aim platform-view's own dispose(), which runs only once the route
        // leaves the tree at the END of the ~300ms reverse transition) is
        // asynchronous and not complete when `pop` resolves this push future.
        // Mounting the preview's YOLOView now means its bind races that teardown;
        // at the opt-in 1280×960 analysis resolution (#464) the two sessions'
        // combined surfaces exceed the device's guaranteed CameraX
        // surface-combination budget, so the preview's bindToLifecycle fails
        // (black preview, no detection). At the old ~640×480 default the smaller
        // surfaces tolerated the transient overlap. Wait out the exit transition
        // + native teardown so only one session is ever bound.
        await Future<void>.delayed(_kAimToRunningHandoffDelay);
        if (!mounted) return;
        // The inline preview binds the correction bridge itself (#456/#457) —
        // it owns the camera controller needed to capture-at-correction. This
        // overlay only clears the binding on stop (_stop/_fail).
        setState(() {
          _mode = _Mode.running;
          _starting = false;
        });
      } else {
        _stop();
      }
    } catch (e) {
      _fail(l10n.autoScorerSetupFailed('$e'));
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    ref.read(activeCaptureCorrectionSinkProvider.notifier).bind(null);
    _session?.dispose();
    _session = null;
    _collapseTimer?.cancel();
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
              // Guard: an in-flight onResult from the preview's YOLOView
              // could fire as this shell is disposing; don't write to the
              // already-disposed notifier.
              onStatus: (s) {
                if (!mounted) return;
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
    final hint = running
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context).autoScorerTapToCorrect,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
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
                      // inert so this opaque detector owns the whole surface.
                      // Trade-off: the manual-capture button is disabled while
                      // collapsed (it stays usable in the expanded state).
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
                builder: (_, status, __) =>
                    AutoScorerStatusChip(status: status),
              ),
            ),
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
