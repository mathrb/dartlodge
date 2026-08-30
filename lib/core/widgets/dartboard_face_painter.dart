/// Shared dartboard-face geometry and painting.
///
/// Two unrelated screens draw a board backdrop from code rather than from an
/// image asset: the statistics heatmap (`HeatmapDartboardWidget`, #571) and the
/// auto-assist calibration-marker diagram (`CalibrationMarkerDiagram`, #740).
/// The geometry lives here so both share one definition of the wedge order,
/// the ring radii and the display rotation.
///
/// Architecture note: this lives in `lib/core/`, which must not import
/// `lib/features/`. `DartboardHighlightWidget` (`features/game`) draws its own
/// board face for the same reason — the duplication across that boundary is
/// deliberate (see the note on [kBoardFaceClockOrder]).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Clockwise segment order beginning with 20 (index 0).
///
/// This is the wedge ORDER, not a positional claim — in the stored frame index
/// 0's wedge starts at the top wire, not centred on it; see
/// [boardSegmentStartAngle] and [kBoardDisplayRotation].
///
/// Mirrors `kDartboardClockOrder` in
/// `lib/features/game/presentation/widgets/dartboard_highlight_widget.dart`.
/// It is duplicated here on purpose: that constant lives in `features/game`,
/// and `lib/core/` must not import `lib/features/` (dependency direction —
/// features depend on core, never the reverse). The order is a fixed property
/// of a regulation dartboard, so the small duplication is the correct trade-off
/// against introducing a core→feature import.
const List<int> kBoardFaceClockOrder = [
  20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
];

/// Angular width of one segment wedge: 18° (2π / 20).
const double kBoardSegmentSweep = math.pi / 10;

/// Canvas start angle (radians) of the wedge for the segment at [index] in
/// [kBoardFaceClockOrder], expressed in the **stored canonical frame**.
///
/// That frame is the auto-scorer's scoring frame (`canonicalTransform` /
/// `dartboard_scorer`), which anchors on the detectable **5/20 calibration
/// wire at the top** (`cal1 → top`). Consequently segment 20 spans the bin just
/// clockwise of vertical (`[-π/2, -π/2 + sweep]`, centre at `-π/2 + π/20`), not
/// centred on the top. Index 0 (segment 20) therefore starts at `-π/2` and each
/// subsequent index advances one sweep clockwise (canvas angles increase
/// clockwise, y-down).
///
/// The start angle of wedge `i` is also the wire between segment `i-1` and
/// segment `i` — which is how the calibration markers are placed (#740).
double boardSegmentStartAngle(int index) =>
    -math.pi / 2 + index * kBoardSegmentSweep;

/// Display-only rotation applied to a whole board rendering so the stored
/// canonical frame — which puts the 5/20 wire at the top — renders as a
/// standard board with **segment 20 centred at the top** and the 5/20 wire ~9°
/// left of vertical (#697).
///
/// It is exactly minus half a segment: the scorer's segment-20 centre sits at
/// `-π/2 + π/20` (9° clockwise of vertical), and rotating by `-π/20` brings it
/// to straight up. Apply it to EVERY layer of a rendering (wedges and whatever
/// is plotted in the canonical frame on top) so the layers stay mutually
/// aligned; it changes nothing about stored positions or the scoring frame.
const double kBoardDisplayRotation = -kBoardSegmentSweep / 2;

// Ring radii as fractions of the total board radius — match
// DartboardHighlightWidget.
const double kBoardRDoubleBull = 0.05;
const double kBoardRSingleBull = 0.115;
const double kBoardRTripleInner = 0.415;
const double kBoardRTripleOuter = 0.475;
const double kBoardRDoubleInner = 0.825;

/// Outer edge of the double ring — the "board radius 1.0" of the canonical
/// scoring frame, and the circle the four calibration markers sit on.
const double kBoardRDoubleOuter = 0.900;

// ── Dartboard segment colours (canonical, NOT theme tokens) ────────────────
// These mirror the physical-board palette used by DartboardHighlightWidget.
// Substituting theme colours would break recognition of the board, so the
// board face is the standing exception to "never hardcode colors"
// (`docs/rules/ui-design.md`) — settled in the #195 audit and not to be
// re-raised. Everything drawn over the face uses theme tokens.
const Color _darkBase = Color(0xFF212121); // segment black
const Color _lightBase = Color(0xFFE0D5C1); // segment cream
final Color _darkColored = Colors.green[800]!;
final Color _lightColored = Colors.red[800]!;
final Color _bullSingle = Colors.green[600]!;
final Color _bullDouble = Colors.red[700]!;

/// Paint a dartboard face — wedges, triple/double rings, bull and rim outline —
/// centred on [center] with the given outer [radius], in the stored canonical
/// frame.
///
/// The caller decides whether to apply [kBoardDisplayRotation]: rotate the
/// canvas around [center] before calling to render a standard "20 at the top"
/// board.
void paintDartboardFace(Canvas canvas, Offset center, double radius) {
  const sweep = kBoardSegmentSweep; // 18°

  // 1. Outer single areas (full pie under everything).
  for (var i = 0; i < 20; i++) {
    final isDark = i.isEven;
    _fillPie(
      canvas,
      center,
      radius,
      boardSegmentStartAngle(i),
      sweep,
      isDark ? _darkBase : _lightBase,
    );
  }

  // 2. Triple ring.
  for (var i = 0; i < 20; i++) {
    final isDark = i.isEven;
    _fillRing(
      canvas,
      center,
      radius * kBoardRTripleInner,
      radius * kBoardRTripleOuter,
      boardSegmentStartAngle(i),
      sweep,
      isDark ? _darkColored : _lightColored,
    );
  }

  // 3. Double ring.
  for (var i = 0; i < 20; i++) {
    final isDark = i.isEven;
    _fillRing(
      canvas,
      center,
      radius * kBoardRDoubleInner,
      radius * kBoardRDoubleOuter,
      boardSegmentStartAngle(i),
      sweep,
      isDark ? _darkColored : _lightColored,
    );
  }

  // 4. Bull.
  _fillRing(
    canvas,
    center,
    radius * kBoardRDoubleBull,
    radius * kBoardRSingleBull,
    0,
    2 * math.pi,
    _bullSingle,
  );
  canvas.drawCircle(
    center,
    radius * kBoardRDoubleBull,
    Paint()..color = _bullDouble,
  );

  // 5. Faint outline so the board edge reads against any background.
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * 0.01)
      ..color = const Color(0xFF000000).withValues(alpha: 0.25),
  );
}

void _fillPie(
  Canvas canvas,
  Offset center,
  double radius,
  double startAngle,
  double sweep,
  Color color,
) {
  final path = Path()
    ..moveTo(center.dx, center.dy)
    ..arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
    )
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

void _fillRing(
  Canvas canvas,
  Offset center,
  double innerR,
  double outerR,
  double startAngle,
  double sweep,
  Color color,
) {
  final path = Path()
    ..moveTo(
      center.dx + innerR * math.cos(startAngle),
      center.dy + innerR * math.sin(startAngle),
    )
    ..arcTo(
      Rect.fromCircle(center: center, radius: outerR),
      startAngle,
      sweep,
      false,
    )
    ..arcTo(
      Rect.fromCircle(center: center, radius: innerR),
      startAngle + sweep,
      -sweep,
      false,
    )
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}
