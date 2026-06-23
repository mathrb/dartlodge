import 'package:flutter/material.dart';

import '../../../../core/utils/app_theme.dart';

class ConfigStepperWidget extends StatelessWidget {
  const ConfigStepperWidget({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
    this.incrementSemanticLabel,
    this.decrementSemanticLabel,
  });

  final int value;
  final int min;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  /// Accessible name for the increment (+) button. When null the button has no
  /// accessible name (legacy behaviour).
  final String? incrementSemanticLabel;

  /// Accessible name for the decrement (−) button. When null the button has no
  /// accessible name (legacy behaviour).
  final String? decrementSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    ButtonStyle buttonStyle(bool enabled) {
      return OutlinedButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ).copyWith(
        side: WidgetStateProperty.all(
          BorderSide(color: enabled ? cs.primary : cs.outlineVariant),
        ),
        foregroundColor: WidgetStateProperty.all(
          enabled ? cs.primary : cs.onSurface.withValues(alpha: AppTheme.opacityDisabled),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: value > min ? onDecrement : null,
          style: buttonStyle(value > min),
          child: Icon(Icons.remove, semanticLabel: decrementSemanticLabel),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$value', style: Theme.of(context).textTheme.titleLarge),
        ),
        OutlinedButton(
          onPressed: value < max ? onIncrement : null,
          style: buttonStyle(value < max),
          child: Icon(Icons.add, semanticLabel: incrementSemanticLabel),
        ),
      ],
    );
  }
}
