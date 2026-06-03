import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/dart_detector_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scoreboard-primary assist-mode overlay (#377 §5.2, #382 rework). Rendered by
/// the X01/Cricket board (via the core `boardOverlayBuilder` seam) **over** the
/// normal scoreboard, which stays primary. Detection runs **headless** (no
/// fullscreen preview) once started; only the one-time aim step shows a preview.
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

enum _Mode { idle, aiming, running }

class _AutoScorerBoardOverlayState
    extends ConsumerState<AutoScorerBoardOverlay> {
  _Mode _mode = _Mode.idle;
  CameraController? _camera;
  AutoScorerSession? _session;
  Timer? _timer;
  bool _busy = false;
  int _turnOrdinal = 1;
  String? _error;
  TrackerStatus _status = const TrackerStatus(
      phase: TrackerPhase.noCalibration, dartsOnBoard: 0, dartsThisTurn: 0);

  /// idle → aiming: load the model + open the camera (preview shown to aim).
  Future<void> _start() async {
    setState(() {
      _error = null;
      _mode = _Mode.aiming;
    });
    CameraController? controller;
    try {
      final detector = await ref.read(dartDetectorProvider.future);
      if (!mounted) return;
      if (!detector.isSupported) {
        setState(() {
          _error = 'Auto-scoring is not available on this device.';
          _mode = _Mode.idle;
        });
        return;
      }
      final store = await ref.read(captureStoreProvider.future);
      final session = AutoScorerSession(detector: detector, captureStore: store);
      final loaded = await session.start();
      if (!mounted) return;
      if (!loaded) {
        setState(() {
          _error = 'Detection model not found (see assets/models).';
          _mode = _Mode.idle;
        });
        return;
      }
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found.';
          _mode = _Mode.idle;
        });
        return;
      }
      controller = CameraController(cameras.first, ResolutionPreset.high,
          enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _session = session;
        _camera = controller;
      });
    } catch (e) {
      // Release the controller if it was created before the failure (e.g.
      // initialize() threw), so the native camera isn't leaked.
      await controller?.dispose();
      if (mounted) {
        setState(() {
          _error = 'Camera setup failed: $e';
          _mode = _Mode.idle;
        });
      }
    }
  }

  /// aiming → running: hide the preview, start headless detection.
  void _beginRunning() {
    if (_camera == null) return;
    setState(() => _mode = _Mode.running);
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
    setState(() => _mode = _Mode.idle);
  }

  Future<void> _tick() async {
    final camera = _camera;
    final session = _session;
    if (_busy || camera == null || session == null) return;
    _busy = true;
    try {
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      final collect = ref.read(dataCollectionEnabledProvider).value ?? false;
      final result = await session.onFrame(
        bytes,
        turnOrdinal: _turnOrdinal,
        gameId: widget.gameId,
        collectData: collect,
      );
      if (!mounted) return;
      final sink = ref.read(activeDartInputSinkProvider);
      for (final dart in result.emittedDarts) {
        sink?.submitDart(dart.segment);
      }
      setState(() => _status = result.status);
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
      final saved = await session.captureCurrentFrame(bytes,
          turnOrdinal: _turnOrdinal, gameId: widget.gameId);
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
    switch (_mode) {
      case _Mode.aiming:
        return _aimView();
      case _Mode.idle:
      case _Mode.running:
        // A compact, corner cluster — the rest of the board stays touchable
        // (no widget there ⇒ taps fall through to the scoreboard beneath).
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _mode == _Mode.running ? _runningControls() : _idleChip(),
            ),
          ),
        );
    }
  }

  Widget _idleChip() {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: const Icon(Icons.videocam_outlined, size: 18),
      label: Text(_error ?? 'Auto-score'),
      backgroundColor: scheme.secondaryContainer,
      onPressed: _start,
    );
  }

  Widget _runningControls() {
    return Card(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AutoScorerStatusChip(status: _status),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Capture frame',
                  icon: const Icon(Icons.add_a_photo_outlined),
                  onPressed: _forceCapture,
                ),
                IconButton(
                  tooltip: 'Remove darts',
                  icon: const Icon(Icons.cleaning_services),
                  onPressed: _removeDarts,
                ),
                IconButton(
                  tooltip: 'Stop auto-scoring',
                  icon: const Icon(Icons.stop_circle_outlined),
                  onPressed: _stop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _aimView() {
    final camera = _camera;
    return ColoredBox(
      color: Colors.black,
      child: camera == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(camera),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton.tonal(
                              onPressed: _stop, child: const Text('Cancel')),
                          FilledButton.icon(
                            onPressed: _beginRunning,
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
