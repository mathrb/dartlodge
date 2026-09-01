import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_recognition_indicators.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/calibration_marker_diagram_widget.dart';
import 'package:flutter/material.dart';

/// Diameter of the live board diagram inside the banner. Big enough that four
/// dots on a rim are told apart at arm's length, small enough to sit on one
/// line of text.
const double kAimBannerDiagramSize = 44;

/// The single status object of the aim view (#759): what the camera sees, and
/// what to do about it, in one opaque block.
///
/// It replaces two things that each said half of it badly — a coloured border
/// around the whole screen that never explained what it stood for, and a line
/// of white text laid straight on the camera image, whose legibility depended
/// on whatever the player happened to have behind their board.
///
/// The colour carries the state, so the border does not have to. Opaque, so the
/// text does not depend on the picture underneath. And the four dots sit where
/// they sit on a real board, which is the part a row of identical pips could
/// never say.
class AimStatusBanner extends StatelessWidget {
  const AimStatusBanner({
    super.key,
    required this.recognition,
    required this.message,
    required this.diagramSemanticsLabel,
  });

  final RecognitionState recognition;

  /// What the player should do about the state — already localised.
  final String message;

  /// Spoken description of the board diagram.
  final String diagramSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Tinted, not saturated: blended over a surface so the block is fully
    // opaque and the text keeps a surface contrast pair, while the tint still
    // reads as red / amber / green at a glance. A flat fill of the grade colour
    // would fight the board drawing sitting on it.
    //
    // The 0.55 is measured, not guessed: rendered to an image and looked at
    // over a camera-coloured background, a third of the way felt like the same
    // brown as the room behind it and left the border doing all the work.
    final tint = Color.alphaBlend(
      recognitionColor(context, recognition.grade).withValues(alpha: 0.55),
      scheme.surfaceContainerHighest,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: recognitionColor(context, recognition.grade), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: kAimBannerDiagramSize,
            height: kAimBannerDiagramSize,
            child: CalibrationMarkerDiagram.live(
              semanticsLabel: diagramSemanticsLabel,
              markers: recognition.markers,
              foreground: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
