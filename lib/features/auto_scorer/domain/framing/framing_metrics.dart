import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// Pure framing metrics for the auto-scorer aim view (#393 setup flow). No
/// Flutter / drift / dio imports — operates on normalised [BoardPoint]s (0–1 in
/// the detection frame). The aim view uses these to advise the user to fill the
/// frame, the highest-leverage knob for detection accuracy: the more of the
/// frame the board occupies, the more pixels it keeps after the 800×800
/// letterbox → finer calibration / dart-tip localisation.

/// Minimum span (normalised) the cal diamond must cover on each axis to count as
/// a real, non-degenerate board — guards against a misdetection clustering the
/// four cals (e.g. cal3 ≈ cal4) passing the upright check. ~0.1 is well below a
/// normally-framed board's cal span while excluding clusters.
const double _kMinCalSpan = 0.1;

/// Whether the four detected calibration points form a proper UPRIGHT board, by
/// their class arrangement (#393 orientation auto-detect). [cals] is index-aligned
/// to cal classes `[cal1, cal2, cal3, cal4]` = the DeepDarts 5/20, 3/17, 8/11,
/// 13/6 wires, whose canonical positions are top / bottom / left / right.
///
/// True iff all four are present and cal1 is the topmost, cal2 the bottommost,
/// cal3 the leftmost, cal4 the rightmost, with a real span on each axis. This is
/// what distinguishes the true-upright rotation from an upside-down / sideways /
/// degenerate detection: the model emits four cal points at several rotations
/// (so "4 cals found" alone is NOT enough), but only the upright one arranges
/// them as the canonical diamond. y grows downward (image space).
bool isCalArrangementUpright(List<BoardPoint?> cals) {
  if (cals.length < 4) return false;
  final c1 = cals[0], c2 = cals[1], c3 = cals[2], c4 = cals[3];
  if (c1 == null || c2 == null || c3 == null || c4 == null) return false;
  final topmost = c1.y < c2.y && c1.y < c3.y && c1.y < c4.y;
  final bottommost = c2.y > c1.y && c2.y > c3.y && c2.y > c4.y;
  final leftmost = c3.x < c1.x && c3.x < c2.x && c3.x < c4.x;
  final rightmost = c4.x > c1.x && c4.x > c2.x && c4.x > c3.x;
  final spans = (c2.y - c1.y) > _kMinCalSpan && (c4.x - c3.x) > _kMinCalSpan;
  return topmost && bottommost && leftmost && rightmost && spans;
}

/// Heuristic "the board fills enough of the frame" threshold for [frameFillRatio]
/// — below this the aim view nudges the user to move closer / zoom in. Advisory
/// only (it gates copy, never the ready state); to be tuned on captured data
/// (#393). The four cals sit on the board's outer ring at roughly 90° apart, so
/// the quad through them is a square inscribed in that ring (area ≈ d²/2 of the
/// board's normalised diameter d) — ~0.25 corresponds to a board diameter of
/// ~0.7 of the frame.
const double kGoodFillRatio = 0.25;

/// Fraction of the frame (0–1) spanned by the polygon through the detected
/// calibration points. Because the cals lie on the board's outer ring, this
/// approximates how much of the frame the board fills — the "fill the frame"
/// signal. Rotation-invariant: the points are sorted by angle around their
/// centroid before the shoelace area, so any board orientation gives the same
/// ratio. Returns 0 when fewer than three cals are present (no area to measure),
/// so callers fall back to the "reframe so all markers show" hint.
///
/// Assumes the points are in raw-camera-frame-normalised space (skip-preprocess,
/// the default since #406), where the area is a faithful fraction of the camera
/// frame. In non-skip/letterbox mode the coords are 800×800-letterbox-normalised,
/// so for a non-square frame one axis is compressed and the ratio is only an
/// approximation — fine for the advisory copy it drives, never a hard gate.
double frameFillRatio(List<BoardPoint?> calBestPoints) {
  final pts = [
    for (final p in calBestPoints) ?p,
  ];
  if (pts.length < 3) return 0.0;

  final cx = pts.map((p) => p.x).reduce((a, b) => a + b) / pts.length;
  final cy = pts.map((p) => p.y).reduce((a, b) => a + b) / pts.length;
  pts.sort((a, b) => math
      .atan2(a.y - cy, a.x - cx)
      .compareTo(math.atan2(b.y - cy, b.x - cx)));

  var twiceArea = 0.0;
  for (var i = 0; i < pts.length; i++) {
    final j = (i + 1) % pts.length;
    twiceArea += pts[i].x * pts[j].y - pts[j].x * pts[i].y;
  }
  return (twiceArea.abs() / 2).clamp(0.0, 1.0);
}
