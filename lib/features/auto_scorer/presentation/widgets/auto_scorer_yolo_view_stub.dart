import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Web no-op for the YOLOView auto-scorer views. The plugin is mobile-only (the
/// conditional-import sibling is `auto_scorer_yolo_view_io.dart`). The shell's
/// support gate ([kAutoScorerYoloSupported] == false) means these are never
/// actually pushed/rendered on web; they exist only so the shell compiles.

/// False on web: the shell shows "auto-scoring unavailable here" instead of
/// starting the camera.
const bool kAutoScorerYoloSupported = false;

class AutoScorerYoloAimView extends StatelessWidget {
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
  final String modelPath;
  final double calConfidence;
  final double dartConfidence;
  final double initialZoom;
  final bool showOverlays;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback? onModelLoadFailed;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: Text(AppLocalizations.of(context).autoScorerNotAvailable)),
      );
}

class AutoScorerYoloPreview extends StatelessWidget {
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
    this.expand = false,
  });

  final AutoScorerSession session;
  final String gameId;
  final String modelPath;
  final int Function() currentTurnOrdinal;
  final bool Function() everCalibrated;
  final double calConfidence;
  final double dartConfidence;
  final double initialZoom;
  final bool showOverlays;
  final ValueChanged<TrackerStatus> onStatus;
  final VoidCallback? onModelLoadFailed;
  final bool expand;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
