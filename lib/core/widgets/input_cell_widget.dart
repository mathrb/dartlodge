import 'package:flutter/material.dart';

import '../utils/app_text_styles.dart';

/// A tappable grid cell used in the dart input grid.
///
/// Promoted from the private `_GridCell` in `dart_input_grid_widget.dart`.
/// The cricket (`_InputCell`) and practice (`_AtcInputCell`) variants deviate
/// significantly in structure (fixed width, Tooltip/isRowClosed, Material/InkWell,
/// dimForeground) and are intentionally left as file-private classes.
class InputCellWidget extends StatelessWidget {
  const InputCellWidget({
    required this.label,
    required this.segment,
    required this.semanticLabel,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
    this.dots = 0,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String segment;
  final String semanticLabel;
  final Color bgColor;
  final Color textColor;
  final void Function(String) onTap;
  final int dots;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        label: semanticLabel,
        child: InkWell(
          onTap: enabled ? () => onTap(segment) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                right: BorderSide(color: cs.outline, width: 1),
                bottom: BorderSide(color: cs.outline, width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  label,
                  style: AppTextStyles.segmentButton.copyWith(color: textColor),
                ),
                if (dots > 0) _DotRow(count: dots, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  const _DotRow({required this.count, required this.color});

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
