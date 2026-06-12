import 'dart:math';

import 'package:flutter/material.dart';

/// Painted cricket mark glyph: 0 = dash (or ghost dot), 1 = slash, 2 = cross,
/// 3+ = circled cross. Extracted from `CricketUnifiedTableWidget`'s private
/// painter (#479) so the at-distance marks strip can share it — at 2.4 m it is
/// the stroke weight, not a font size, that carries legibility.
class CricketMarkPainter extends CustomPainter {
  const CricketMarkPainter({
    required this.marks,
    required this.color,
    this.strokeWidth = 2.5,
    this.zeroAsDot = false,
  });

  final int marks;
  final Color color;

  /// Table uses the historical 2.5; the camera-first strip uses ~4 for
  /// at-distance reading.
  final double strokeWidth;

  /// When set, 0 marks renders as a small ghost dot instead of a dash
  /// (the strip's "nothing here yet" affordance).
  final bool zeroAsDot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final arm = size.width * 0.38;

    if (marks == 0) {
      if (zeroAsDot) {
        canvas.drawCircle(
          Offset(cx, cy),
          strokeWidth * 0.8,
          paint..style = PaintingStyle.fill,
        );
      } else {
        canvas.drawLine(
          Offset(cx - arm, cy),
          Offset(cx + arm, cy),
          paint..strokeWidth = strokeWidth * 0.8,
        );
      }
      return;
    }

    // Diagonal arm length for slash/X marks (same for all mark counts)
    final armDiag = arm / sqrt(2) * 1.15;

    if (marks >= 3) {
      canvas.drawCircle(Offset(cx, cy), size.width * 0.44, paint);
    }

    if (marks >= 2) {
      canvas.drawLine(
          Offset(cx - armDiag, cy + armDiag), Offset(cx + armDiag, cy - armDiag), paint);
      canvas.drawLine(
          Offset(cx - armDiag, cy - armDiag), Offset(cx + armDiag, cy + armDiag), paint);
    } else {
      canvas.drawLine(
          Offset(cx - armDiag, cy + armDiag), Offset(cx + armDiag, cy - armDiag), paint);
    }
  }

  @override
  bool shouldRepaint(CricketMarkPainter old) =>
      old.marks != marks ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.zeroAsDot != zeroAsDot;
}
