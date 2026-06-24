import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'heatmap_density.dart';

/// Clockwise segment order starting from 20 at the top.
///
/// Mirrors `kDartboardClockOrder` in
/// `lib/features/game/presentation/widgets/dartboard_highlight_widget.dart`.
/// It is duplicated here on purpose: that constant lives in `features/game`,
/// and `lib/core/` must not import `lib/features/` (dependency direction —
/// features depend on core, never the reverse). The order is a fixed property
/// of a regulation dartboard, so the small duplication is the correct trade-off
/// against introducing a core→feature import.
const List<int> kHeatmapClockOrder = [
  20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
];

/// Angular width of one segment wedge: 18° (2π / 20).
const double kHeatmapSegmentSweep = math.pi / 10;

/// Canvas start angle (radians) of the wedge for the segment at [index] in
/// [kHeatmapClockOrder], expressed in the **stored canonical frame**.
///
/// That frame is the auto-scorer's scoring frame (`canonicalTransform` /
/// `dartboard_scorer`), which anchors on the detectable **5/20 calibration
/// wire at the top** (`cal1 → top`). Consequently segment 20 spans the bin just
/// clockwise of vertical (`[-π/2, -π/2 + sweep]`, centre at `-π/2 + π/20`), not
/// centred on the top. Index 0 (segment 20) therefore starts at `-π/2` and each
/// subsequent index advances one sweep clockwise (canvas angles increase
/// clockwise, y-down). The density image is plotted in this same frame, so the
/// wedges and the impacts are mutually aligned here — they are rotated together
/// for display by [kHeatmapDisplayRotation] so a standard "20 at the top" board
/// is what the user sees. The position data / homography are never touched.
double heatmapSegmentStartAngle(int index) =>
    -math.pi / 2 + index * kHeatmapSegmentSweep;

/// Display-only rotation applied to the whole heatmap (board wedges + density
/// image together) so the stored canonical frame — which puts the 5/20 wire at
/// the top — renders as a standard board with **segment 20 centred at the top**
/// and the 5/20 wire ~9° left of vertical (#697).
///
/// It is exactly minus half a segment: the scorer's segment-20 centre sits at
/// `-π/2 + π/20` (9° clockwise of vertical), and rotating by `-π/20` brings it
/// to straight up. Applying it to BOTH layers keeps every impact inside its
/// wedge; it changes nothing about the stored positions or the scoring frame.
const double kHeatmapDisplayRotation = -kHeatmapSegmentSweep / 2;

/// Renders a density heatmap of dart impacts over a dartboard face.
///
/// Input is a list of normalised positions in the canonical board frame
/// (`(0,0)` = bull centre, radius `1.0` = outer edge of the double ring, "20 at
/// the top"). Drive it from a passed-in list — this widget does NO data wiring.
///
/// Empty input renders nothing (a [SizedBox.shrink]) so callers can place it
/// unconditionally and have it disappear for manual-only games.
///
/// Architecture note: this lives in `lib/core/`, which must not import
/// `lib/features/`. The existing `DartboardHighlightWidget` board face lives in
/// `features/game`, so it cannot be reused here. Instead the painter draws its
/// own faithful-enough board backdrop (option (a) of the SI-4 plan). Dartboard
/// segment colours are an accepted hardcoded-colour exception (see CLAUDE.md);
/// all non-dartboard chrome uses themed tokens.
class HeatmapDartboardWidget extends StatefulWidget {
  const HeatmapDartboardWidget({
    super.key,
    required this.points,
    this.resolution = kHeatGridResolution,
    this.kernelRadiusCells,
    this.placeholder,
  });

  /// Normalised dart positions to render. Empty → widget hidden.
  final List<HeatPoint> points;

  /// Density grid resolution (cells per axis).
  final int resolution;

  /// Optional explicit gaussian kernel radius (cells). Null = adaptive.
  final int? kernelRadiusCells;

  /// Optional widget shown instead of nothing when [points] is empty.
  final Widget? placeholder;

  @override
  State<HeatmapDartboardWidget> createState() => _HeatmapDartboardWidgetState();
}

class _HeatmapDartboardWidgetState extends State<HeatmapDartboardWidget> {
  ui.Image? _image;
  HeatGrid? _grid;

  @override
  void initState() {
    super.initState();
    _rebuildImage();
  }

  @override
  void didUpdateWidget(covariant HeatmapDartboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.points, widget.points) ||
        oldWidget.resolution != widget.resolution ||
        oldWidget.kernelRadiusCells != widget.kernelRadiusCells) {
      _rebuildImage();
    }
  }

  Future<void> _rebuildImage() async {
    if (widget.points.isEmpty) {
      _disposeImage();
      if (mounted) setState(() => _grid = null);
      return;
    }

    final grid = computeHeatGrid(
      widget.points,
      resolution: widget.resolution,
      kernelRadiusCells: widget.kernelRadiusCells,
    );
    final rgba = heatGridToRgba(grid);

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      grid.resolution,
      grid.resolution,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;

    if (!mounted) {
      image.dispose();
      return;
    }
    _disposeImage();
    setState(() {
      _grid = grid;
      _image = image;
    });
  }

  void _disposeImage() {
    _image?.dispose();
    _image = null;
  }

  @override
  void dispose() {
    _disposeImage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _HeatmapDartboardPainter(
          image: _image,
          extent: _grid?.extent ?? kHeatGridExtent,
        ),
      ),
    );
  }
}

class _HeatmapDartboardPainter extends CustomPainter {
  _HeatmapDartboardPainter({required this.image, required this.extent});

  /// The pre-computed density image (resolution × resolution RGBA), or null
  /// while it is still being generated.
  final ui.Image? image;

  /// Canonical half-extent the density image covers (`[-extent, +extent]`).
  final double extent;

  // Radii as fractions of total board radius — match DartboardHighlightWidget.
  static const double _rDoubleBull = 0.05;
  static const double _rSingleBull = 0.115;
  static const double _rTripleInner = 0.415;
  static const double _rTripleOuter = 0.475;
  static const double _rDoubleInner = 0.825;
  static const double _rDoubleOuter = 0.900;

  // ── Dartboard segment colours (canonical, NOT theme tokens) ──────────────
  // These mirror the physical-board palette used by DartboardHighlightWidget.
  // Substituting theme colours would break recognition of the board. This is
  // the accepted hardcoded-colour exception documented in CLAUDE.md.
  static const Color _darkBase = Color(0xFF212121); // segment black
  static const Color _lightBase = Color(0xFFE0D5C1); // segment cream
  static final Color _darkColored = Colors.green[800]!;
  static final Color _lightColored = Colors.red[800]!;
  static final Color _bullSingle = Colors.green[600]!;
  static final Color _bullDouble = Colors.red[700]!;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rotate the whole rendering (wedges + density image, drawn in the stored
    // canonical frame) so a standard "20 at the top" board is shown (#697). Both
    // layers share the rotation, so every impact stays inside its wedge; the
    // centred bull/outline circles are rotation-invariant.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(kHeatmapDisplayRotation);
    canvas.translate(-center.dx, -center.dy);

    _paintBoard(canvas, center, radius);

    // The board radius (1.0 canonical) corresponds to the double-ring outer
    // edge. The density image spans [-extent, +extent] canonical, i.e. a square
    // of side (2*extent) board-radii. Place it centred on the board, clipped to
    // the board disc so off-board misses fade at the rim.
    final img = image;
    if (img != null) {
      final half = radius * extent;
      final dst = Rect.fromCenter(
        center: center,
        width: half * 2,
        height: half * 2,
      );
      final src = Rect.fromLTWH(
        0,
        0,
        img.width.toDouble(),
        img.height.toDouble(),
      );

      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      // Linear sampling smooths the coarse density grid.
      final paint = Paint()..filterQuality = FilterQuality.medium;
      canvas.drawImageRect(img, src, dst, paint);
      canvas.restore();
    }

    canvas.restore(); // display rotation
  }

  void _paintBoard(Canvas canvas, Offset center, double radius) {
    const sweep = kHeatmapSegmentSweep; // 18°

    // 1. Outer single areas (full pie under everything).
    for (var i = 0; i < 20; i++) {
      final isDark = i.isEven;
      _fillPie(
        canvas,
        center,
        radius,
        heatmapSegmentStartAngle(i),
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
        radius * _rTripleInner,
        radius * _rTripleOuter,
        heatmapSegmentStartAngle(i),
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
        radius * _rDoubleInner,
        radius * _rDoubleOuter,
        heatmapSegmentStartAngle(i),
        sweep,
        isDark ? _darkColored : _lightColored,
      );
    }

    // 4. Bull.
    _fillRing(
      canvas,
      center,
      radius * _rDoubleBull,
      radius * _rSingleBull,
      0,
      2 * math.pi,
      _bullSingle,
    );
    canvas.drawCircle(
      center,
      radius * _rDoubleBull,
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

  @override
  bool shouldRepaint(_HeatmapDartboardPainter old) =>
      !identical(old.image, image) || old.extent != extent;
}
