import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/camera_zoom_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/detection_thresholds_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/setup_tips_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_setup_tips_view.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_yolo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scoreboard-primary assist-mode camera widget (#377 §5.2). Two layouts via
/// [expand]: the band variant (`expand: false`, via the core `boardOverlayBuilder`
/// seam) is a slim row under the header (Cricket); the camera-first variant
/// (`expand: true`, via `boardCameraPreviewBuilder`, #427) fills a flexible body
/// region with a large preview (X01). Detection runs on a live `YOLOView`
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

class _AutoScorerBoardOverlayState
    extends ConsumerState<AutoScorerBoardOverlay> {
  _Mode _mode = _Mode.idle;
  bool _starting = false;
  AutoScorerSession? _session;
  int _turnOrdinal = 1;
  String? _error;

  /// Tracker status for the chip. A [ValueNotifier] (not setState) so the live
  /// `onResult` stream (~3 Hz) updates only the chip — never rebuilding the
  /// `YOLOView` preview (which would churn / risk a native remount).
  final ValueNotifier<TrackerStatus> _status = ValueNotifier(
    const TrackerStatus(
        phase: TrackerPhase.noCalibration, dartsOnBoard: 0, dartsThisTurn: 0),
  );

  @override
  void dispose() {
    _status.dispose();
    _session?.dispose();
    super.dispose();
  }

  /// idle → (one-time tips) → aim (fullscreen YOLOView) → running (inline preview).
  Future<void> _start() async {
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
        _fail('Auto-scoring is not available on this device.');
        return;
      }
      final store = await ref.read(captureStoreProvider.future);
      if (!mounted) return;
      // No predict detector: YOLOView loads its own model. The session just
      // wires the tracker + capture; start() prunes captures to the cap.
      final session = AutoScorerSession(
          captureStore: store, modelVersion: kAutoScorerModelVersion);
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
        setState(() {
          _mode = _Mode.running;
          _starting = false;
        });
      } else {
        _stop();
      }
    } catch (e) {
      _fail('Camera setup failed: $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    _session?.dispose();
    _session = null;
    setState(() {
      _error = message;
      _starting = false;
      _mode = _Mode.idle;
    });
  }

  /// Stop detection and release the camera (back to idle). The inline preview
  /// unmounts on the mode switch → its YOLOView disposes the native camera.
  void _stop() {
    _session?.dispose();
    _session = null;
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
    // The board bumps this whenever the turn advances (its own next-turn button);
    // reset the tracker's per-turn cap in lock-step (#380). No setState: the
    // preview reads [_turnOrdinal] live for capture handles.
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
                if (mounted) _status.value = s;
              },
            ),
          )
        : null;
    final children = <Widget>[
      if (preview != null)
        // Camera-first: let the preview fill the flexible region; band mode:
        // fixed ~140px height (set inside AutoScorerYoloPreview).
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
      if (running)
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tap a dart to correct a misread',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ),
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
    // idle / aim: a single Start action (plus the last error, if any). While the
    // aim modal is up, show a spinner behind it rather than re-exposing "Start".
    final scheme = Theme.of(context).colorScheme;
    final busy = _starting || _mode == _Mode.aim;
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
            label: const Text('Start camera'),
          ),
      ],
    );
  }
}
