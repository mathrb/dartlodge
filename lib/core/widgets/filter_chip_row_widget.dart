import 'package:flutter/material.dart';

import '../utils/app_spacing.dart';

class FilterChipRowWidget<T> extends StatelessWidget {
  const FilterChipRowWidget({
    required this.items,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.allLabel,
    super.key,
  });

  final List<T> items;
  final T? selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onSelected;
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget chip({
      required String label,
      required bool isSelected,
      required VoidCallback onTap,
    }) =>
        FilterChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: cs.primaryContainer,
          checkmarkColor: cs.onPrimaryContainer,
          backgroundColor: cs.surfaceContainerHighest,
          labelStyle: TextStyle(
            color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          ),
          onSelected: (_) => onTap(),
        );

    // Wrap (multi-line) rather than a horizontal SingleChildScrollView
    // (single-line, possibly off-screen). At 412px the practice-tab chip
    // row (5 game types) would silently extend past the right edge with
    // no scroll affordance, hiding "Checkout" entirely (#261). Wrap
    // auto-flows to a second row when needed — short rows render the
    // same as before.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Wrap(
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space2,
        children: [
          if (allLabel != null)
            chip(
              label: allLabel!,
              isSelected: selected == null,
              onTap: () => onSelected(null),
            ),
          ...items.map(
            (item) => chip(
              label: labelBuilder(item),
              isSelected: selected == item,
              onTap: () => onSelected(selected == item ? null : item),
            ),
          ),
        ],
      ),
    );
  }
}
