import 'package:flutter/material.dart';

/// A horizontal run of small multiplier dots. Used to distinguish singles,
/// doubles and triples on the scoring keypads: the full grid ([DartInputGridWidget])
/// draws a fixed count per row, while the simplified keypad
/// ([SimplifiedDartInputGridWidget]) varies the count live with the armed
/// multiplier.
class DotRow extends StatelessWidget {
  const DotRow({required this.count, required this.color, super.key});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
