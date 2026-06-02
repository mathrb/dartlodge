import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/dart_detector_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Assist-mode camera page (#382): live preview while the [AutoScorerSession]
/// detects darts and emits them into the active game via the core
/// `DartInputSink`. The scoreboard stays the primary surface — this is opened
/// from the board's menu and popped when done. Turn advance / "remove darts"
/// are manual (the tracker never advances the turn itself).
///
/// Device-only: needs a camera and a bundled model. On web / unsupported
/// devices it shows an unavailable message (the detector stub reports false).
class AutoScorerCapturePage extends ConsumerStatefulWidget {
  final String gameId;

  const AutoScorerCapturePage({super.key, required this.gameId});

  @override
  ConsumerState<AutoScorerCapturePage> createState() =>
      _AutoScorerCapturePageState();
}

class _AutoScorerCapturePageState extends ConsumerState<AutoScorerCapturePage> {
  CameraController? _camera;
  AutoScorerSession? _session;
  Timer? _timer;
  bool _busy = false;
  int _turnOrdinal = 1;
  String? _error;
  TrackerStatus _status = const TrackerStatus(
      phase: TrackerPhase.noCalibration, dartsOnBoard: 0, dartsThisTurn: 0);

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final detector = await ref.read(dartDetectorProvider.future);
      if (!mounted) return;
      if (!detector.isSupported) {
        setState(() => _error = 'Auto-scoring is not available on this device.');
        return;
      }
      final store = await ref.read(captureStoreProvider.future);
      final session = AutoScorerSession(detector: detector, captureStore: store);
      final loaded = await session.start();
      if (!mounted) return;
      if (!loaded) {
        setState(() => _error =
            'Detection model not found. Bundle the model first (see assets/models).');
        return;
      }
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found.');
        return;
      }
      final controller = CameraController(cameras.first, ResolutionPreset.high,
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
      // Capture faster than the ~1 Hz inference so a fast third dart isn't
      // starved before the user pulls (#377 §3); inference itself runs per call.
      _timer = Timer.periodic(const Duration(milliseconds: 700), (_) => _tick());
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera setup failed: $e');
    }
  }

  Future<void> _tick() async {
    final camera = _camera;
    final session = _session;
    if (_busy || camera == null || session == null) return;
    _busy = true;
    try {
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      // An in-flight tick can resume after dispose() (timer.cancel only stops
      // future fires); bail before touching ref/state on a dead widget.
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

  void _nextTurn() {
    ref.read(activeDartInputSinkProvider)?.advanceTurn();
    _session?.onTurnAdvanced();
    setState(() => _turnOrdinal += 1);
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
    // Clear the sink here (not just on the board's push-return) so it can't
    // leak if the game completes while this page is open and the stack is
    // replaced via go() — that path never returns to the board's unbind.
    ref.read(activeDartInputSinkProvider.notifier).bind(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto-scoring')),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
          : _camera == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Positioned.fill(child: CameraPreview(_camera!)),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: AutoScorerStatusChip(status: _status),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _removeDarts,
                              icon: const Icon(Icons.cleaning_services),
                              label: const Text('Remove darts'),
                            ),
                            FilledButton.icon(
                              onPressed: _nextTurn,
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Next turn'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
