import 'package:flutter/material.dart';

class VariantPillWidget extends StatelessWidget {
  const VariantPillWidget({
    super.key,
    required this.label,
    this.isSelected = false,
    this.isRecommended = false,
    this.isEnabled = true,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isRecommended;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Widget pill = SizedBox(
      width: double.infinity,
      height: 72,
      child: Material(
        color: _backgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(36),
          child: Container(
            decoration: isRecommended || isSelected
                ? null
                : BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(36),
                  ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _labelColor(colorScheme),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );

    if (!isEnabled) {
      return Opacity(opacity: 0.5, child: pill);
    }
    return pill;
  }

  Color _backgroundColor(ColorScheme colorScheme) {
    if (isRecommended) return colorScheme.primary;
    if (isSelected) return colorScheme.primaryContainer;
    return Colors.transparent;
  }

  Color _labelColor(ColorScheme colorScheme) {
    if (isRecommended) return colorScheme.onPrimary;
    if (isSelected) return colorScheme.onPrimaryContainer;
    return colorScheme.onSurface;
  }
}
