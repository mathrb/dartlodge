import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

// Pure (canvas-free) KDE density computation and cold→hot colormap for the
// dartboard heatmap.
//
// All functions here are deliberately free of any `dart:ui` / `Canvas`
// dependency so they can be unit-tested off-screen. The widget
// (`HeatmapDartboardWidget`) feeds the resulting RGBA buffer into a
// `ui.Image` for painting.

/// A normalised dart position in the canonical board frame.
///
/// `(0,0)` = bull centre, radius `1.0` = outer edge of the double ring. A miss
/// outside the double ring has `r > 1.0`.
///
/// Orientation is the auto-scorer's scoring frame, which anchors the **5/20
/// calibration wire at the top** (`cal1 → top`); segment 20's centre therefore
/// sits ~9° clockwise of vertical, not on it. `HeatmapDartboardWidget` rotates
/// the whole rendering by `kHeatmapDisplayRotation` so the user still sees a
/// standard "20 at the top" board (#697) — the stored positions are unchanged.
typedef HeatPoint = ({double x, double y});

/// The square domain the density grid covers, in canonical units.
///
/// Slightly larger than the board (`1.0`) so misses just outside the double
/// ring still contribute. Points with `r > [kHeatNoiseRadius]` are discarded
/// as noise before binning.
const double kHeatGridExtent = 1.1;

/// Points further than this from centre are treated as detector noise and
/// dropped (see design doc "Cas limites").
const double kHeatNoiseRadius = 1.5;

/// Default density grid resolution (cells per axis).
const int kHeatGridResolution = 64;

/// Result of [computeHeatGrid]: a normalised (`0..1`) density grid plus its
/// resolution. Row-major, `values[row * resolution + col]`.
///
/// `col` maps to x across `[-extent, +extent]`, `row` maps to y across
/// `[-extent, +extent]` (row 0 = top = `y = -extent`).
@immutable
class HeatGrid {
  const HeatGrid({
    required this.values,
    required this.resolution,
    required this.extent,
  });

  final Float64List values;
  final int resolution;
  final double extent;

  /// Density at `(col, row)` in `0..1`.
  double at(int col, int row) => values[row * resolution + col];

  /// True when no point contributed any density (all zero).
  bool get isEmpty {
    for (final v in values) {
      if (v > 0) return false;
    }
    return true;
  }
}

/// Bins [points] onto a grid, applies a separable gaussian blur, and
/// normalises to `0..1`.
///
/// - [resolution]: grid cells per axis (default [kHeatGridResolution]).
/// - [extent]: half-width of the covered square in canonical units
///   (default [kHeatGridExtent]); the grid spans `[-extent, +extent]²`.
/// - [kernelRadiusCells]: gaussian blur radius in cells. When null it is
///   chosen adaptively from the point count (a small radius for few points so
///   sparse end-of-game boards still read, a larger one for large stats
///   volumes). Pass an explicit value to override.
///
/// Complexity is O(resolution² + points), independent of points² — separable
/// blur keeps it linear in the grid size.
HeatGrid computeHeatGrid(
  List<HeatPoint> points, {
  int resolution = kHeatGridResolution,
  double extent = kHeatGridExtent,
  int? kernelRadiusCells,
}) {
  assert(resolution > 0);
  assert(extent > 0);

  final raw = Float64List(resolution * resolution);

  // 1. Bin points into grid cells (noise-gated, in-domain only).
  final span = 2 * extent;
  for (final p in points) {
    final r = math.sqrt(p.x * p.x + p.y * p.y);
    if (r > kHeatNoiseRadius) continue; // detector noise
    // Map [-extent, +extent] → [0, resolution).
    final col = ((p.x + extent) / span * resolution).floor();
    final row = ((p.y + extent) / span * resolution).floor();
    if (col < 0 || col >= resolution || row < 0 || row >= resolution) {
      continue; // outside the grid domain
    }
    raw[row * resolution + col] += 1.0;
  }

  // 2. Choose the kernel radius if not given.
  final radius =
      kernelRadiusCells ?? _adaptiveKernelRadius(points.length, resolution);

  // 3. Separable gaussian blur (horizontal then vertical).
  final blurred = radius <= 0 ? raw : _gaussianBlur(raw, resolution, radius);

  // 4. Normalise to 0..1.
  var max = 0.0;
  for (final v in blurred) {
    if (v > max) max = v;
  }
  final normalised = Float64List(blurred.length);
  if (max > 0) {
    for (var i = 0; i < blurred.length; i++) {
      normalised[i] = blurred[i] / max;
    }
  }

  return HeatGrid(values: normalised, resolution: resolution, extent: extent);
}

/// Picks a gaussian kernel radius (in cells) based on the point count.
///
/// Few points → tight kernel (each impact stays visible); many points → wider
/// kernel (a smooth aggregate field). Scaled with grid resolution so the
/// visual spread is roughly resolution-independent.
int _adaptiveKernelRadius(int pointCount, int resolution) {
  final base = resolution / 64.0;
  final int cells;
  if (pointCount <= 0) {
    cells = 0;
  } else if (pointCount <= 30) {
    cells = (4 * base).round();
  } else if (pointCount <= 150) {
    cells = (3 * base).round();
  } else {
    cells = (2 * base).round();
  }
  return math.max(1, cells);
}

/// 1-D gaussian weights for a given radius (sigma = radius / 2), normalised.
Float64List _gaussianWeights(int radius) {
  final sigma = radius / 2.0;
  final twoSigmaSq = 2 * sigma * sigma;
  final weights = Float64List(2 * radius + 1);
  var sum = 0.0;
  for (var i = -radius; i <= radius; i++) {
    final w = math.exp(-(i * i) / twoSigmaSq);
    weights[i + radius] = w;
    sum += w;
  }
  for (var i = 0; i < weights.length; i++) {
    weights[i] /= sum;
  }
  return weights;
}

/// Separable gaussian blur with clamp-to-edge sampling.
Float64List _gaussianBlur(Float64List src, int n, int radius) {
  final weights = _gaussianWeights(radius);
  final tmp = Float64List(src.length);
  final out = Float64List(src.length);

  // Horizontal pass.
  for (var row = 0; row < n; row++) {
    for (var col = 0; col < n; col++) {
      var acc = 0.0;
      for (var k = -radius; k <= radius; k++) {
        final sc = (col + k).clamp(0, n - 1);
        acc += src[row * n + sc] * weights[k + radius];
      }
      tmp[row * n + col] = acc;
    }
  }

  // Vertical pass.
  for (var row = 0; row < n; row++) {
    for (var col = 0; col < n; col++) {
      var acc = 0.0;
      for (var k = -radius; k <= radius; k++) {
        final sr = (row + k).clamp(0, n - 1);
        acc += tmp[sr * n + col] * weights[k + radius];
      }
      out[row * n + col] = acc;
    }
  }

  return out;
}

/// Maps a normalised density `t` (`0..1`) to an RGBA colour on a cold→hot
/// scale: transparent → blue → cyan → yellow → red, with rising alpha.
///
/// Returns a 4-tuple `(r, g, b, a)` with channels in `0..255`. Kept as plain
/// ints (no `Color`) so the colormap is testable without `dart:ui` colour
/// semantics and can be packed straight into an RGBA buffer.
({int r, int g, int b, int a}) heatColor(double t) {
  final v = t.clamp(0.0, 1.0);

  // Colour stops (RGB) along the cold→hot ramp.
  // 0.00 blue  · 0.40 cyan · 0.65 yellow · 1.00 red
  const stops = <({double pos, int r, int g, int b})>[
    (pos: 0.0, r: 0, g: 0, b: 255), // blue
    (pos: 0.40, r: 0, g: 255, b: 255), // cyan
    (pos: 0.65, r: 255, g: 255, b: 0), // yellow
    (pos: 1.0, r: 255, g: 0, b: 0), // red
  ];

  int r = stops.last.r, g = stops.last.g, b = stops.last.b;
  for (var i = 0; i < stops.length - 1; i++) {
    final lo = stops[i];
    final hi = stops[i + 1];
    if (v <= hi.pos) {
      final span = hi.pos - lo.pos;
      final f = span <= 0 ? 0.0 : (v - lo.pos) / span;
      r = _lerpByte(lo.r, hi.r, f);
      g = _lerpByte(lo.g, hi.g, f);
      b = _lerpByte(lo.b, hi.b, f);
      break;
    }
  }

  // Alpha rises with density; a soft ease-in so the low-density tail fades
  // toward transparent rather than a hard floor.
  final alpha = (math.pow(v, 0.6) * 230).round().clamp(0, 255);

  return (r: r, g: g, b: b, a: alpha);
}

int _lerpByte(int a, int b, double f) =>
    (a + (b - a) * f).round().clamp(0, 255);

/// Renders a [HeatGrid] into a tightly-packed RGBA byte buffer of size
/// `resolution * resolution * 4`, applying [heatColor] per cell. Row-major,
/// matching the grid layout. The widget wraps this in a `ui.Image`.
Uint8List heatGridToRgba(HeatGrid grid) {
  final n = grid.resolution;
  final out = Uint8List(n * n * 4);
  for (var i = 0; i < grid.values.length; i++) {
    final c = heatColor(grid.values[i]);
    final o = i * 4;
    out[o] = c.r;
    out[o + 1] = c.g;
    out[o + 2] = c.b;
    out[o + 3] = c.a;
  }
  return out;
}
