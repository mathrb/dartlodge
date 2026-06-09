import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/controllers/auto_scorer_session.dart';
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
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Camera not available on this platform.')),
      );
}

class AutoScorerYoloPreview extends StatelessWidget {
  const AutoScorerYoloPreview({
    super.key,
    required this.session,
    required this.gameId,
    required this.currentTurnOrdinal,
    required this.calConfidence,
    required this.dartConfidence,
    required this.initialZoom,
    required this.onStatus,
  });

  final AutoScorerSession session;
  final String gameId;
  final int Function() currentTurnOrdinal;
  final double calConfidence;
  final double dartConfidence;
  final double initialZoom;
  final ValueChanged<TrackerStatus> onStatus;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
