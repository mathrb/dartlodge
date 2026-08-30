import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// How the camera is doing at recognising one of the four board markers.
enum MarkerRecognition {
  /// The model reported nothing at all for this marker class.
  missing,

  /// The model sees this marker, but below the calibration threshold — so it
  /// does not count yet. Worth showing: it means "nearly", not "nothing", and
  /// a small reframe usually gets it over the line.
  weak,

  /// Detected at or above the calibration threshold — this marker counts.
  found,
}

/// Overall recognition grade, the halo's colour: nothing / getting there / good.
enum RecognitionGrade {
  /// The model sees nothing of the board — not even below the threshold.
  none,

  /// Something is recognised but it is not a settled four: markers seen only
  /// weakly, some markers counting, or all four counting while the framing is
  /// still moving.
  partial,

  /// All four markers count and the caller's steadiness signal agrees — see
  /// [recognitionStateOf]'s `isStable`, whose meaning each view chooses.
  ready,
}

/// The single derived recognition state behind both the halo (S1.1) and the
/// marker pips (S1.2) of the aim view. One pure function, two renderings, so
/// the border colour and the pips can never tell the player different stories.
typedef RecognitionState = ({
  /// Per-marker state in DeepDarts order (cal1=5/20 wire, cal2=3/17, cal3=8/11,
  /// cal4=13/6) — always four entries, index-aligned with the detector's cal
  /// classes.
  List<MarkerRecognition> markers,
  RecognitionGrade grade,

  /// How many markers are [MarkerRecognition.found]. Drives copy that still
  /// wants a number; the pips themselves show it without one.
  int foundCount,
});

/// Derive the recognition state from a detection frame's diagnostic cal fields.
///
/// [calBestPoints] and [calConfidences] are the per-class *diagnostic* fields of
/// `DetectionFrame` (index-aligned, null where the class wasn't detected): they
/// expose a marker the model sees even when the full set is incomplete, which
/// is exactly what the player needs while reframing. [calMinConfidence] is the
/// user's calibration threshold — the same value that decides whether the frame
/// counts as calibrated.
///
/// **Advisory only.** This drives colour and copy; it never gates the ready
/// state, the homography, or scoring — those read `DetectionFrame.calPoints` /
/// `hasCalibration` as before.
///
/// [isStable] is what separates a green grade from an amber one once all four
/// markers count, and its meaning is the caller's to choose:
///
/// - the **aim view** passes its `CalibrationStabilityGate` verdict, because
///   aiming is exactly the moment to ask the player to hold still;
/// - the **in-game preview** has no steadiness gate (the running tracker
///   re-derives the transform live, #687) and passes "the board is calibrated
///   this frame", so the halo turns green as soon as recognition succeeds.
///
/// Passing a constant false is also valid and simply caps the grade at
/// [RecognitionGrade.partial].
RecognitionState recognitionStateOf({
  required List<BoardPoint?> calBestPoints,
  required List<double?> calConfidences,
  required double calMinConfidence,
  required bool isStable,
}) {
  final markers = <MarkerRecognition>[];
  for (var i = 0; i < 4; i++) {
    final seen = i < calBestPoints.length ? calBestPoints[i] : null;
    final conf = i < calConfidences.length ? calConfidences[i] : null;
    if (seen == null) {
      markers.add(MarkerRecognition.missing);
    } else if (conf != null && conf >= calMinConfidence) {
      markers.add(MarkerRecognition.found);
    } else {
      markers.add(MarkerRecognition.weak);
    }
  }
  final found = markers.where((m) => m == MarkerRecognition.found).length;
  // Red is reserved for "the camera sees nothing of the board". Markers seen
  // below the threshold grade amber even though none of them counts yet: that
  // is the whole point of telling weak apart from missing, and it keeps the
  // halo agreeing with the pips, which are already showing amber outlines.
  final seenAny = markers.any((m) => m != MarkerRecognition.missing);
  final grade = !seenAny
      ? RecognitionGrade.none
      : found == 4 && isStable
          ? RecognitionGrade.ready
          : RecognitionGrade.partial;
  return (markers: markers, grade: grade, foundCount: found);
}
