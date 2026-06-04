import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/features/auto_scorer/domain/diagnostics/pipeline_timings.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/dart_detector_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/detection_thresholds_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/frame_preprocessor_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/diagnostics_provider.dart';
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
          detector: detector, preprocessor: preprocessor, captureStore: store);
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
      final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AutoScorerAimView(controller: controller!),
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
      final skip = ref.read(autoScorerSkipPreprocessProvider).value ?? false;
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
      final skip = ref.read(autoScorerSkipPreprocessProvider).value ?? false;
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
class _AutoScorerAimView extends StatelessWidget {
  const _AutoScorerAimView({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel')),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check),
                      label: const Text('Done aiming'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Aim at the board, then Done',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
