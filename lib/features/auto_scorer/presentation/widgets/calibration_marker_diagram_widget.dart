import 'dart:math' as math;

import 'package:dart_lodge/core/widgets/dartboard_face_painter.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:flutter/material.dart';

/// The four wire crossings the detector calibrates on, in DeepDarts cal order
/// (`cal1..cal4`, see `domain/scoring/homography.dart`): the wire between 20
/// and 5, between 3 and 17, between 8 and 11, and between 13 and 6 — each taken
/// where it meets the **outer edge of the double ring**.
///
/// These are what the model's `cal1..cal4` classes detect, and what the player
/// is being asked to keep in frame. The word "corner" that used to describe
/// them was wrong twice over: they are not corners, and they are not on the
/// image (#740).
const List<(int, int)> kCalibrationMarkerWires = [
  (20, 5),
  (3, 17),
  (8, 11),
  (13, 6),
];

/// Canvas angle (radians) of the calibration marker at [index] in the **stored
/// canonical frame** — the same frame [boardSegmentStartAngle] uses.
///
/// The marker sits on the wire between the two segments of
/// `kCalibrationMarkerWires[index]`, i.e. at the start angle of whichever of
/// the two wedges follows the other clockwise. In this frame the four angles
/// come out exactly cardinal — top, bottom, left, right — which is the
/// `cal1 → top, cal2 → bottom, cal3 → left, cal4 → right` mapping
/// `canonicalTransform` is built on.
///
/// Add [kBoardDisplayRotation] to place the marker on a board drawn the
/// standard "20 at the top" way.
double calibrationMarkerAngle(int index) {
  final (a, b) = kCalibrationMarkerWires[index];
  final ia = kBoardFaceClockOrder.indexOf(a);
  final ib = kBoardFaceClockOrder.indexOf(b);
  final n = kBoardFaceClockOrder.length;
  if ((ia + 1) % n == ib) return boardSegmentStartAngle(ib);
  if ((ib + 1) % n == ia) return boardSegmentStartAngle(ia);
  throw StateError('Segments $a and $b are not adjacent on a dartboard.');
}

/// Static dartboard diagram marking the four calibration points the camera
/// looks for (#740, design S1.4).
///
/// Pure UI: no providers, no detection state, nothing animated — it is a
/// drawing in the setup-tips screen, shown identically on the game-flow path
/// and in review mode from Settings. It renders from the shared core board face
/// ([paintDartboardFace]) rather than a bitmap asset, so it stays sharp at any
/// size and costs nothing to ship.
///
/// Square by construction; give it a width and it takes the matching height.
class CalibrationMarkerDiagram extends StatelessWidget {
  const CalibrationMarkerDiagram({super.key, required this.semanticsLabel})
      : markers = null,
        foreground = null;

  /// The same four points, drawn live while aiming (#759): no labels, no leader
  /// lines — at the size this runs at they would crowd out the board — and each
  /// dot coloured by whether the camera has that marker.
  ///
  /// This is deliberately the board's own frame and never the camera image's:
  /// placing a dot where the model saw something would mean mapping detection
  /// space onto the preview, which is the one geometric risk this design keeps
  /// refusing to take. What it can say — WHICH marker is missing, and where it
  /// sits on a board — is what a count of four never said.
  const CalibrationMarkerDiagram.live({
    super.key,
    required this.semanticsLabel,
    required List<MarkerRecognition> this.markers,
    required Color this.foreground,
  });

  /// Spoken description of the diagram — the drawing carries no text a screen
  /// reader could reach, so the caller passes the localised equivalent.
  final String semanticsLabel;

  /// Per-marker state, in the detector's cal order. Null for the static
  /// diagram of the setup tips, which is about where the points ARE.
  final List<MarkerRecognition>? markers;

  /// Colour the live dots are drawn in — the caller's own foreground, so the
  /// diagram reads on whatever it is laid over.
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _CalibrationMarkerDiagramPainter(
            markerColor: foreground ?? theme.colorScheme.primary,
            markerOutlineColor: theme.colorScheme.surface,
            leaderColor: theme.colorScheme.outline,
            markers: markers,
            labelStyle: (theme.textTheme.labelMedium ?? const TextStyle())
                .copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
            textScaler: MediaQuery.textScalerOf(context),
          ),
        ),
      ),
    );
  }
}

class _CalibrationMarkerDiagramPainter extends CustomPainter {
  _CalibrationMarkerDiagramPainter({
    required this.markerColor,
    required this.markerOutlineColor,
    required this.leaderColor,
    required this.markers,
    required this.labelStyle,
    required this.textScaler,
  });

  /// Per-marker state when drawing live; null draws the static diagram.
  final List<MarkerRecognition>? markers;

  bool get _live => markers != null;

  /// Fill of the marker dots. A theme token, not a board colour: the dots are
  /// app chrome laid over the board, not part of it.
  final Color markerColor;

  /// Ring drawn around each dot so it reads over both the black and the cream
  /// segments underneath.
  final Color markerOutlineColor;
  final Color leaderColor;
  final TextStyle labelStyle;
  final TextScaler textScaler;

  /// Upper bound on the board radius as a fraction of half the canvas. The
  /// board never grows past this even when the labels are tiny, so there is
  /// always a visible gutter around the rim.
  static const double _maxBoardFraction = 0.74;

  /// Board radius as a fraction of half the canvas when drawing live. Larger
  /// than [_maxBoardFraction] because nothing has to fit around it.
  static const double _liveBoardFraction = 0.94;

  /// Where the leader line ends, as a fraction of the board radius.
  static const double _leaderEnd = 1.06;

  /// Gap between the end of a leader line and its label box.
  static const double _labelGap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final half = math.min(size.width, size.height) / 2;
    if (half <= 0) return;

    // Lay the labels out first: the board is then sized to whatever room they
    // leave, so a long label or a large text scale shrinks the board instead of
    // running off the canvas. Live, there are no labels to make room for and
    // the board takes almost the whole canvas — it is drawn small enough that
    // every pixel counts.
    final labels = _live
        ? const <TextPainter>[]
        : [for (var i = 0; i < kCalibrationMarkerWires.length; i++) _label(i)];
    final radius =
        _live ? half * _liveBoardFraction : _boardRadius(half, labels);

    // The face is drawn in the canonical frame, so rotate the canvas to get a
    // standard "20 at the top" board. Markers and labels are placed in
    // unrotated canvas space (with the rotation folded into their angle) so the
    // text stays upright.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(kBoardDisplayRotation);
    canvas.translate(-center.dx, -center.dy);
    paintDartboardFace(canvas, center, radius);
    canvas.restore();

    for (var i = 0; i < kCalibrationMarkerWires.length; i++) {
      _paintMarker(canvas, center, radius, i, _live ? null : labels[i]);
    }
  }

  TextPainter _label(int index) {
    final (a, b) = kCalibrationMarkerWires[index];
    // The bar stands for the wire the marker sits on, between the two numbers.
    return TextPainter(
      text: TextSpan(text: '$a | $b', style: labelStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
  }

  /// Largest board radius that still leaves every label fully inside the
  /// canvas.
  ///
  /// A label is centred on the marker's outward direction, just past the leader
  /// line. Along each axis its outer edge must stay within [half], which bounds
  /// the radius; the tightest of the eight bounds (four labels × two axes)
  /// wins, capped by [_maxBoardFraction].
  double _boardRadius(double half, List<TextPainter> labels) {
    var radius = half * _maxBoardFraction;
    for (var i = 0; i < labels.length; i++) {
      final dir = _direction(i);
      final w = labels[i].width, h = labels[i].height;
      // Distance from the leader end to the label centre, along the direction.
      final offset = dir.dx.abs() * w / 2 + dir.dy.abs() * h / 2 + _labelGap;
      for (final (component, extent) in [
        (dir.dx.abs(), w / 2),
        (dir.dy.abs(), h / 2),
      ]) {
        if (component < 1e-6) continue;
        final bound =
            (half - extent - component * offset) / (_leaderEnd * component);
        if (bound < radius) radius = bound;
      }
    }
    return math.max(0, radius);
  }

  /// Outward unit vector of the marker at [index], on a board drawn the
  /// standard "20 at the top" way.
  Offset _direction(int index) {
    final angle = calibrationMarkerAngle(index) + kBoardDisplayRotation;
    return Offset(math.cos(angle), math.sin(angle));
  }

  void _paintMarker(
    Canvas canvas,
    Offset center,
    double radius,
    int index,
    TextPainter? label,
  ) {
    final dir = _direction(index);

    // The markers sit on the outer edge of the double ring, which is where the
    // detector's cal classes are annotated.
    final dot = center + dir * (radius * kBoardRDoubleOuter);
    final leaderEnd = center + dir * (radius * _leaderEnd);

    if (!_live) {
      canvas.drawLine(
        dot,
        leaderEnd,
        Paint()
          ..color = leaderColor
          ..strokeWidth = math.max(1.5, radius * 0.02),
      );
    }

    // Sized to read at a glance on a phone: the dot is the whole point of the
    // diagram, and the ring keeps it visible over both the black and the cream
    // segments it can land on.
    final dotRadius = radius * (_live ? 0.115 : 0.075);
    canvas.drawCircle(
      dot,
      dotRadius + math.max(1.5, radius * 0.022),
      Paint()..color = markerOutlineColor,
    );
    if (_live) {
      // Filled when the marker counts, hollow when it does not, half-strength
      // in between — the same shape language the pips used, so the state
      // survives for a colour-blind player and at this size.
      final state = index < markers!.length
          ? markers![index]
          : MarkerRecognition.missing;
      switch (state) {
        case MarkerRecognition.found:
          canvas.drawCircle(dot, dotRadius, Paint()..color = markerColor);
        case MarkerRecognition.weak:
          canvas.drawCircle(dot, dotRadius,
              Paint()..color = markerColor.withValues(alpha: 0.45));
          canvas.drawCircle(
            dot,
            dotRadius,
            Paint()
              ..color = markerColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.0, dotRadius * 0.35),
          );
        case MarkerRecognition.missing:
          canvas.drawCircle(
            dot,
            dotRadius,
            Paint()
              ..color = markerColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.0, dotRadius * 0.35),
          );
      }
      return;
    }
    canvas.drawCircle(dot, dotRadius, Paint()..color = markerColor);

    final offset =
        dir.dx.abs() * label!.width / 2 +
        dir.dy.abs() * label.height / 2 +
        _labelGap;
    final labelCenter = leaderEnd + dir * offset;
    label.paint(
      canvas,
      labelCenter - Offset(label.width / 2, label.height / 2),
    );
  }

  @override
  bool shouldRepaint(_CalibrationMarkerDiagramPainter old) =>
      old.markerColor != markerColor ||
      old.markerOutlineColor != markerOutlineColor ||
      old.leaderColor != leaderColor ||
      old.labelStyle != labelStyle ||
      old.textScaler != textScaler ||
      !_sameMarkers(old.markers, markers);

  static bool _sameMarkers(
      List<MarkerRecognition>? a, List<MarkerRecognition>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
