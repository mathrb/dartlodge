import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/data/preprocessing/square_crop.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/dart_detector_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lab experiment: feed the **predict** detector a centred **square crop** of the
/// camera frame, to answer the core question — *does a square crop improve cal /
/// dart detection vs the full landscape frame?* Mobile-only; web gets the stub.
///
/// This is a QUALITY probe, not a perf one: the Dart decode→crop→encode adds the
/// known preprocess lag (surfaced in the HUD so it's quantified), which is fine
/// — we only care whether the square detects the board better. The crop is
/// handed to `detect(..., skipPreprocess: true)` so the plugin's letterbox is a
/// no-op pad and detections come back normalised to the crop. Detections are
/// shown as **data** (cals n/4 + per-cal confidence, dart positions), not an
/// overlay. Mount the phone so the board is upright (no rotation handling here).
class SquareCropExperimentPage extends ConsumerStatefulWidget {
  const SquareCropExperimentPage({super.key});

  @override
  ConsumerState<SquareCropExperimentPage> createState() =>
      _SquareCropExperimentPageState();
}

class _SquareCropExperimentPageState
    extends ConsumerState<SquareCropExperimentPage> {
  CameraController? _camera;
  DartDetector? _detector;
  Timer? _timer;
  bool _busy = false;
  String? _error;

  double _zoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _conf = 0.25;
  bool _squareGuide = true;

  DetectionFrame? _frame;
  int _captureMs = 0;
  int _cropMs = 0;
  int _detectMs = 0;

  bool get _zoomSupported => _maxZoom > _minZoom;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final detector = await ref.read(dartDetectorProvider.future);
      if (!mounted) return;
      if (!detector.isSupported) {
        _fail('Détection indisponible sur cet appareil.');
        return;
      }
      final loaded = await detector.load();
      if (!mounted) return;
      if (!loaded) {
        _fail('Modèle introuvable (assets/models).');
        return;
      }
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        _fail('Aucune caméra trouvée.');
        return;
      }
      final cam = CameraController(cameras.first, ResolutionPreset.high,
          enableAudio: false);
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      try {
        _minZoom = await cam.getMinZoomLevel();
        _maxZoom = await cam.getMaxZoomLevel();
      } catch (_) {
        // Zoom unsupported — leave both at 1.0 (slider hidden).
      }
      _detector = detector;
      _camera = cam;
      setState(() {});
      _timer = Timer.periodic(
          const Duration(milliseconds: 700), (_) => _tick());
    } catch (e) {
      _fail('Init caméra échouée : $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  Future<void> _tick() async {
    final cam = _camera;
    final det = _detector;
    if (_busy || cam == null || det == null) return;
    _busy = true;
    try {
      final sw = Stopwatch()..start();
      final shot = await cam.takePicture();
      final bytes = await shot.readAsBytes();
      final captureMs = sw.elapsedMilliseconds;
      sw
        ..reset()
        ..start();
      final cropped = squareCropEncoded(bytes) ?? bytes;
      final cropMs = sw.elapsedMilliseconds;
      sw
        ..reset()
        ..start();
      // skipPreprocess: true → the plugin letterboxes the already-square crop
      // (no-op pad), so the model sees the crop and coords map to it.
      final frame = await det.detect(cropped,
          skipPreprocess: true, calConfidence: _conf, dartConfidence: _conf);
      final detectMs = sw.elapsedMilliseconds;
      if (!mounted) return;
      setState(() {
        _frame = frame;
        _captureMs = captureMs;
        _cropMs = cropMs;
        _detectMs = detectMs;
      });
    } catch (_) {
      // Drop this frame; the next tick retries.
    } finally {
      _busy = false;
    }
  }

  Future<void> _setZoom(double v) async {
    setState(() => _zoom = v);
    try {
      await _camera?.setZoomLevel(v);
    } catch (_) {
      // Best-effort; the preview still works at the default level.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Dispose only the local camera — the detector is a shared keepAlive
    // provider instance (also used by the real scoring path); don't dispose it.
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop carré → predict')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : _camera == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(flex: 3, child: _preview()),
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _hud(),
                            const Divider(),
                            _params(),
                            const Divider(),
                            _readout(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _preview() {
    final cam = _camera!;
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(cam),
          if (_squareGuide)
            // Static framing aid: the centred square fed to the model (the short
            // side of the preview). NOT a detection overlay — just shows the crop
            // region so the user can frame the board inside it.
            Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6), width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hud() => Text(
        'capture ${_captureMs}ms · crop ${_cropMs}ms · detect ${_detectMs}ms',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );

  Widget _params() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_zoomSupported)
            _slider('Zoom ${StatFormatter.fmtDouble(_zoom, decimals: 1)}×',
                _zoom, _minZoom, _maxZoom.clamp(_minZoom, 5.0), _setZoom),
          _slider(
              'Confiance (filtre) ${StatFormatter.fmtDouble(_conf, decimals: 2)}',
              _conf,
              0.05,
              0.9,
              (v) => setState(() => _conf = v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repère du carré croppé'),
            value: _squareGuide,
            onChanged: (v) => setState(() => _squareGuide = v),
          ),
        ],
      );

  Widget _slider(String label, double value, double min, double max,
          ValueChanged<double> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged),
          ],
        ),
      );

  Widget _readout() {
    final f = _frame;
    if (f == null) return const Text('En attente de détections…');
    final found = f.calBestPoints.where((p) => p != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('cals : $found/4${f.hasCalibration ? '  ✓ calibré' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        for (var i = 0; i < f.calConfidences.length; i++)
          Text('  cal${i + 1} : '
              '${f.calConfidences[i] == null ? '—' : StatFormatter.fmtDouble(f.calConfidences[i], decimals: 2)}'
              '${(f.calConfidences[i] ?? 0) >= _conf ? '  ✓' : ''}'),
        const SizedBox(height: 6),
        Text('fléchettes (≥ ${StatFormatter.fmtDouble(_conf, decimals: 2)}) : ${f.dartCandidates.length}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final d in f.dartCandidates)
          Text('  (${StatFormatter.fmtDouble(d.x, decimals: 3)}, '
              '${StatFormatter.fmtDouble(d.y, decimals: 3)})'),
      ],
    );
  }
}
