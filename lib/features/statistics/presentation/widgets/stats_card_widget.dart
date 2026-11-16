import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/stat_formatter.dart';

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
      StatFormatter.fmtDouble(v, decimals: decimals);

  static String formatInt(int? v) => StatFormatter.fmtInt(v);

  /// Inner padding of the card.
  static const padding = EdgeInsets.all(12);

  static TextStyle? labelStyle(ThemeData theme) =>
      theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );

  static TextStyle valueStyle(ThemeData theme) =>
      AppTextStyles.scoreSmall.copyWith(color: theme.colorScheme.primary);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        // Label at the top, value at the bottom: when the card is stretched
        // to a taller sibling (StatsCardRowWidget), the numerals of a row
        // line up even if the labels wrap to different line counts. Under
        // unbounded height the column keeps its content size.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle(theme)),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(value, style: valueStyle(theme)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
