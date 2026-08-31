import 'dart:async';

import 'package:dart_lodge/core/game/capture_correction_sink.dart';
import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/detection_mapping.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/yolo_view_detections.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/calibration_stability.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/framing_metrics.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/auto_advance.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_recognition_indicators.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/auto_advance_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/aim_escalation.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/aim_outcome.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/session_recording_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/uncalibrated_notice_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/aim_explanation_panel.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
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

/// Native streaming inference rate (Hz) for BOTH the aim view and the in-game
/// preview. Calibration stability is measured over a handful of consecutive
/// frames and scoring polls at this rate, so a higher rate only adds heat /
/// battery drain. Shared so the two views can't drift apart (#470).
const int kAutoScorerInferenceHz = 3;

double _floor(double calConf, double dartConf) =>
    [_nativeFloor, calConf, dartConf].reduce((a, b) => a < b ? a : b);

/// How long to let autofocus/auto-exposure converge after a focus request before
/// grabbing a manual still (#468 follow-up). The plugin's `capturePhoto` does NOT
/// trigger AF — it freezes the current focus state — and there is no continuous
/// AF on the analysis stream, so a manual shot taken without re-focusing is often
/// blurry. `tapToFocus`'s Future only signals dispatch (not AF lock), and
/// `focusEvents` is AF-complete on Android but a mere tap-ack on iOS, so we wait a
/// fixed settle delay instead of racing the event. ~600 ms covers typical AF
/// convergence (300–800 ms); tunable on device (raise for reliability, lower for
/// latency).
const Duration kAutoScorerFocusSettle = Duration(milliseconds: 600);

/// Request autofocus + auto-exposure at the preview centre (where the board sits)
/// and wait for it to settle, so the subsequent [YOLOViewController.capturePhoto]
/// is sharp. Best-effort: a failed focus request still proceeds to capture.
Future<void> _focusCenterThenSettle(YOLOViewController controller) async {
  try {
    await controller.tapToFocus(0.5, 0.5);
  } catch (_) {
    // Best-effort — capture anyway at whatever focus the camera holds.
  }
  await Future<void>.delayed(kAutoScorerFocusSettle);
}

/// Map a YOLOView result stream into our [DetectionFrame] (cals + dart
/// candidates). The plugin-bound `YOLOResult → ClassedDetection` step lives here;
/// the pure mapping is the merged `rawDetectionsFromClassed` + `buildDetectionFrame`.
({DetectionFrame frame, List<RawDetection> raw}) _detectionFrameFrom(
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
  // Keep the raw (pre-filter) detections alongside the built frame: the session
  // records them for replay (#490), so a too-aggressive threshold stays
  // reproducible. buildDetectionFrame applies the thresholds.
  final raw = rawDetectionsFromClassed(classed);
  return (
    frame: buildDetectionFrame(raw,
        calMinConfidence: calConf, dartMinConfidence: dartConf),
    raw: raw,
  );
}

/// Fullscreen one-time aim/calibration view backed by `YOLOView` (native
/// streaming inference) instead of CameraController + takePicture. Feeds each
/// `onResult` to the [CalibrationStabilityGate], which drives the steadiness
/// hint. The confirm button is always clickable: with the four cals present it
/// reads "Done aiming"; otherwise it reads "Continue without auto-scoring" and
/// proceeds uncalibrated (manual scoring) after a one-time note. Zoom drives the
/// native `setZoomLevel`; the native overlays that draw the detection boxes (no
/// Dart-side coord mapping) are off unless [showOverlays] is on (#738) — and the
/// "Capture photo" button first re-focuses (see `_focusCenterThenSettle`) then
/// grabs a clean full-resolution still via `capturePhoto(withOverlays: false)`,
/// not the annotated preview snapshot.
/// Pops an [AimOutcome]: `calibrated` on Done, `uncalibrated` when the player
/// proceeds without the markers, `cancelled` on Cancel/back (also what a system
/// back gesture yields, since the route then pops null). The caller starts the
/// game in learning mode on `uncalibrated` (#741). Consumer-backed only to read
/// the data-collection opt-in before persisting a capture (otherwise state + a
/// session handle).
class AutoScorerYoloAimView extends ConsumerStatefulWidget {
  const AutoScorerYoloAimView({
    super.key,
    required this.session,
    required this.gameId,
    required this.modelPath,
    required this.calConfidence,
    required this.dartConfidence,
    required this.initialZoom,
    required this.showOverlays,
    required this.onZoomChanged,
    this.onModelLoadFailed,
  });

  final AutoScorerSession session;
  final String gameId;

  /// The resolved model to load — the bundled asset or a staged OTA file (#715).
  /// Snapshotted at session start and passed in so the model never hot-swaps.
  final String modelPath;
  final double calConfidence;
  final double dartConfidence;
  final double initialZoom;

  /// Paint the plugin's raw detection boxes on the preview. Off by default —
  /// see [AutoScorerTechnicalDisplay].
  final bool showOverlays;
  final ValueChanged<double> onZoomChanged;

  /// Fired when a *staged* OTA model fails to load natively (#715). The view has
  /// already reset itself to the bundled asset; the host persists the quarantine.
  final VoidCallback? onModelLoadFailed;

  @override
  ConsumerState<AutoScorerYoloAimView> createState() =>
      _AutoScorerYoloAimViewState();
}

class _AutoScorerYoloAimViewState extends ConsumerState<AutoScorerYoloAimView> {
  final YOLOViewController _controller = YOLOViewController();
  final CalibrationStabilityGate _gate = CalibrationStabilityGate();

  bool _nativePushed = false;
  bool _capturing = false;
  DetectionFrame? _latest;

  /// When the current run of frames-without-the-four-markers started (#743).
  /// Reset on every successful recognition, so the explanation only appears
  /// after a sustained failure — never after a marker blinks out.
  ///
  /// Null until the first frame arrives: the clock has to measure time with a
  /// camera actually running, or a slow permission prompt (the player reading
  /// the system dialog, or going to Settings and back) would spend the whole
  /// patience budget before detection ever got a chance.
  DateTime? _unrecognisedSince;

  /// The player took the panel's "Keep aiming". Held until recognition returns,
  /// so the panel cannot come back every [kAimExplainAfter] seconds.
  bool _keepAiming = false;

  /// Re-evaluates the escalation on the clock rather than only on frames: the
  /// case worth explaining includes a detector that has stopped reporting
  /// altogether, which produces no rebuilds of its own.
  Timer? _explainTicker;
  CalibrationStability _stability = (stableFrames: 0, isReady: false);
  late double _zoom = widget.initialZoom.clamp(_zoomMin, _zoomMax);

  /// Model path currently fed to `YOLOView`. Seeded from the resolved prop; a
  /// native load failure of a staged model resets it to the bundled asset (#715).
  late String _effectivePath = widget.modelPath;

  @override
  void initState() {
    super.initState();
    _explainTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _explainTicker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _ensureNative() {
    if (_nativePushed) return;
    _nativePushed = true;
    _controller.setShowOverlays(widget.showOverlays);
    if (_zoom != 1.0) _controller.setZoomLevel(_zoom);
  }

  /// A staged OTA model failed to load natively (#715): immediately reload the
  /// bundled asset so scoring can't be bricked by a bad-but-hash-valid model,
  /// and notify the host to persist the quarantine. Ignores failures once we're
  /// already on the bundled asset (nothing left to fall back to).
  void _onModelError(Object error, String failedPath, YOLOTask? task) {
    if (_effectivePath == kAutoScorerModelAsset) return;
    if (!mounted) return;
    setState(() => _effectivePath = kAutoScorerModelAsset);
    widget.onModelLoadFailed?.call();
  }

  void _onResults(List<YOLOResult> results) {
    _ensureNative();
    final frame = _detectionFrameFrom(
            results, widget.calConfidence, widget.dartConfidence)
        .frame;
    final stability = _gate.update(frame);
    if (!mounted) return;
    setState(() {
      _latest = frame;
      _stability = stability;
      // First frame: the camera is live, so start the patience clock.
      _unrecognisedSince ??= DateTime.now();
      if (frame.hasCalibration) {
        // Recognition is back: restart the patience clock and re-arm the
        // panel, so a setup that works and then stops working can explain
        // itself again.
        _unrecognisedSince = DateTime.now();
        _keepAiming = false;
      }
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
    if (_capturing) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // Respect the data-collection opt-in: the store is non-null even when the
    // toggle is off, so without this gate a manual capture would write a frame
    // the user opted out of (mirrors `_captureEmitted`/`correctDart`).
    if (!(ref.read(dataCollectionEnabledProvider).value ?? false)) {
      messenger.showSnackBar(SnackBar(
          content: Text(l10n.autoScorerCaptureNeedsCollection)));
      return;
    }
    setState(() => _capturing = true);
    try {
      // Focus first: capturePhoto doesn't trigger AF, so a manual shot is often
      // blurry without re-focusing the board centre (see kAutoScorerFocusSettle).
      await _focusCenterThenSettle(_controller);
      if (!mounted) return;
      // `capturePhoto(withOverlays: false)`, NOT `captureFrame()`: the latter
      // snapshots the on-screen preview (widget-sized, zoom-cropped) and bakes the
      // detection overlay in. We want a clean full-resolution still for training.
      final bytes = await _controller.capturePhoto(withOverlays: false);
      if (!mounted) return;
      if (bytes == null) {
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.autoScorerCaptureFailed)));
        return;
      }
      await widget.session.persistManualCapture(_latest ?? _emptyFrame, bytes,
          turnOrdinal: 0, gameId: widget.gameId);
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.autoScorerCaptureSaved)));
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _finish(AimOutcome outcome) async {
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
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(outcome);
  }

  /// Proceed past aiming WITHOUT a full calibration (markers not detected).
  /// Auto-scoring can't run, so the player scores by hand and each manual entry
  /// captures a labelled frame (the point of this path). Shows a one-time note
  /// explaining that, then finishes; once acknowledged it never interrupts again.
  Future<void> _confirmContinueWithoutCals() async {
    final seen =
        ref.read(autoScorerUncalibratedNoticeSeenProvider).value ?? false;
    if (seen) {
      await _finish(AimOutcome.uncalibrated);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.autoScorerUncalibratedNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.autoScorerContinueWithoutAutoScoring),
          ),
        ],
      ),
    );
    if (!mounted || proceed != true) return;
    await ref
        .read(autoScorerUncalibratedNoticeSeenProvider.notifier)
        .setSeen(true);
    if (!mounted) return;
    await _finish(AimOutcome.uncalibrated);
  }

  /// The panel's primary action (#743): proceed and score by hand. The panel
  /// has just said everything the one-time uncalibrated notice says, so mark it
  /// seen rather than showing it on top of the explanation the player has just
  /// read — and finish on the same `uncalibrated` outcome as the button, so the
  /// existing path is unchanged.
  Future<void> _playAnyway() async {
    await ref
        .read(autoScorerUncalibratedNoticeSeenProvider.notifier)
        .setSeen(true);
    if (!mounted) return;
    await _finish(AimOutcome.uncalibrated);
  }

  /// Turn recording on from the panel. Mirrors the settings page's single
  /// "Record" switch (#686), which drives the training photos and the session
  /// trace together — so enabling it here means the same thing it means there.
  void _enableRecording() {
    ref.read(dataCollectionEnabledProvider.notifier).setEnabled(true);
    ref.read(sessionRecordingEnabledProvider.notifier).setEnabled(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calibrated = _latest?.hasCalibration ?? false;
    final fill = _latest == null ? 0.0 : frameFillRatio(_latest!.calBestPoints);
    final ready = _stability.isReady;
    // One derived state, two renderings (#739): the halo around the preview and
    // the four pips beside the hint. Advisory — it drives colour and copy only;
    // `calibrated`/`ready` above still gate the button.
    final recognition = recognitionStateOf(
      calBestPoints: _latest?.calBestPoints ?? const [null, null, null, null],
      calConfidences: _latest?.calConfidences ?? const [null, null, null, null],
      calMinConfidence: widget.calConfidence,
      isStable: ready,
    );
    // After a sustained failure to recognise the board, the one-line nudge
    // gives way to an explanation (#743). Time-based and presentational: the
    // confirm button below keeps working exactly as before, panel or not.
    final since = _unrecognisedSince;
    final explain = shouldExplainAim(
      withoutRecognition:
          since == null ? Duration.zero : DateTime.now().difference(since),
      recognisedNow: calibrated,
      keepAimingChosen: _keepAiming,
    );
    final hint = _latest == null
        ? l10n.autoScorerAimHint
        : !calibrated
            ? l10n.autoScorerMarkersReframe
            // Calibrated: the button already reads "Done aiming" and is enabled,
            // so the steadiness nudge must NOT imply it's blocked (hint↔button
            // agreement, #411). Advisory "tap when steady" while not-yet-stable.
            : !ready
                ? l10n.autoScorerCalibratedSteadyHint
                : fill < kGoodFillRatio
                    ? l10n.autoScorerReadyZoomHint
                    : l10n.autoScorerReadyDone;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          YOLOView(
            modelPath: _effectivePath,
            task: YOLOTask.detect,
            controller: _controller,
            confidenceThreshold:
                _floor(widget.calConfidence, widget.dartConfidence),
            iouThreshold: 0.45,
            lensFacing: LensFacing.back,
            streamingConfig: const YOLOStreamingConfig(
                inferenceFrequency: kAutoScorerInferenceHz,
                analysisResolution: kAutoScorerAnalysisResolution),
            onResult: _onResults,
            onModelError: _onModelError,
          ),
          // Painted around the preview, never at a detection coordinate — see
          // the note on [RecognitionHalo].
          Positioned.fill(
              child: RecognitionHaloOverlay(grade: recognition.grade)),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The pips replace the old "{found}/4 markers" count: which
                    // marker is missing is what the count never carried.
                    MarkerPips(markers: recognition.markers),
                    const SizedBox(height: 8),
                    if (explain)
                      AimExplanationPanel(
                        // The photo opt-in specifically, NOT the settings
                        // page's `collect || sessions` OR (#686): the panel
                        // talks about the photos that go with a hand-entered
                        // score, and only this opt-in decides whether any are
                        // kept. Turning it on from here still flips both, like
                        // that single switch does.
                        recordingOn:
                            ref.watch(dataCollectionEnabledProvider).value ??
                                false,
                        onPlayAnyway: _playAnyway,
                        onKeepAiming: () =>
                            setState(() => _keepAiming = true),
                        onEnableRecording: _enableRecording,
                      )
                    else
                      Text(hint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white)),
                  ],
                ),
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
                      onPressed: _capturing ? null : _capture,
                      icon: _capturing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_a_photo_outlined),
                      label: Text(_capturing
                          ? l10n.autoScorerCaptureFocusing
                          : l10n.autoScorerCapturePhoto),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton.tonal(
                            onPressed: () => _finish(AimOutcome.cancelled),
                            child: Text(l10n.commonCancel)),
                        // Always clickable so an unsupported setup (markers
                        // never resolve) can still proceed and contribute
                        // frames. Calibrated → normal "Done aiming"; otherwise
                        // proceed uncalibrated (manual scoring) after a one-time
                        // note. Discriminate on `calibrated` (4 cals present),
                        // not `ready` (stable 3 frames): the running preview
                        // re-derives the transform live (#687), so the stability
                        // wait is only the advisory "Hold steady…" hint now.
                        FilledButton.icon(
                          onPressed: calibrated
                              ? () => _finish(AimOutcome.calibrated)
                              : _confirmContinueWithoutCals,
                          icon: Icon(calibrated
                              ? Icons.check
                              : Icons.videocam_off_outlined),
                          label: Text(calibrated
                              ? l10n.autoScorerDoneAiming
                              : l10n.autoScorerContinueWithoutAutoScoring),
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
/// is on. The native overlays are off unless [showOverlays] is on (#738); even
/// then they are drawn on screen only and are NOT in the capture.
///
/// It carries no controls: during play every capture worth having is taken on
/// its own (on emission, on a correction, on a hand-entered score), and the
/// manual button that used to sit here was inert in the collapsed vignette
/// anyway — an unlabelled frame is worth less than the labelled ones the game
/// already produces (#745). Framing shots stay in the aim view, where taking
/// one is the point.
class AutoScorerYoloPreview extends ConsumerStatefulWidget {
  const AutoScorerYoloPreview({
    super.key,
    required this.session,
    required this.gameId,
    required this.modelPath,
    required this.currentTurnOrdinal,
    required this.everCalibrated,
    required this.calConfidence,
    required this.dartConfidence,
    required this.initialZoom,
    required this.showOverlays,
    required this.onStatus,
    this.onModelLoadFailed,
  });

  final AutoScorerSession session;
  final String gameId;

  /// The resolved model to load — bundled asset or staged OTA file (#715).
  final String modelPath;
  final int Function() currentTurnOrdinal;

  /// Whether this camera session has ever been calibrated — read live, like
  /// [currentTurnOrdinal], because the host keeps it in a plain field.
  ///
  /// It cannot be latched here: the aim step seeds it BEFORE this preview
  /// exists, so a preview that only watched its own frames would treat a board
  /// lost right after a successful aim as if it had never been recognised.
  final bool Function() everCalibrated;
  final double calConfidence;
  final double dartConfidence;
  final double initialZoom;

  /// Paint the plugin's raw detection boxes on the preview. Off by default —
  /// see [AutoScorerTechnicalDisplay].
  final bool showOverlays;
  final ValueChanged<TrackerStatus> onStatus;

  /// Fired when a *staged* OTA model fails to load natively (#715). The view has
  /// already reset itself to the bundled asset; the host persists the quarantine.
  final VoidCallback? onModelLoadFailed;


  @override
  ConsumerState<AutoScorerYoloPreview> createState() =>
      _AutoScorerYoloPreviewState();
}

class _AutoScorerYoloPreviewState extends ConsumerState<AutoScorerYoloPreview>
    implements CaptureCorrectionSink {
  final YOLOViewController _controller = YOLOViewController();
  bool _nativePushed = false;
  DetectionFrame _latest = _emptyFrame;

  /// Recognition grade for the halo (#739), held as a notifier rather than
  /// widget state: `_onResults` fires at the inference rate, and calling
  /// `setState` that often would rebuild `YOLOView` along with everything else.
  /// Only the border listens.
  ///
  /// There is no steadiness gate here — that belongs to aiming, and the running
  /// tracker re-derives the transform live (#687) — so `isStable` is fed the
  /// frame's own calibration: green means "the board is recognised right now".
  ///
  /// Seeded null — "say nothing" — not [RecognitionGrade.none]: until the first
  /// frame comes back (model load plus one inference, which is not instant)
  /// nothing is known about the board, and `none` would paint the alarm red in
  /// the meantime. That flash lands on every fresh mount: camera restart, model
  /// error recovery, and the re-aim that has just reset the session's
  /// calibration memory — the exact moment #758 must stay calm.
  final ValueNotifier<RecognitionGrade?> _grade = ValueNotifier(null);

  /// Model path currently fed to `YOLOView`. Seeded from the resolved prop; a
  /// native load failure of a staged model resets it to the bundled asset (#715).
  late String _effectivePath = widget.modelPath;

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

  /// The overlay `watch`es the technical-display preference, so a toggle can
  /// reach a live preview. `_ensureNative` only ever pushes once, so re-push the
  /// flag here instead of waiting for the next session.
  @override
  void didUpdateWidget(AutoScorerYoloPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_nativePushed && oldWidget.showOverlays != widget.showOverlays) {
      _controller.setShowOverlays(widget.showOverlays);
    }
  }

  @override
  void dispose() {
    _grade.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Propagate a user dart-correction (#456/#457). In "all" mode the capture was
  /// already saved at emission, so rewrite its sidecar. In "partial" mode nothing
  /// was saved, so capture the current frame now and store a new corrected
  /// capture (capture-at-correction). Fire-and-forget — a missed capture must
  /// never disrupt scoring.
  @override
  void correctDart({required int cameraDartOrdinal, required String segment}) {
    if (!mounted) return;
    // Respect the data-collection opt-in: with it off we never touch the capture
    // store — in partial mode this would otherwise silently write a frame the
    // user opted out of (the store is non-null even when collection is off).
    if (!(ref.read(dataCollectionEnabledProvider).value ?? false)) return;
    final mode =
        ref.read(captureModeSettingProvider).value ?? CaptureMode.partial;
    if (mode == CaptureMode.all) {
      unawaited(widget.session.applyDartCorrection(
        gameId: widget.gameId,
        turnOrdinal: widget.currentTurnOrdinal(),
        // The capture handle's dartInTurnOrdinal is the camera-emitted ordinal
        // (#469), which is exactly what the game now supplies.
        dartInTurnOrdinal: cameraDartOrdinal,
        segment: segment,
      ));
    } else {
      unawaited(_captureCorrected(segment));
    }
  }

  Future<void> _captureCorrected(String segment) async {
    try {
      // Full-resolution still without the baked-in overlay (see `_capture`).
      final bytes = await _controller.capturePhoto(withOverlays: false);
      if (!mounted || bytes == null) return;
      // Keyed by a per-session correction sequence inside persistCorrectedCapture
      // (collision-free), so dartInTurnOrdinal isn't needed here.
      await widget.session.persistCorrectedCapture(
        frame: _latest,
        bytes: bytes,
        turnOrdinal: widget.currentTurnOrdinal(),
        gameId: widget.gameId,
        segment: segment,
      );
    } catch (_) {
      // A missed training capture must never disrupt scoring.
    }
  }

  /// The user manually entered [segment] for a dart the model missed (#537):
  /// capture the current frame as a labelled mistake. Unlike [correctDart] this
  /// does NOT branch on the capture mode — a manual entry is always a detection
  /// error, so it is captured in both "all" and "mistakes only" modes. Gated on
  /// the data-collection opt-in; fire-and-forget so a missed capture can never
  /// disrupt scoring.
  @override
  void captureManualEntry({required String segment}) {
    if (!mounted) return;
    if (!(ref.read(dataCollectionEnabledProvider).value ?? false)) return;
    unawaited(_captureManualEntry(segment));
  }

  Future<void> _captureManualEntry(String segment) async {
    try {
      // Full-resolution still without the baked-in overlay (see `_capture`).
      final bytes = await _controller.capturePhoto(withOverlays: false);
      if (!mounted || bytes == null) return;
      await widget.session.persistManualEntry(
        _latest,
        bytes,
        turnOrdinal: widget.currentTurnOrdinal(),
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
    _controller.setShowOverlays(widget.showOverlays);
    final z = widget.initialZoom.clamp(_zoomMin, _zoomMax);
    if (z != 1.0) _controller.setZoomLevel(z);
  }

  /// A staged OTA model failed to load natively (#715): fall back to the bundled
  /// asset immediately and notify the host to persist the quarantine. No-op once
  /// already on the bundled asset.
  void _onModelError(Object error, String failedPath, YOLOTask? task) {
    if (_effectivePath == kAutoScorerModelAsset) return;
    if (!mounted) return;
    setState(() => _effectivePath = kAutoScorerModelAsset);
    widget.onModelLoadFailed?.call();
  }

  void _onResults(List<YOLOResult> results) {
    _ensureNative();
    final (:frame, :raw) = _detectionFrameFrom(
        results, widget.calConfidence, widget.dartConfidence);
    _latest = frame;
    final result = widget.session.processDetectionFrame(
      frame,
      rawDetections: raw,
      calConfidence: widget.calConfidence,
      dartConfidence: widget.dartConfidence,
    );
    final sink = ref.read(activeDartInputSinkProvider);
    for (final d in result.emittedDarts) {
      sink?.submitDart(d.segment, x: d.x, y: d.y);
    }
    // Auto-capture on emission only in "all" mode; in "partial" mode captures
    // happen only at correction time (#457, see [correctDart]).
    if (result.emittedDarts.isNotEmpty &&
        (ref.read(dataCollectionEnabledProvider).value ?? false) &&
        (ref.read(captureModeSettingProvider).value ?? CaptureMode.partial) ==
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
    // The halo is graded LAST, after the status has been published: the host
    // latches its calibration memory from that status, and the suppression
    // rule reads that same memory. Grading earlier would read it one frame
    // stale — harmless on the ordinary path, but not on the held-homography
    // continuation (#485), where a frame with no cal marker in sight can still
    // report `tracking` and so prove the session calibrated. There, an early
    // read would suppress a red that had just become legitimate.
    //
    // Guard: an in-flight onResult can fire while this state is being
    // disposed, and `_grade` is disposed there — same hazard the shell's
    // `onStatus` guard covers for its own notifier (#419).
    if (mounted) {
      // A never-calibrated session must not be painted as an alarm (#758) —
      // the chip calls that state learning mode and stays calm about it.
      _grade.value = haloGradeOf(
        grade: recognitionStateOf(
          calBestPoints: frame.calBestPoints,
          calConfidences: frame.calConfidences,
          calMinConfidence: widget.calConfidence,
          isStable: frame.hasCalibration,
        ).grade,
        everCalibrated: widget.everCalibrated(),
      );
    }
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
          modelPath: _effectivePath,
          task: YOLOTask.detect,
          controller: _controller,
          confidenceThreshold:
              _floor(widget.calConfidence, widget.dartConfidence),
          iouThreshold: 0.45,
          lensFacing: LensFacing.back,
          streamingConfig: const YOLOStreamingConfig(
              inferenceFrequency: kAutoScorerInferenceHz,
              analysisResolution: kAutoScorerAnalysisResolution),
          onResult: _onResults,
          onModelError: _onModelError,
        ),
      ],
    );
    // The halo (#739) is the only recognition signal left in-game once the
    // native boxes are off by default (#738), and it is what reads from the
    // oche when the preview is collapsed to a vignette (#480). Listening
    // narrowly keeps the inference-rate updates off `YOLOView`.
    final haloed = ValueListenableBuilder<RecognitionGrade?>(
      valueListenable: _grade,
      builder: (_, grade, child) =>
          RecognitionHalo(grade: grade, child: child!),
      child: stack,
    );
    // Fills whatever the board's Expanded gives it (#760).
    return haloed;
  }
}
