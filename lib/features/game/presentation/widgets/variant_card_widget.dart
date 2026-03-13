import 'package:flutter/material.dart';

class VariantCardWidget extends StatelessWidget {
  const VariantCardWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.isSelected = false,
    this.isEnabled = true,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final semanticsLabel = [
      title,
      if (subtitle != null) subtitle!,
      if (!isEnabled) ', coming soon',
    ].join('');

    Widget card = Material(
      color: isSelected ? cs.primaryContainer : cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: cs.onSurface.withOpacity(0.12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: _buildDecoration(cs),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: tt.bodyLarge?.copyWith(
                  color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: tt.bodyMedium?.copyWith(
                    color: isSelected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!isEnabled) {
      card = Opacity(opacity: 0.38, child: card);
    }

    final wrapped = !isEnabled
        ? Tooltip(
            message: 'Custom configuration coming soon',
            child: card,
          )
        : card;

    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: isEnabled,
      child: wrapped,
    );
  }

  // Note: borderRadius is intentionally omitted here — Material's borderRadius
  // clips children so the card appears rounded without triggering Flutter's
  // "uniform colors required with borderRadius" constraint.
  BoxDecoration _buildDecoration(ColorScheme cs) {
    if (isSelected) {
      return BoxDecoration(
        border: Border(
          left: BorderSide(color: cs.primary, width: 3),
          top: BorderSide(color: cs.outline, width: 1),
          right: BorderSide(color: cs.outline, width: 1),
          bottom: BorderSide(color: cs.outline, width: 1),
        ),
      );
    }
    return BoxDecoration(
      border: Border.all(color: cs.outline, width: 1),
    );
  }
}
