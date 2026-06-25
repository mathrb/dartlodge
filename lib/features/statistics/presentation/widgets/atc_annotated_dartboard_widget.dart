import 'dart:math';
import 'package:flutter/material.dart';

import '../../../game/presentation/widgets/dartboard_highlight_widget.dart';

class AtcAnnotatedDartboardWidget extends StatelessWidget {
  const AtcAnnotatedDartboardWidget({
    super.key,
    required this.hits,
    required this.attempts,
  });

  final Map<int, int> hits;
  final Map<int, int> attempts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Outer padding creates room for labels beyond board boundary
    return Padding(
      padding: const EdgeInsets.all(22),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DartboardHighlightWidget(
              currentTarget: null,
              doublesOnly: false,
              noHighlight: true,
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _AtcLabelPainter(
                  hits: hits,
                  attempts: attempts,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtcLabelPainter extends CustomPainter {
  _AtcLabelPainter({
    required this.hits,
    required this.attempts,
    required this.colorScheme,
  });

  final Map<int, int> hits;
  final Map<int, int> attempts;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final labelRadius = radius * 1.07;

    final textStyle = TextStyle(
      color: colorScheme.onSurface,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < 20; i++) {
      final number = kDartboardClockOrder[i];
      // Centre of the wedge for segment [i] — must track the board's geometry
      // (#700) so the % labels stay over their segments.
      final midAngle = dartboardSegmentStartAngle(i) + pi / 20;
      final x = center.dx + labelRadius * cos(midAngle);
      final y = center.dy + labelRadius * sin(midAngle);

      final att = attempts[number] ?? 0;
      final hit = hits[number] ?? 0;
      final label = att > 0 ? '${(hit / att * 100).round()}%' : '—';

      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_AtcLabelPainter old) =>
      old.hits != hits ||
      old.attempts != attempts ||
      old.colorScheme != colorScheme;
}
