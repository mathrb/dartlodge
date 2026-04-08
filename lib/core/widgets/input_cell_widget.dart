import 'package:flutter/material.dart';

import '../utils/app_text_styles.dart';
import '../utils/app_theme.dart';

/// A tappable grid cell used in the dart input grid.
///
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
    this.dotColor,
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
  final Color? dotColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: InkWell(
        onTap: enabled ? () => onTap(segment) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.segmentButton.copyWith(color: textColor),
              ),
              if (dots > 0) ...[
                const SizedBox(height: 4),
                _DotRow(count: dots, color: dotColor ?? textColor),
              ],
            ],
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
