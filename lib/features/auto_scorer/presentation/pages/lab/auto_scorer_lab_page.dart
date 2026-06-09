import 'package:dart_lodge/features/auto_scorer/presentation/pages/lab/experiments/square_crop_experiment.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/pages/lab/experiments/yolo_zoom_experiment.dart';
import 'package:flutter/material.dart';

/// Camera experiments "Lab" (#auto-scorer input exploration). A list of
/// self-contained options to A/B different ways of feeding the detector on a
/// real device — each shows the camera (or images) + its tunable params + a
/// detection readout in **data** (not a painted overlay). Reached from the
/// auto-scoring settings; isolated from the real scoring flow (the headless
/// `_tick` + `predict` path is untouched).
///
/// Add a future option by appending one [_LabExperiment] entry + its screen.
/// Catalogue still to add: native 1:1 camera, Dart square-crop (lag baseline),
/// zoom + display-square, native-preprocess fork.
class AutoScorerLabPage extends StatelessWidget {
  const AutoScorerLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    const experiments = <_LabExperiment>[
      _LabExperiment(
        id: 'yolo-zoom',
        title: 'YOLOView + zoom',
        subtitle: 'Inférence native sur le flux ; troncature par zoom (sans '
            'distorsion). Caméra + détections cals/fléchettes en données.',
        build: _buildYoloZoom,
      ),
      _LabExperiment(
        id: 'square-crop',
        title: 'Crop carré → predict',
        subtitle: 'Le modèle reçoit un crop carré centré (sonde qualité : le '
            'carré aide-t-il ?). Lag du crop Dart assumé, chiffré dans le HUD.',
        build: _buildSquareCrop,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Labo caméra')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
                'Bancs d\'essai pour comparer des approches de détection sur '
                'device. Sans impact sur le scoring.'),
          ),
          for (final e in experiments)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(e.title),
                subtitle: Text(e.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: e.build)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Top-level so it can sit in a `const` experiment descriptor (a tear-off of an
/// instance method can't be const).
Widget _buildYoloZoom(BuildContext _) => const YoloZoomExperimentPage();

Widget _buildSquareCrop(BuildContext _) => const SquareCropExperimentPage();

class _LabExperiment {
  const _LabExperiment({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.build,
  });

  final String id;
  final String title;
  final String subtitle;
  final WidgetBuilder build;
}
