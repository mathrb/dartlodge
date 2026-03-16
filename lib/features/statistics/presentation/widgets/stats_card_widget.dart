import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';

class StatsCardWidget extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const StatsCardWidget({
    required this.label,
    required this.value,
    this.subtitle,
    super.key,
  });

  static String format(double? v, {int decimals = 1}) =>
      v != null ? v.toStringAsFixed(decimals) : '—';

  static String formatInt(int? v) => v != null ? v.toString() : '—';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.scoreSmall(context).copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
