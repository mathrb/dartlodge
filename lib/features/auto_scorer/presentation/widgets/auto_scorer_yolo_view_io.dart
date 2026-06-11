import 'dart:async';

import 'package:dart_lodge/core/game/capture_correction_sink.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_view_detections.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/calibration_stability.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/framing_metrics.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/auto_advance.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/auto_advance_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/widgets/yolo_controller.dart';

/// True on mobile (io): the YOLOView-backed auto-scorer is available.
const bool kAutoScorerYoloSupported = true;

const DetectionFrame _emptyFrame =
    DetectionFrame(calPoints: [], dartCandidates: []);

/// Run native NMS at a low floor so sub-threshold cals still surface in the aim
/// readout (mirrors the predict path's HUD floor); per-class acceptance is
/// applied in [buildDetectionFrame].
const double _nativeFloor = 0.05;

const double _zoomMin = 1.0;
const double _zoomMax = 5.0;

/// Requested CameraX analysis resolution for live detection (#461). The model
/// input is 800×800; CameraX's default analysis frame (~640×480) is below that,
/// so it was letterboxed + upscaled and small-object detail (dart tips) lost.
/// 1280×960 keeps both dims ≥ 800 (no upscaling). Opt-in via `ultralytics_yolo`
/// ≥ 0.6.4 (upstream #529); CameraX falls back to the nearest supported size and
/// it's a no-op where unsupported, so this is non-regressive. Coords are
/// normalised against the analysis frame, so overlays/scoring are unaffected;
/// inference cost is unchanged (model input fixed) — only the per-frame copy
/// grows. Tune on-device against FPS.
const Size kAutoScorerAnalysisResolution = Size(1280, 960);

double _floor(double calConf, double dartConf) =>
    [_nativeFloor, calConf, dartConf].reduce((a, b) => a < b ? a : b);

/// Map a YOLOView result stream into our [DetectionFrame] (cals + dart
/// candidates). The plugin-bound `YOLOResult → ClassedDetection` step lives here;
/// the pure mapping is the merged `rawDetectionsFromClassed` + `buildDetectionFrame`.
DetectionFrame _detectionFrameFrom(
    List<YOLOResult> results, double calConf, double dartConf) {
  final classed = <ClassedDetection>[
    for (final r in results)
      (
        className: r.className,
        confidence: r.confidence,
        cx: r.normalizedBox.center.dx,
        cy: r.normalizedBox.center.dy,
      ),
  ];
  return buildDetectionFrame(
    rawDetectionsFromClassed(classed),
    calMinConfidence: calConf,
    dartMinConfidence: dartConf,
  );
}

/// Fullscreen one-time aim/calibration view backed by `YOLOView` (native
/// streaming inference) instead of CameraController + takePicture. Feeds each
/// `onResult` to the [CalibrationStabilityGate]; "Done aiming" enables once the
/// four cals have held steady. Zoom drives the native `setZoomLevel`; native
/// overlays draw the detection boxes (no Dart-side coord mapping) — but the
/// "Capture photo" button grabs a clean full-resolution still via
/// `capturePhoto(withOverlays: false)`, not the annotated preview snapshot.
/// Returns true on Done, false on Cancel/back. Riverpod-free (state + a session
/// handle).
class AutoScorerYoloAimView extends StatefulWidget {
  const AutoScorerYoloAimView({
    super.key,
    required this.session,
    required this.gameId,
    required this.calConfidence,
    required this.dartConfidence,
    required this.initialZoom,
    required this.onZoomChanged,
  });

  final AutoScorerSession session;
  final String gameId;
  final double calConfidence;
  final double dartConfidence;
  final double initialZoom;
  final ValueChanged<double> onZoomChanged;

  @override
  State<AutoScorerYoloAimView> createState() => _AutoScorerYoloAimViewState();
}

class _AutoScorerYoloAimViewState extends State<AutoScorerYoloAimView> {
  final YOLOViewController _controller = YOLOViewController();
  final CalibrationStabilityGate _gate = CalibrationStabilityGate();

  bool _nativePushed = false;
  DetectionFrame? _latest;
  CalibrationStability _stability = (stableFrames: 0, isReady: false);
  late double _zoom = widget.initialZoom.clamp(_zoomMin, _zoomMax);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureNative() {
    if (_nativePushed) return;
    _nativePushed = true;
    _controller.setShowOverlays(true);
    if (_zoom != 1.0) _controller.setZoomLevel(_zoom);
  }

  void _onResults(List<YOLOResult> results) {
    _ensureNative();
    final frame =
        _detectionFrameFrom(results, widget.calConfidence, widget.dartConfidence);
    final stability = _gate.update(frame);
    if (!mounted) return;
    setState(() {
      _latest = frame;
      _stability = stability;
    });
  }

  Future<void> _setZoom(double v) async {
    setState(() => _zoom = v);
    try {
      await _controller.setZoomLevel(v);
    } catch (_) {
      // Best-effort; the preview still works at the previous level.
    }
  }

  Future<void> _capture() async {
    final messenger = ScaffoldMessenger.of(context);
    // `capturePhoto(withOverlays: false)`, NOT `captureFrame()`: the latter
    // snapshots the on-screen preview (widget-sized, zoom-cropped) and bakes the
    // detection overlay in. We want a clean full-resolution still for training.
    final bytes = await _controller.capturePhoto(withOverlays: false);
    if (!mounted) return;
    if (bytes == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Capture failed (no frame).')));
      return;
    }
    await widget.session.persistManualCapture(_latest ?? _emptyFrame, bytes,
        turnOrdinal: 0, gameId: widget.gameId);
    if (!mounted) return;
    messenger.showSnackBar(
        const SnackBar(content: Text('Frame saved for training')));
  }

  Future<void> _finish(bool done) async {
    // Release the aim camera BEFORE the route pops: the in-game preview mounts
    // its own YOLOView as soon as the modal returns, and two YOLOViews live
    // during the ~300ms pop animation would contend for the hardware camera
    // ("camera busy"). Stopping here is the YOLOView equivalent of the old aim
    // view cancelling its timer before pop (#408).
    try {
      await _controller.stop();
    } catch (_) {
      // Best-effort; dispose() still tears the controller down.
    }
    if (!mounted) return;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(done);
  }

  @override
  Widget build(BuildContext context) {
    final calibrated = _latest?.hasCalibration ?? false;
    final found = _latest?.calBestPoints.where((p) => p != null).length ?? 0;
    final fill = _latest == null ? 0.0 : frameFillRatio(_latest!.calBestPoints);
    final ready = _stability.isReady;
    final hint = _latest == null
        ? 'Aim at the board…'
        : !calibrated
            ? '$found/4 markers — reframe so all 4 show. Any board rotation is fine.'
            : !ready
                ? 'Hold steady… ${_stability.stableFrames}/${_gate.requiredStableFrames}'
                : fill < kGoodFillRatio
                    ? 'Ready — move closer or zoom in for better accuracy, or Done aiming'
                    : 'Ready — Done aiming';
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          YOLOView(
            modelPath: kAutoScorerModelAsset,
            task: YOLOTask.detect,
            controller: _controller,
            confidenceThreshold:
                _floor(widget.calConfidence, widget.dartConfidence),
            iouThreshold: 0.45,
            lensFacing: LensFacing.back,
            streamingConfig: const YOLOStreamingConfig(
                analysisResolution: kAutoScorerAnalysisResolution),
            onResult: _onResults,
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
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _zoomSlider(),
                    FilledButton.tonalIcon(
                      onPressed: _capture,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Capture photo'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton.tonal(
                            onPressed: () => _finish(false),
                            child: const Text('Cancel')),
                        FilledButton.icon(
                          onPressed: ready ? () => _finish(true) : null,
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
        ],
      ),
    );
  }

  Widget _zoomSlider() => Row(
        children: [
          const Icon(Icons.zoom_out, color: Colors.white),
          Expanded(
            child: Slider(
              value: _zoom.clamp(_zoomMin, _zoomMax),
              min: _zoomMin,
              max: _zoomMax,
              onChanged: _setZoom,
              onChangeEnd: widget.onZoomChanged,
            ),
          ),
          Text('${StatFormatter.fmtDouble(_zoom, decimals: 1)}×',
              style: const TextStyle(color: Colors.white)),
        ],
      );
}

/// Always-on small in-game preview (~140px) backed by `YOLOView`. Each
/// `onResult` is mapped to a [DetectionFrame] and fed to the session's tracker
/// ([AutoScorerSession.processDetectionFrame]); emitted darts go to the active
/// `DartInputSink`. Capture-on-emit grabs a clean full-resolution still via
/// `capturePhoto(withOverlays: false)` only when darts emit AND data-collection
/// is on. Native overlays draw the on-screen boxes but are NOT in the capture.
class AutoScorerYoloPreview extends ConsumerStatefulWidget {
  const AutoScorerYoloPreview({
    super.key,
    required this.session,
    required this.gameId,
    required this.currentTurnOrdinal,
    required this.calConfidence,
    required this.dartConfidence,
    required this.initialZoom,
    required this.onStatus,
    this.expand = false,
  });

  final AutoScorerSession session;
  final String gameId;
  final int Function() currentTurnOrdinal;
  final double calConfidence;
  final double dartConfidence;
  final double initialZoom;
  final ValueChanged<TrackerStatus> onStatus;

  /// Camera-first layout (#427): fill the parent's height (the board places this
  /// in an `Expanded`) instead of the fixed ~140px band.
  final bool expand;

  @override
  ConsumerState<AutoScorerYoloPreview> createState() =>
      _AutoScorerYoloPreviewState();
}

class _AutoScorerYoloPreviewState extends ConsumerState<AutoScorerYoloPreview>
    implements CaptureCorrectionSink {
  final YOLOViewController _controller = YOLOViewController();
  bool _nativePushed = false;
  DetectionFrame _latest = _emptyFrame;

  /// Whether any dart has been seen on the board since the last turn advance —
  /// the guard for auto-advance-on-clear, so a `rebaselined` frame from a board
  /// that sat empty at turn start (no darts thrown) doesn't skip the player.
  /// Reset on every turn advance (manual or auto) via the `activeTurnSignal`
  /// listener in [build].
  bool _sawDartsThisTurn = false;

  @override
  void initState() {
    super.initState();
    // This preview owns the correction bridge (#456/#457): it has the camera
    // controller needed to capture-at-correction in partial mode. Bind from a
    // post-frame callback (ref mutation outside build). No unbind in dispose
    // (illegal there) — the overlay's _stop/_fail bind(null), and correctDart
    // guards on `mounted`, mirroring the DartInputSink bridge.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeCaptureCorrectionSinkProvider.notifier).bind(this);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Propagate a user dart-correction (#456/#457). In "all" mode the capture was
  /// already saved at emission, so rewrite its sidecar. In "partial" mode nothing
  /// was saved, so capture the current frame now and store a new corrected
  /// capture (capture-at-correction). Fire-and-forget — a missed capture must
  /// never disrupt scoring.
  @override
  void correctDart({required int dartInTurnOrdinal, required String segment}) {
    if (!mounted) return;
    // Respect the data-collection opt-in: with it off we never touch the capture
    // store — in partial mode this would otherwise silently write a frame the
    // user opted out of (the store is non-null even when collection is off).
    if (!(ref.read(dataCollectionEnabledProvider).value ?? false)) return;
    final mode =
        ref.read(captureModeSettingProvider).value ?? CaptureMode.all;
    if (mode == CaptureMode.all) {
      unawaited(widget.session.applyDartCorrection(
        gameId: widget.gameId,
        turnOrdinal: widget.currentTurnOrdinal(),
        dartInTurnOrdinal: dartInTurnOrdinal,
        segment: segment,
      ));
    } else {
      unawaited(_captureCorrected(dartInTurnOrdinal, segment));
    }
  }

  Future<void> _captureCorrected(int dartInTurnOrdinal, String segment) async {
    try {
      // Full-resolution still without the baked-in overlay (see `_capture`).
      final bytes = await _controller.capturePhoto(withOverlays: false);
      if (!mounted || bytes == null) return;
      await widget.session.persistCorrectedCapture(
        frame: _latest,
        bytes: bytes,
        turnOrdinal: widget.currentTurnOrdinal(),
        dartInTurnOrdinal: dartInTurnOrdinal,
        gameId: widget.gameId,
        segment: segment,
      );
    } catch (_) {
      // A missed training capture must never disrupt scoring.
    }
  }

  void _ensureNative() {
    if (_nativePushed) return;
    _nativePushed = true;
    _controller.setShowOverlays(true);
    final z = widget.initialZoom.clamp(_zoomMin, _zoomMax);
    if (z != 1.0) _controller.setZoomLevel(z);
  }

  void _onResults(List<YOLOResult> results) {
    _ensureNative();
    final frame =
        _detectionFrameFrom(results, widget.calConfidence, widget.dartConfidence);
    _latest = frame;
    final result = widget.session.processDetectionFrame(frame);
    final sink = ref.read(activeDartInputSinkProvider);
    for (final d in result.emittedDarts) {
      sink?.submitDart(d.segment);
    }
    // Auto-capture on emission only in "all" mode; in "partial" mode captures
    // happen only at correction time (#457, see [correctDart]).
    if (result.emittedDarts.isNotEmpty &&
        (ref.read(dataCollectionEnabledProvider).value ?? false) &&
        (ref.read(captureModeSettingProvider).value ?? CaptureMode.all) ==
            CaptureMode.all) {
      unawaited(_captureEmitted(frame, result.firstEmittedDartOrdinal!,
          result.emittedDarts.length));
    }
    // Auto-advance-on-clear (opt-in): when all darts are removed (board-clear →
    // rebaselined) after at least one dart was on the board this turn, advance.
    // `dartsOnBoard` (not emittedDarts) so a cap-held 4th dart still counts.
    if (result.status.dartsOnBoard > 0) _sawDartsThisTurn = true;
    if (shouldAutoAdvance(
      phase: result.status.phase,
      sawDartsThisTurn: _sawDartsThisTurn,
      enabled: ref.read(autoAdvanceOnClearEnabledProvider).value ?? false,
    )) {
      sink?.advanceTurn();
    }
    widget.onStatus(result.status);
  }

  Future<void> _captureEmitted(
      DetectionFrame frame, int firstOrdinal, int count) async {
    try {
      // Full-resolution still without the baked-in overlay (see `_capture`).
      final bytes = await _controller.capturePhoto(withOverlays: false);
      if (!mounted || bytes == null) return;
      await widget.session.persistEmittedDarts(frame, bytes,
          turnOrdinal: widget.currentTurnOrdinal(),
          firstDartOrdinal: firstOrdinal,
          gameId: widget.gameId,
          count: count);
    } catch (_) {
      // A missed training capture must never disrupt scoring.
    }
  }

  Future<void> _manualCapture() async {
    final messenger = ScaffoldMessenger.of(context);
    // Full-resolution still without the baked-in overlay (see `_capture`).
    final bytes = await _controller.capturePhoto(withOverlays: false);
    if (!mounted) return;
    if (bytes == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Capture failed (no frame).')));
      return;
    }
    final saved = await widget.session.persistManualCapture(_latest, bytes,
        turnOrdinal: widget.currentTurnOrdinal(), gameId: widget.gameId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(saved
            ? 'Frame saved for training'
            : 'Enable data collection to save frames')));
  }

  @override
  Widget build(BuildContext context) {
    // Reset the auto-advance guard on every turn advance — manual NEXT and our
    // own auto-advance both bump activeTurnSignal — so each new turn requires a
    // fresh dart sighting before it can auto-advance again.
    ref.listen<int>(activeTurnSignalProvider, (_, __) => _sawDartsThisTurn = false);
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        YOLOView(
          modelPath: kAutoScorerModelAsset,
          task: YOLOTask.detect,
          controller: _controller,
          confidenceThreshold:
              _floor(widget.calConfidence, widget.dartConfidence),
          iouThreshold: 0.45,
          lensFacing: LensFacing.back,
          streamingConfig: const YOLOStreamingConfig(
              inferenceFrequency: 3,
              analysisResolution: kAutoScorerAnalysisResolution),
          onResult: _onResults,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black.withValues(alpha: 0.4),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Capture frame',
              icon: const Icon(Icons.add_a_photo_outlined,
                  color: Colors.white, size: 20),
              onPressed: _manualCapture,
            ),
          ),
        ),
      ],
    );
    // Camera-first fills the Expanded the board gives it; band mode is a fixed
    // ~140px strip under the header.
    return widget.expand ? stack : SizedBox(height: 140, child: stack);
  }
}
