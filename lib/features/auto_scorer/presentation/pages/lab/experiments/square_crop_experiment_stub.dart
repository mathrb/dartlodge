import 'package:flutter/material.dart';

/// Web no-op for the square-crop experiment — the camera/detector are
/// mobile-only (the conditional-import sibling is `square_crop_experiment_io.dart`).
class SquareCropExperimentPage extends StatelessWidget {
  const SquareCropExperimentPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Crop carré → predict')),
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
