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
/// aim view's status banner (S1.2). One pure function, however many renderings,
/// so they can never tell the player different stories.
typedef RecognitionState = ({
  /// Per-marker state in DeepDarts order (cal1=5/20 wire, cal2=3/17, cal3=8/11,
  /// cal4=13/6) — always four entries, index-aligned with the detector's cal
  /// classes.
  List<MarkerRecognition> markers,
  RecognitionGrade grade,

  /// How many markers are [MarkerRecognition.found]. Drives copy that still
  /// wants a number; the board diagram shows it without one.
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
  // grade agreeing with the per-marker dots, which already show that nuance.
  final seenAny = markers.any((m) => m != MarkerRecognition.missing);
  final grade = !seenAny
      ? RecognitionGrade.none
      : found == 4 && isStable
          ? RecognitionGrade.ready
          : RecognitionGrade.partial;
  return (markers: markers, grade: grade, foundCount: found);
}

/// The grade the **in-game** halo should paint, or null for "say nothing".
///
/// A camera session that has never calibrated is a valid way to play, and the
/// status chip says so calmly (#741). Painting the "sees nothing" red around
/// the preview for a whole game is precisely the permanent alarm #741 was
/// created to remove: the two signals told the player opposite stories (#758).
/// So while nothing has been recognised yet, red is suppressed.
///
/// Amber and green are NOT suppressed: progress is not an alarm, it is the
/// first sign the board is about to be recognised — the one thing worth
/// showing a player whose setup is not supported yet.
///
/// Once the session HAS been calibrated, red means the board was lost, which
/// is a real problem and keeps alarming.
///
/// The aim view deliberately does not use this: there, "the camera sees
/// nothing" is the actionable state the player is there to fix, and a
/// sustained failure escalates to its own explanation panel (#743).
RecognitionGrade? haloGradeOf({
  required RecognitionGrade grade,
  required bool everCalibrated,
}) =>
    !everCalibrated && grade == RecognitionGrade.none ? null : grade;
