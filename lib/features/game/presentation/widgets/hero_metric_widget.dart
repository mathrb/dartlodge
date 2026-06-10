import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';

/// Large, at-distance-readable primary game-state value for auto-scoring mode
/// (#442 / epic #440).
///
/// In auto-scoring the phone is mounted near the board and the player stands at
/// the oche (~2.4 m), where the small primary value (X01 remaining score, the
/// current practice target) is illegible. This renders that single value
/// prominently with an optional caption.
///
/// Presentational and game-agnostic: the X01 / Cricket / Practice camera-first
/// layouts compose it with no per-game branching. The [value] is a pre-formatted
/// String — the consumer formats (e.g. via `StatFormatter`), so this widget
/// never formats numbers itself. Manual-mode layouts do not use this widget.
class HeroMetricWidget extends StatelessWidget {
  const HeroMetricWidget({
    required this.value,
    this.label,
    this.valueColor,
    super.key,
  });

  /// The primary value, already formatted by the caller (e.g. an X01 remaining
  /// score `'341'`, an ATC target `'14'`, a Bob's double `'D14'`).
  final String value;

  /// Optional caption shown above the value; rendered uppercased.
  final String? label;

  /// Optional tint for the value; defaults to `colorScheme.onSurface`.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          // Over-line above the hero numeral → label-sm in primaryFixed
          // (DESIGN_SYSTEM §3); the token already carries the over-line tracking.
          Text(
            label!.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: cs.primaryFixed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],
        // Score numerals never scale or wrap — the container is constrained by
        // the consumer, the numeral renders at its tier size (DESIGN_SYSTEM
        // §3.3). maxLines:1 with the default clip keeps it to one line.
        Text(
          value,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: AppTextStyles.scoreActive.copyWith(
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}
