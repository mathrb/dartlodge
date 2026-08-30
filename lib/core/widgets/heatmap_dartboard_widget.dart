import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'dartboard_face_painter.dart';
import 'heatmap_density.dart';

/// Renders a density heatmap of dart impacts over a dartboard face.
///
/// Input is a list of normalised positions in the canonical board frame (see
/// [HeatPoint] for the exact orientation: `(0,0)` = bull centre, radius `1.0` =
/// outer edge of the double ring, 5/20 wire at top — rendered as a standard
/// "20 at top" board via [kBoardDisplayRotation]). Drive it from a passed-in
/// list — this widget does NO data wiring.
///
/// Empty input renders nothing (a [SizedBox.shrink]) so callers can place it
/// unconditionally and have it disappear for manual-only games.
///
/// Architecture note: this lives in `lib/core/`, which must not import
/// `lib/features/`. The existing `DartboardHighlightWidget` board face lives in
/// `features/game`, so it cannot be reused here. Instead the board backdrop is
/// drawn by [paintDartboardFace] (`dartboard_face_painter.dart`), the shared
/// core-side board face this widget and the auto-assist calibration diagram
/// (#740) both paint. Dartboard segment colours are an accepted
/// hardcoded-colour exception (see CLAUDE.md); all non-dartboard chrome uses
/// themed tokens.
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
    canvas.rotate(kBoardDisplayRotation);
    canvas.translate(-center.dx, -center.dy);

    paintDartboardFace(canvas, center, radius);

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

  @override
  bool shouldRepaint(_HeatmapDartboardPainter old) =>
      !identical(old.image, image) || old.extent != extent;
}
