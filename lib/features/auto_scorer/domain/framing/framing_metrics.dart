import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// Pure framing metrics for the auto-scorer aim view (#393 setup flow). No
/// Flutter / drift / dio imports — operates on normalised [BoardPoint]s (0–1 in
/// the detection frame). The aim view uses these to advise the user to fill the
/// frame, the highest-leverage knob for detection accuracy: the more of the
/// frame the board occupies, the more pixels it keeps after the 800×800
/// letterbox → finer calibration / dart-tip localisation.

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
double frameFillRatio(List<BoardPoint?> calBestPoints) {
  final pts = [
    for (final p in calBestPoints)
      if (p != null) p,
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
