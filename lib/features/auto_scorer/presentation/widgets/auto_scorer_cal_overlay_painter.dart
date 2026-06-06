import 'dart:math' as math;

import 'package:dart_lodge/core/utils/stat_formatter.dart';
import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:flutter/material.dart';

/// Map a normalised detection point onto the displayed preview [rect].
///
/// Detection coords are normalised 0–1 but in different reference spaces:
///  * skip-preprocess (default): normalised to the **raw camera frame**, which
///    is what the preview shows → a direct linear map into [rect].
///  * non-skip: normalised to the square **letterbox** the preprocessor builds
///    (scale-to-fit into a square + centred grey pad). We invert that letterbox
///    using the raw frame aspect ([rawFrameSize]) to recover raw-frame-
///    normalised coords, then map into [rect]. Returns null for points that fall
///    in the grey pad (off the real frame), so the caller skips drawing them.
///
/// The square's edge length cancels out of the inversion algebra: with
/// `sW = W/max(W,H)`, `sH = H/max(W,H)` (the frame's scaled fraction of the
/// square), a letterbox-normalised `(u,v)` maps to raw-normalised
/// `((u-0.5)/sW + 0.5, (v-0.5)/sH + 0.5)`.
Offset? mapDetectionToRect(
  BoardPoint p, {
  required Size rect,
  required bool skipPreprocess,
  Size? rawFrameSize,
}) {
  double x = p.x;
  double y = p.y;
  if (!skipPreprocess && rawFrameSize != null) {
    final w = rawFrameSize.width;
    final h = rawFrameSize.height;
    if (w <= 0 || h <= 0) return null;
    final longest = math.max(w, h);
    final sW = w / longest;
    final sH = h / longest;
    x = (p.x - 0.5) / sW + 0.5;
    y = (p.y - 0.5) / sH + 0.5;
    if (x < 0 || x > 1 || y < 0 || y > 1) return null; // in the grey pad
  }
  return Offset(x * rect.width, y * rect.height);
}

/// Draws the model's per-cal best positions over the live aim preview so the
/// user can reframe until all four are found. Cals only (no dart candidates).
///
/// Each detected cal (from [DetectionFrame.calBestPoints], index-aligned with
/// [DetectionFrame.calConfidences]) is a numbered dot + its confidence, coloured
/// by whether it cleared [calConfidence] (accepted vs sub-threshold). A header
/// chip reports "calibrated" (all four) or "n/4 — reframe".
class CalOverlayPainter extends CustomPainter {
  CalOverlayPainter({
    required this.frame,
    required this.skipPreprocess,
    required this.calConfidence,
    required this.scheme,
    this.rawFrameSize,
  });

  final DetectionFrame? frame;
  final bool skipPreprocess;
  final double calConfidence;
  final ColorScheme scheme;
  final Size? rawFrameSize;

  static const double _dotRadius = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    if (f == null) return;

    final accepted = scheme.primary;
    const sub = Color(0xFFFFB300); // amber — detected but below threshold
    final outline = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    var found = 0;
    for (var i = 0; i < f.calBestPoints.length; i++) {
      final p = f.calBestPoints[i];
      if (p == null) continue;
      found++;
      final at = mapDetectionToRect(p,
          rect: size, skipPreprocess: skipPreprocess, rawFrameSize: rawFrameSize);
      if (at == null) continue;
      final conf = i < f.calConfidences.length ? f.calConfidences[i] : null;
      final isAccepted = conf != null && conf >= calConfidence;
      final color = isAccepted ? accepted : sub;

      canvas.drawCircle(at, _dotRadius, outline);
      canvas.drawCircle(at, _dotRadius, Paint()..color = color);
      _label(
        canvas,
        '${i + 1}  ${StatFormatter.fmtDouble(conf, decimals: 2)}',
        at + const Offset(_dotRadius + 4, -_dotRadius - 2),
        color,
      );
    }

    _header(canvas, size, found, f.hasCalibration);
  }

  void _header(Canvas canvas, Size size, int found, bool calibrated) {
    final text = calibrated ? '✓ calibrated' : '$found/4 cals — reframe';
    final color = calibrated ? scheme.primary : const Color(0xFFFFB300);
    final tp = _painter(text, color, 14);
    const pad = 6.0;
    final origin = const Offset(8, 8);
    final bg = Rect.fromLTWH(origin.dx, origin.dy, tp.width + pad * 2,
        tp.height + pad * 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bg, const Radius.circular(6)),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    tp.paint(canvas, origin + const Offset(pad, pad));
  }

  void _label(Canvas canvas, String text, Offset at, Color color) {
    final tp = _painter(text, color, 13);
    // Dark plate behind the text for legibility over the camera image.
    final bg = Rect.fromLTWH(at.dx - 2, at.dy - 1, tp.width + 4, tp.height + 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bg, const Radius.circular(3)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    tp.paint(canvas, at);
  }

  TextPainter _painter(String text, Color color, double fontSize) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant CalOverlayPainter old) =>
      !identical(old.frame, frame) ||
      old.skipPreprocess != skipPreprocess ||
      old.calConfidence != calConfidence ||
      old.rawFrameSize != rawFrameSize ||
      old.scheme != scheme;
}
