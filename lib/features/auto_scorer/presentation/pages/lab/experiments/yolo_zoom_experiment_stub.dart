import 'package:flutter/material.dart';

/// Web no-op for the YOLOView zoom experiment — the camera/YOLO plugin is
/// mobile-only (the conditional-import sibling is `yolo_zoom_experiment_io.dart`).
class YoloZoomExperimentPage extends StatelessWidget {
  const YoloZoomExperimentPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('YOLOView + zoom')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Les expériences caméra ne sont disponibles que sur un build device.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}
