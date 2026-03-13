import 'dart:math';
import 'package:flutter/material.dart';

class DartboardHighlightWidget extends StatelessWidget {
  const DartboardHighlightWidget({
    super.key,
    required this.currentTarget,
    required this.doublesOnly,
    this.bobs27 = false,
    this.noHighlight = false,
  });

  final int? currentTarget; // 1–20 or null (bull)
  final bool doublesOnly;
  final bool bobs27;
  final bool noHighlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _DartboardPainter(
          currentTarget: currentTarget,
          doublesOnly: doublesOnly,
          bobs27: bobs27,
          noHighlight: noHighlight,
          colorScheme: colorScheme,
        ),
      ),
    );
  }
}

class _DartboardPainter extends CustomPainter {
  _DartboardPainter({
    required this.currentTarget,
    required this.doublesOnly,
    required this.colorScheme,
    this.bobs27 = false,
    this.noHighlight = false,
  });

  final int? currentTarget;
  final bool doublesOnly;
  final bool bobs27;
  final bool noHighlight;
  final ColorScheme colorScheme;

  // Clockwise segment order starting from top (20 at top)
  static const List<int> _clockOrder = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
  ];

  // Radii as fractions of total radius
  static const double _rDoubleBull = 0.05;
  static const double _rSingleBull = 0.115;
  static const double _rTripleInner = 0.415;
  static const double _rTripleOuter = 0.475;
  static const double _rDoubleInner = 0.825;
  static const double _rDoubleOuter = 0.900;

  // Base colors
  static const Color _darkBase = Color(0xFF212121);
  static const Color _lightBase = Color(0xFFE0D5C1);
  static final Color _darkColored = Colors.green[800]!;
  static final Color _lightColored = Colors.red[800]!;
  static final Color _bullSingle = Colors.green[600]!;
  static final Color _bullDouble = Colors.red[700]!;

  bool get _hasHighlight {
    if (noHighlight) return false;
    if (currentTarget == null) return true;
    final t = currentTarget!;
    return t >= 1 && t <= 20;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bool highlighting = _hasHighlight;

    // 1. Draw 20 pie segments (full board radius)
    for (int i = 0; i < 20; i++) {
      final number = _clockOrder[i];
      final isTarget = currentTarget != null && currentTarget == number;
      final isDark = i.isEven;
      final baseColor = isDark ? _darkBase : _lightBase;
      final opacity = highlighting && !isTarget ? 0.35 : (isTarget && bobs27 ? 0.40 : 1.0);

      final startAngle = _segmentStartAngle(i);
      const sweepAngle = pi / 10; // 18 degrees

      final paint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);
    }

    // 2. Draw triple ring arcs
    for (int i = 0; i < 20; i++) {
      final number = _clockOrder[i];
      final isTarget = currentTarget != null && currentTarget == number;
      final isDark = i.isEven;
      final startAngle = _segmentStartAngle(i);
      const sweepAngle = pi / 10;

      Color color;
      double opacity;
      if (isTarget && !doublesOnly && !bobs27) {
        color = colorScheme.primary;
        opacity = 1.0;
      } else if (isTarget && bobs27) {
        color = isDark ? _darkColored : _lightColored;
        opacity = 0.40;
      } else {
        color = isDark ? _darkColored : _lightColored;
        opacity = highlighting && !isTarget ? 0.35 : 1.0;
      }

      _drawRingSegment(
        canvas,
        center,
        radius * _rTripleInner,
        radius * _rTripleOuter,
        startAngle,
        sweepAngle,
        color.withValues(alpha: opacity),
      );
    }

    // 3. Draw single large area (between triple outer and double inner)
    for (int i = 0; i < 20; i++) {
      final number = _clockOrder[i];
      final isTarget = currentTarget != null && currentTarget == number;
      final isDark = i.isEven;
      final baseColor = isDark ? _darkBase : _lightBase;
      final startAngle = _segmentStartAngle(i);
      const sweepAngle = pi / 10;

      Color color;
      double opacity;
      if (isTarget && !doublesOnly && !bobs27) {
        color = colorScheme.primary;
        opacity = 1.0;
      } else if (isTarget && bobs27) {
        color = baseColor;
        opacity = 0.40;
      } else {
        color = baseColor;
        opacity = highlighting && !isTarget ? 0.35 : 1.0;
      }

      _drawRingSegment(
        canvas,
        center,
        radius * _rSingleBull,
        radius * _rTripleInner,
        startAngle,
        sweepAngle,
        color.withValues(alpha: opacity),
      );

      _drawRingSegment(
        canvas,
        center,
        radius * _rTripleOuter,
        radius * _rDoubleInner,
        startAngle,
        sweepAngle,
        color.withValues(alpha: opacity),
      );
    }

    // 4. Draw double ring arcs
    for (int i = 0; i < 20; i++) {
      final number = _clockOrder[i];
      final isTarget = currentTarget != null && currentTarget == number;
      final isDark = i.isEven;
      final startAngle = _segmentStartAngle(i);
      const sweepAngle = pi / 10;

      Color color;
      double opacity;
      if (isTarget) {
        color = colorScheme.primary;
        opacity = 1.0;
      } else {
        color = isDark ? _darkColored : _lightColored;
        opacity = highlighting && !isTarget ? 0.35 : 1.0;
      }

      _drawRingSegment(
        canvas,
        center,
        radius * _rDoubleInner,
        radius * _rDoubleOuter,
        startAngle,
        sweepAngle,
        color.withValues(alpha: opacity),
      );
    }

    // Draw outer border ring (beyond double outer to board edge)
    for (int i = 0; i < 20; i++) {
      final isDark = i.isEven;
      final baseColor = isDark ? _darkBase : _lightBase;
      final startAngle = _segmentStartAngle(i);
      const sweepAngle = pi / 10;
      final opacity = highlighting ? 0.35 : 1.0;

      _drawRingSegment(
        canvas,
        center,
        radius * _rDoubleOuter,
        radius,
        startAngle,
        sweepAngle,
        baseColor.withValues(alpha: opacity),
      );
    }

    // 5. Draw single bull ring
    {
      final isBullTarget = currentTarget == null;
      final color = isBullTarget ? colorScheme.primary : _bullSingle;
      final opacity = highlighting && !isBullTarget ? 0.35 : 1.0;

      _drawCircle(
        canvas,
        center,
        radius * _rDoubleBull,
        radius * _rSingleBull,
        color.withValues(alpha: opacity),
      );
    }

    // 6. Draw double bull circle
    {
      final isBullTarget = currentTarget == null;
      final color = isBullTarget ? colorScheme.primary : _bullDouble;
      final opacity = highlighting && !isBullTarget ? 0.35 : 1.0;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * _rDoubleBull, paint);
    }

    // Glow effect for highlighted segments
    if (highlighting) {
      _drawHighlightGlow(canvas, center, radius);
    }

    // 7. Draw segment number labels
    _drawLabels(canvas, center, radius, highlighting);
  }

  void _drawHighlightGlow(Canvas canvas, Offset center, double radius) {
    if (currentTarget == null) {
      // Glow on bull
      final glowPaint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * _rSingleBull, glowPaint);
    } else {
      final t = currentTarget!;
      if (t < 1 || t > 20) return;
      final segIndex = _clockOrder.indexOf(t);
      if (segIndex < 0) return;

      final startAngle = _segmentStartAngle(segIndex);
      const sweepAngle = pi / 10;

      final glowPaint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..style = PaintingStyle.fill;

      final innerR = (doublesOnly || bobs27) ? radius * _rDoubleInner : radius * _rSingleBull;

      final path = Path();
      path.moveTo(
        center.dx + innerR * cos(startAngle),
        center.dy + innerR * sin(startAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius * _rDoubleOuter),
        startAngle,
        sweepAngle,
        false,
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerR),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, glowPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, bool highlighting) {
    const labelRadius = 0.94;
    for (int i = 0; i < 20; i++) {
      final number = _clockOrder[i];
      final isTarget = currentTarget != null && currentTarget == number;
      final midAngle = _segmentStartAngle(i) + pi / 20; // center of segment

      final x = center.dx + radius * labelRadius * cos(midAngle);
      final y = center.dy + radius * labelRadius * sin(midAngle);

      final opacity = highlighting && !isTarget ? 0.4 : 1.0;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$number',
          style: TextStyle(
            color: Colors.white.withValues(alpha: opacity),
            fontSize: radius * 0.08,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  double _segmentStartAngle(int index) {
    // Top = -90° in canvas coords, each segment = 18° = pi/10
    return -pi / 2 + index * pi / 10;
  }

  void _drawRingSegment(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(
      center.dx + innerRadius * cos(startAngle),
      center.dy + innerRadius * sin(startAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawCircle(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius));
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DartboardPainter oldDelegate) {
    return oldDelegate.currentTarget != currentTarget ||
        oldDelegate.doublesOnly != doublesOnly ||
        oldDelegate.bobs27 != bobs27 ||
        oldDelegate.noHighlight != noHighlight;
  }
}
