import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/predicted_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_view_detections.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/widgets/yolo_controller.dart';

/// Lab experiment: feed the detector via `YOLOView` (native streaming inference)
/// and "truncate" the feed with native zoom (`setZoomLevel`, a FOV crop — no
/// distortion). Mobile-only; the web build gets the stub sibling.
///
/// Validates on-device: perf (fps / processingTimeMs vs the predict path),
/// orientation across both phone mounts, cal stability vs zoom, and that
/// `captureFrame()` yields a usable training frame. Detections are shown as
/// **data** (cals n/4 + per-cal confidence, darts + position/confidence), not a
/// painted overlay. Reuses the pure `buildDetectionFrame`; the
/// `YOLOResult → RawDetection` mapping is plugin-bound so it lives here, not in
/// `domain/`.
class YoloZoomExperimentPage extends ConsumerStatefulWidget {
  const YoloZoomExperimentPage({super.key});

  @override
  ConsumerState<YoloZoomExperimentPage> createState() =>
      _YoloZoomExperimentPageState();
}

class _YoloZoomExperimentPageState
    extends ConsumerState<YoloZoomExperimentPage> {
  /// Run native NMS at a low floor so sub-threshold cals still surface in the
  /// readout (mirrors the predict-path HUD); the [_conf] slider filters in Dart.
  static const double _nativeFloor = 0.05;

  final YOLOViewController _controller = YOLOViewController();

  double _zoom = 1.0;
  double _conf = 0.25; // Dart-side acceptance for cals (readout only).
  double _iou = 0.45; // native NMS IoU.
  bool _squareClip = false; // cosmetic; native view may stretch into the square.
  bool _nativeOverlays = false;

  /// Pushes native state once the platform view is live (callbacks only fire
  /// post-init, so calling from there is safe vs a no-op before `init`).
  bool _nativePushed = false;

  DetectionFrame? _frame;
  List<PredictedDart> _darts = const [];
  double _fps = 0;
  double _ms = 0;
  int _manualSeq = 0;

  /// Unique per page-mount so re-entering the Lab doesn't reuse handle keys:
  /// a constant gameId + a reset [_manualSeq] would collide (t0-m1, t0-m2…) and
  /// `CaptureStore.save` overwrites by `(gameId, handle)`, silently clobbering
  /// earlier captures.
  late final String _gameId =
      'lab-yolo-zoom-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureNativeState() {
    if (_nativePushed) return;
    _nativePushed = true;
    _controller.setThresholds(
        confidenceThreshold: _nativeFloor, iouThreshold: _iou);
    _controller.setShowOverlays(_nativeOverlays);
    if (_zoom != 1.0) _controller.setZoomLevel(_zoom);
  }

  void _onResults(List<YOLOResult> results) {
    _ensureNativeState();
    final classed = <ClassedDetection>[
      for (final r in results)
        (
          className: r.className,
          confidence: r.confidence,
          cx: r.normalizedBox.center.dx,
          cy: r.normalizedBox.center.dy,
        ),
    ];
    final frame = buildDetectionFrame(rawDetectionsFromClassed(classed),
        calMinConfidence: _conf, dartMinConfidence: _conf);
    final darts = <PredictedDart>[
      for (final d in classed)
        if (d.className == 'dart')
          PredictedDart(x: d.cx, y: d.cy, conf: d.confidence),
    ];
    if (!mounted) return;
    setState(() {
      _frame = frame;
      _darts = darts;
    });
  }

  void _onMetrics(YOLOPerformanceMetrics m) {
    _ensureNativeState();
    if (!mounted) return;
    setState(() {
      _fps = m.fps;
      _ms = m.processingTimeMs;
    });
  }

  Future<void> _setZoom(double v) async {
    setState(() => _zoom = v);
    await _controller.setZoomLevel(v);
  }

  Future<void> _setIou(double v) async {
    setState(() => _iou = v);
    await _controller.setIoUThreshold(v);
  }

  Future<void> _setNativeOverlays(bool v) async {
    setState(() => _nativeOverlays = v);
    await _controller.setShowOverlays(v);
  }

  Future<void> _capture() async {
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await _controller.captureFrame();
    if (bytes == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Capture échouée (frame indisponible).')));
      return;
    }
    final store = await ref.read(captureStoreProvider.future);
    if (!store.isSupported) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Stockage capture indisponible ici.')));
      return;
    }
    _manualSeq += 1;
    await store.save(
      CaptureRecord(
        predictedDarts: _darts,
        calPoints: _frame?.calPoints ?? const [],
        modelVersion: kAutoScorerModelVersion,
        gameId: _gameId,
        handle: CaptureHandle.manual(turnOrdinal: 0, sequence: _manualSeq),
        timestamp: DateTime.now(),
        // Lab spike: captureFrame() returns the raw camera frame, while
        // YOLOResult coords are normalised to the inference frame. Coord-space
        // alignment for YOLOView captures is an open Lab question, so we tag
        // raw and mark dims unknown with 0 — the convention auto_scorer_session
        // uses for a raw frame whose pixel dims it can't read — rather than let
        // CaptureRecord's 800×800 defaults misrepresent the raw frame.
        frameSpace: FrameSpace.raw,
        frameWidth: 0,
        frameHeight: 0,
      ),
      bytes,
    );
    if (!mounted) return;
    messenger.showSnackBar(
        SnackBar(content: Text('Frame capturée (#$_manualSeq).')));
  }

  @override
  Widget build(BuildContext context) {
    Widget preview = YOLOView(
      modelPath: kAutoScorerModelAsset,
      task: YOLOTask.detect,
      controller: _controller,
      confidenceThreshold: _nativeFloor,
      iouThreshold: _iou,
      lensFacing: LensFacing.back,
      onResult: _onResults,
      onPerformanceMetrics: _onMetrics,
      onZoomChanged: (z) {
        if (mounted) setState(() => _zoom = z);
      },
    );
    if (_squareClip) {
      preview = Center(
        child: AspectRatio(aspectRatio: 1, child: ClipRect(child: preview)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLOView + zoom'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Capturer la frame',
            onPressed: _capture,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              flex: 3, child: Container(color: Colors.black, child: preview)),
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

  Widget _hud() => Text(
        'fps ${StatFormatter.fmtDouble(_fps, decimals: 1)} · '
        '${StatFormatter.fmtDouble(_ms, decimals: 1)} ms',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );

  Widget _params() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slider('Zoom ${StatFormatter.fmtDouble(_zoom, decimals: 1)}×', _zoom,
              1.0, 5.0, _setZoom),
          _slider(
              'Confiance (filtre) ${StatFormatter.fmtDouble(_conf, decimals: 2)}',
              _conf,
              0.05,
              0.9,
              (v) => setState(() => _conf = v)),
          _slider('IoU ${StatFormatter.fmtDouble(_iou, decimals: 2)}', _iou, 0.1,
              0.9, _setIou),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Affichage carré (peut étirer l\'aperçu)'),
            value: _squareClip,
            onChanged: (v) => setState(() => _squareClip = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Overlay natif du plugin'),
            value: _nativeOverlays,
            onChanged: _setNativeOverlays,
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
        Text('fléchettes (≥ ${StatFormatter.fmtDouble(_nativeFloor, decimals: 2)}) : ${_darts.length}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final d in _darts)
          Text('  (${StatFormatter.fmtDouble(d.x, decimals: 3)}, '
              '${StatFormatter.fmtDouble(d.y, decimals: 3)})  '
              'conf ${StatFormatter.fmtDouble(d.conf, decimals: 2)}'),
      ],
    );
  }
}
