import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/auto_scorer/domain/diagnostics/pipeline_timings.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/dart_detector_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/camera_zoom_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/detection_thresholds_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/frame_preprocessor_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/diagnostics_provider.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_cal_overlay_painter.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_timing_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scoreboard-primary assist-mode control bar (#377 §5.2, #382 rework). The
/// X01/Cricket board renders this (via the core `boardOverlayBuilder` seam) as a
/// **slim row directly under the header**, so the scoreboard — including the
/// three-dart indicator — stays fully visible (it is laid out in flow, not
/// floated over the board). Detection runs **headless** once started; the
/// one-time aim step is a transient fullscreen route, not this bar.
///
/// Emits detected darts through the core `DartInputSink` (bound by the board),
/// so it never imports the game feature. Camera/device-only: shows nothing
/// usable on web / unsupported devices (the detector stub reports unsupported).
class AutoScorerBoardOverlay extends ConsumerStatefulWidget {
  final String gameId;

  const AutoScorerBoardOverlay({super.key, required this.gameId});

  @override
  ConsumerState<AutoScorerBoardOverlay> createState() =>
      _AutoScorerBoardOverlayState();
}

enum _Mode { idle, running }

class _AutoScorerBoardOverlayState
    extends ConsumerState<AutoScorerBoardOverlay> {
  _Mode _mode = _Mode.idle;
  bool _starting = false;
  CameraController? _camera;
  AutoScorerSession? _session;
  Timer? _timer;
  bool _busy = false;
  int _turnOrdinal = 1;
  String? _error;
  TrackerStatus _status = const TrackerStatus(
      phase: TrackerPhase.noCalibration, dartsOnBoard: 0, dartsThisTurn: 0);

  /// Rolling per-frame timings for the diagnostics HUD (#377 §3); newest last,
  /// capped so the average tracks recent frames rather than the whole session.
  static const int _maxTimingSamples = 30;
  final List<PipelineTimings> _timings = [];

  /// Latest per-cal-class confidences `[cal1..cal4]` (null = absent), shown in
  /// the diagnostics HUD so the user can tune the calibration threshold.
  List<double?> _calConfidences = const [null, null, null, null];

  /// idle → aiming → running: load the model + open the camera, push a one-time
  /// fullscreen aim preview, then (on "Done") start headless detection. The aim
  /// step is a transient route so this bar never grows to cover the scoreboard.
  Future<void> _start() async {
    setState(() {
      _error = null;
      _starting = true;
    });
    CameraController? controller;
    try {
      final detector = await ref.read(dartDetectorProvider.future);
      if (!mounted) return;
      if (!detector.isSupported) {
        _fail('Auto-scoring is not available on this device.');
        return;
      }
      final store = await ref.read(captureStoreProvider.future);
      final preprocessor = ref.read(framePreprocessorProvider);
      final session = AutoScorerSession(
          detector: detector,
          preprocessor: preprocessor,
          captureStore: store,
          modelVersion: kAutoScorerModelVersion);
      final loaded = await session.start();
      if (!mounted) return;
      if (!loaded) {
        _fail('Detection model not found (see assets/models).');
        return;
      }
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        _fail('No camera found.');
        return;
      }
      controller = CameraController(cameras.first, ResolutionPreset.high,
          enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _session = session;
      _camera = controller;
      // One-time aim: a transient fullscreen modal to position the phone — an
      // ephemeral overlay carrying a live CameraController, not an app screen,
      // so it uses Navigator.push (a routed go_router screen can't take a
      // runtime object). Returns true on "Done", false/null on cancel or back.
      // _starting stays true so the bar shows a spinner behind the modal rather
      // than re-exposing "Start camera".
      // Resolve detection settings once for the aim overlay (this state has
      // `ref`; the aim view stays riverpod-free). Defaults match the providers.
      final skip = ref.read(autoScorerSkipPreprocessProvider).value ?? true;
      final calConf =
          ref.read(autoScorerCalConfidenceProvider).value ?? kDefaultConfidence;
      final dartConf = ref.read(autoScorerDartConfidenceProvider).value ??
          kDefaultConfidence;
      // Resolve the device's zoom range and apply the persisted level once
      // before the aim view opens (#393 setup flow: a tighter frame = more board
      // pixels in the 800 letterbox). A device with no zoom reports
      // minZoom == maxZoom == 1.0, and the aim view hides the slider.
      var minZoom = 1.0;
      var maxZoom = 1.0;
      try {
        minZoom = await controller.getMinZoomLevel();
        maxZoom = await controller.getMaxZoomLevel();
      } catch (_) {
        // Zoom unsupported — leave both at 1.0 (slider hidden).
      }
      final initialZoom = (ref.read(autoScorerCameraZoomProvider).value ??
              kDefaultCameraZoom)
          .clamp(minZoom, maxZoom);
      try {
        await controller.setZoomLevel(initialZoom);
      } catch (_) {
        // Best-effort; the live preview still works at the default level.
      }
      if (!mounted) return;
      final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AutoScorerAimView(
          controller: controller!,
          session: session,
          skipPreprocess: skip,
          calConfidence: calConf,
          dartConfidence: dartConf,
          minZoom: minZoom,
          maxZoom: maxZoom,
          initialZoom: initialZoom,
          onZoomChanged: (z) =>
              ref.read(autoScorerCameraZoomProvider.notifier).set(z),
        ),
      ));
      if (!mounted) return;
      if (done == true) {
        _beginRunning();
      } else {
        _stop();
      }
    } catch (e) {
      // Release the controller if it was created before the failure (e.g.
      // initialize() threw), so the native camera isn't leaked.
      await controller?.dispose();
      _fail('Camera setup failed: $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    // The local controller (if any) is already disposed by the caller; clear
    // the fields so dispose()/_stop() don't double-dispose or leave a dangling
    // reference. The shared detector (via the session) is left intact.
    _camera = null;
    _session = null;
    setState(() {
      _error = message;
      _starting = false;
      _mode = _Mode.idle;
    });
  }

  /// aiming → running: start headless detection (no preview).
  void _beginRunning() {
    if (_camera == null) return;
    setState(() {
      _mode = _Mode.running;
      _starting = false;
    });
    // Capture faster than ~1 Hz inference so a fast third dart isn't starved
    // before the user pulls (#377 §3); inference runs per call.
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) => _tick());
  }

  /// Stop detection and release the camera (back to idle); scoreboard untouched.
  void _stop() {
    _timer?.cancel();
    _timer = null;
    final cam = _camera;
    _camera = null;
    cam?.dispose();
    _session?.dispose();
    _session = null;
    _timings.clear();
    setState(() {
      _mode = _Mode.idle;
      _starting = false;
    });
  }

  Future<void> _tick() async {
    final camera = _camera;
    final session = _session;
    if (_busy || camera == null || session == null) return;
    _busy = true;
    try {
      final captureWatch = Stopwatch()..start();
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      captureWatch.stop();
      if (!mounted) return;
      final collect = ref.read(dataCollectionEnabledProvider).value ?? false;
      // Match the provider's persisted default (#raw-capture brief: native on)
      // so a frame taken before prefs resolve is captured in the right space.
      final skip = ref.read(autoScorerSkipPreprocessProvider).value ?? true;
      final calConf = ref.read(autoScorerCalConfidenceProvider).value ??
          kDefaultConfidence;
      final dartConf = ref.read(autoScorerDartConfidenceProvider).value ??
          kDefaultConfidence;
      final result = await session.onFrame(
        bytes,
        turnOrdinal: _turnOrdinal,
        gameId: widget.gameId,
        collectData: collect,
        skipPreprocess: skip,
        calConfidence: calConf,
        dartConfidence: dartConf,
      );
      if (!mounted) return;
      final sink = ref.read(activeDartInputSinkProvider);
      for (final dart in result.emittedDarts) {
        sink?.submitDart(dart.segment);
      }
      setState(() {
        _recordTimings(result.timings.copyWith(capture: captureWatch.elapsed));
        _status = result.status;
        _calConfidences = result.calConfidences;
      });
    } catch (_) {
      // Drop this frame; the next tick retries.
    } finally {
      _busy = false;
    }
  }

  Future<void> _forceCapture() async {
    final camera = _camera;
    final session = _session;
    if (_busy || camera == null || session == null) return;
    _busy = true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      final skip = ref.read(autoScorerSkipPreprocessProvider).value ?? true;
      final calConf = ref.read(autoScorerCalConfidenceProvider).value ??
          kDefaultConfidence;
      final dartConf = ref.read(autoScorerDartConfidenceProvider).value ??
          kDefaultConfidence;
      final saved = await session.captureCurrentFrame(bytes,
          turnOrdinal: _turnOrdinal,
          gameId: widget.gameId,
          skipPreprocess: skip,
          calConfidence: calConf,
          dartConfidence: dartConf);
      messenger.showSnackBar(SnackBar(
          content: Text(saved
              ? 'Frame saved for training'
              : 'Enable data collection to save frames')));
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  void _removeDarts() {
    final status = _session?.removeDarts();
    if (status != null) setState(() => _status = status);
  }

  void _recordTimings(PipelineTimings t) {
    _timings.add(t);
    if (_timings.length > _maxTimingSamples) _timings.removeAt(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _camera?.dispose();
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The board bumps this whenever the turn advances (via its own next-turn
    // button); reset the tracker's per-turn cap in lock-step so the next
    // player's darts keep emitting (#380).
    ref.listen<int>(activeTurnSignalProvider, (_, __) {
      _session?.onTurnAdvanced();
      _turnOrdinal += 1;
    });
    final scheme = Theme.of(context).colorScheme;
    final hudOn = ref.watch(autoScorerTimingHudEnabledProvider).value ?? false;
    // A full-width strip in the board's layout flow (under the header), so it
    // never overlaps the scoreboard / dart indicator (#377 §5.2).
    return Material(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _barRow(),
            if (_mode == _Mode.running && hudOn && _timings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AutoScorerTimingHud(
                    last: _timings.last,
                    samples: _timings,
                    skipPreprocess:
                        ref.watch(autoScorerSkipPreprocessProvider).value ??
                            false,
                    calConfidences: _calConfidences,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _barRow() {
    if (_mode == _Mode.running) {
      return Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AutoScorerStatusChip(status: _status),
            ),
          ),
          IconButton(
            tooltip: 'Capture frame',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: _forceCapture,
          ),
          IconButton(
            tooltip: 'Remove darts',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.cleaning_services),
            onPressed: _removeDarts,
          ),
          IconButton(
            tooltip: 'Stop auto-scoring',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: _stop,
          ),
        ],
      );
    }
    // Idle: a single Start action (plus the last error, if any).
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            _error ?? 'Auto-scoring ready',
            style: TextStyle(
                color: _error != null ? scheme.error : scheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_starting)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          FilledButton.tonalIcon(
            onPressed: _start,
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text('Start camera'),
          ),
      ],
    );
  }
}

/// One-time fullscreen aim preview (#377 §5.2), pushed as a transient route by
/// the control bar so the persistent UI never covers the scoreboard. Returns
/// `true` on "Done aiming", `false` on cancel.
///
/// Runs detection-only inference on a timer while aiming and overlays the
/// model's per-cal predictions on the live preview, so the user can reframe
/// until all four cals are found. It is handed the already-open [controller] and
/// [session] (owned by the parent) and must NOT dispose either.
class _AutoScorerAimView extends StatefulWidget {
  const _AutoScorerAimView({
    required this.controller,
    required this.session,
    required this.skipPreprocess,
    required this.calConfidence,
    required this.dartConfidence,
    required this.minZoom,
    required this.maxZoom,
    required this.initialZoom,
    required this.onZoomChanged,
  });

  final CameraController controller;
  final AutoScorerSession session;
  final bool skipPreprocess;
  final double calConfidence;
  final double dartConfidence;

  /// Device zoom range (`minZoom == maxZoom` ⇒ no zoom; slider hidden).
  final double minZoom;
  final double maxZoom;

  /// Zoom already applied to [controller] when the view opens.
  final double initialZoom;

  /// Persist the chosen zoom (wired to the camera-zoom notifier by the parent).
  final void Function(double zoom) onZoomChanged;

  @override
  State<_AutoScorerAimView> createState() => _AutoScorerAimViewState();
}

class _AutoScorerAimViewState extends State<_AutoScorerAimView> {
  Timer? _timer;
  bool _busy = false;
  DetectionFrame? _latest;
  // Clamp to the slider's own range, not just [minZoom, maxZoom]: if a device
  // reports maxZoom > the ceiling, the camera was opened at initialZoom but the
  // slider only goes to _sliderMax, so keep the field in lock-step with what the
  // slider can display.
  late double _zoom = widget.initialZoom.clamp(widget.minZoom, _sliderMax);

  /// Cap the slider so a phone reporting a large *digital* zoom (e.g. 8×) can't
  /// be driven into a mushy, low-detail frame that hurts detection.
  static const double _zoomCeiling = 5.0;

  bool get _zoomSupported => widget.maxZoom > widget.minZoom;
  double get _sliderMax => widget.maxZoom.clamp(widget.minZoom, _zoomCeiling);

  @override
  void initState() {
    super.initState();
    // Same cadence + _busy guard as the headless _tick loop.
    _timer = Timer.periodic(
        const Duration(milliseconds: 700), (_) => _detectTick());
  }

  Future<void> _setZoom(double value) async {
    setState(() => _zoom = value);
    try {
      await widget.controller.setZoomLevel(value);
    } catch (_) {
      // Ignore transient failures (e.g. controller mid-transition).
    }
  }

  Future<void> _detectTick() async {
    if (_busy) return;
    _busy = true;
    try {
      final shot = await widget.controller.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      final frame = await widget.session.detectOnly(
        bytes,
        skipPreprocess: widget.skipPreprocess,
        calConfidence: widget.calConfidence,
        dartConfidence: widget.dartConfidence,
      );
      if (!mounted) return;
      setState(() => _latest = frame);
    } catch (_) {
      // Drop this frame; the next tick retries (mirrors _tick).
    } finally {
      _busy = false;
    }
  }

  /// Stop detecting, then return [result]. Cancelling the timer on commit means
  /// no aim-view `takePicture()` fires during the route transition — otherwise
  /// it could race the parent's headless `_tick` (started by `_beginRunning`)
  /// for the same camera.
  void _finish(bool result) {
    _timer?.cancel();
    _timer = null;
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Do NOT dispose controller/session — owned by the parent overlay; the
    // headless run after "Done" reuses them.
    super.dispose();
  }

  /// Zoom control over the live preview. White-on-black to stay legible over the
  /// camera feed (matches the hint text styling in this view). Persists only on
  /// release (`onChangeEnd`) to avoid SharedPrefs churn while dragging.
  Widget _zoomSlider() {
    final clamped = _zoom.clamp(widget.minZoom, _sliderMax);
    return Row(
      children: [
        const Icon(Icons.zoom_out, color: Colors.white, size: 20),
        Expanded(
          child: Slider(
            min: widget.minZoom,
            max: _sliderMax,
            value: clamped,
            onChanged: (v) => _setZoom(v),
            onChangeEnd: widget.onZoomChanged,
          ),
        ),
        const Icon(Icons.zoom_in, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text('${clamped.toStringAsFixed(1)}×',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final calibrated = _latest?.hasCalibration ?? false;
    final found =
        _latest?.calBestPoints.where((p) => p != null).length ?? 0;
    final hint = _latest == null
        ? 'Aim at the board…'
        : calibrated
            ? 'All 4 cals detected — Done aiming'
            : '$found/4 cals — reframe so all 4 show';
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Preview + overlay share one AspectRatio rect, so normalised cal
          // coords map by a plain multiply against the painter's canvas size.
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  CustomPaint(
                    painter: CalOverlayPainter(
                      frame: _latest,
                      skipPreprocess: widget.skipPreprocess,
                      calConfidence: widget.calConfidence,
                      rawFrameSize: controller.value.previewSize,
                      acceptedColor: Theme.of(context).colorScheme.primary,
                      subColor: AppTheme.award(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_zoomSupported) _zoomSlider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton.tonal(
                            onPressed: () => _finish(false),
                            child: const Text('Cancel')),
                        FilledButton.icon(
                          onPressed: () => _finish(true),
                          icon: const Icon(Icons.check),
                          label: const Text('Done aiming'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(hint,
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
