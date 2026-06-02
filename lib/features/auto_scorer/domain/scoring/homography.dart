import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// Pure-Dart 4-point perspective transform — the `cv2.getPerspectiveTransform`
/// equivalent used by the probe's `dartboard.py`, ported with **no OpenCV**
/// (#377 §4, #379).
///
/// Given four source→destination correspondences it solves the 8-unknown
/// linear system (the homography has 8 degrees of freedom; `h33` is fixed to
/// 1) directly via Gauss–Jordan elimination with partial pivoting. Pure Dart,
/// no platform CV — safe for the `domain/` layer.
class Homography {
  /// Row-major 3×3 matrix `[h11,h12,h13, h21,h22,h23, h31,h32,h33]`.
  final List<double> m;

  const Homography(this.m);

  /// Solve for the homography mapping each `src[i]` onto `dst[i]`.
  ///
  /// Requires exactly four correspondences. Throws [ArgumentError] when the
  /// calibration points are degenerate (collinear / coincident → singular
  /// system).
  factory Homography.fromCorrespondences(
      List<BoardPoint> src, List<BoardPoint> dst) {
    if (src.length != 4 || dst.length != 4) {
      throw ArgumentError('getPerspectiveTransform needs exactly 4 points.');
    }
    // Each correspondence (x,y)→(u,v) with h33=1 contributes two rows:
    //   h11·x + h12·y + h13            − h31·x·u − h32·y·u = u
    //               h21·x + h22·y + h23 − h31·x·v − h32·y·v = v
    // Unknowns: [h11,h12,h13,h21,h22,h23,h31,h32].
    final a = List.generate(8, (_) => List<double>.filled(8, 0));
    final b = List<double>.filled(8, 0);
    for (var i = 0; i < 4; i++) {
      final x = src[i].x, y = src[i].y;
      final u = dst[i].x, v = dst[i].y;
      final r0 = i * 2;
      a[r0] = [x, y, 1, 0, 0, 0, -x * u, -y * u];
      b[r0] = u;
      final r1 = i * 2 + 1;
      a[r1] = [0, 0, 0, x, y, 1, -x * v, -y * v];
      b[r1] = v;
    }
    final h = _solveLinearSystem(a, b);
    return Homography([h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7], 1.0]);
  }

  /// Apply the transform to a single point.
  BoardPoint apply(BoardPoint p) {
    final w = m[6] * p.x + m[7] * p.y + m[8];
    final u = (m[0] * p.x + m[1] * p.y + m[2]) / w;
    final v = (m[3] * p.x + m[4] * p.y + m[5]) / w;
    return (x: u, y: v);
  }
}

/// Warp [all] into a face-on canonical frame aligned with the cardinal axes,
/// using the four calibration points [cals] (DeepDarts order: cal1=5/20 wire,
/// cal2=3/17, cal3=8/11, cal4=13/6).
///
/// Mirrors `dartboard.transform_to_canonical`: the cal centroid `c` and mean
/// radius `r` define a target square (cal1→top, cal2→bottom, cal3→left,
/// cal4→right); the homography that maps the (possibly skewed) cal quad onto
/// that square is applied to every point in [all].
List<BoardPoint> transformToCanonical(
    List<BoardPoint> cals, List<BoardPoint> all) {
  if (cals.length != 4) {
    throw ArgumentError('transformToCanonical needs exactly 4 cal points.');
  }
  final cx = cals.map((p) => p.x).reduce((a, b) => a + b) / 4;
  final cy = cals.map((p) => p.y).reduce((a, b) => a + b) / 4;
  final r = cals
          .map((p) => math.sqrt(_sq(p.x - cx) + _sq(p.y - cy)))
          .reduce((a, b) => a + b) /
      4;
  final dst = <BoardPoint>[
    (x: cx, y: cy - r), // cal1 → top
    (x: cx, y: cy + r), // cal2 → bottom
    (x: cx - r, y: cy), // cal3 → left
    (x: cx + r, y: cy), // cal4 → right
  ];
  final h = Homography.fromCorrespondences(cals, dst);
  return all.map(h.apply).toList();
}

double _sq(double v) => v * v;

/// Solve `A·x = b` for a dense `n×n` system via Gauss–Jordan elimination with
/// partial pivoting. Operates on copies so the inputs are left untouched.
List<double> _solveLinearSystem(List<List<double>> aIn, List<double> bIn) {
  final n = bIn.length;
  final a = [for (final row in aIn) [...row]];
  final b = [...bIn];
  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var r = col + 1; r < n; r++) {
      if (a[r][col].abs() > a[pivot][col].abs()) pivot = r;
    }
    if (a[pivot][col].abs() < 1e-12) {
      throw ArgumentError('Degenerate calibration points: singular matrix.');
    }
    if (pivot != col) {
      final tmpRow = a[pivot];
      a[pivot] = a[col];
      a[col] = tmpRow;
      final tmpB = b[pivot];
      b[pivot] = b[col];
      b[col] = tmpB;
    }
    final pivVal = a[col][col];
    for (var r = 0; r < n; r++) {
      if (r == col) continue;
      final factor = a[r][col] / pivVal;
      if (factor == 0) continue;
      for (var c = col; c < n; c++) {
        a[r][c] -= factor * a[col][c];
      }
      b[r] -= factor * b[col];
    }
  }
  return [for (var i = 0; i < n; i++) b[i] / a[i][i]];
}
