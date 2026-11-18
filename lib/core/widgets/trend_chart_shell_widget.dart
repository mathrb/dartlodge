import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../utils/app_spacing.dart';
import '../utils/app_theme.dart';

class TrendChartShellWidget extends StatelessWidget {
  final bool hasEnoughData;
  final Widget child;

  const TrendChartShellWidget({
    super.key,
    required this.hasEnoughData,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!hasEnoughData) {
      // One line instead of an empty 200 px box, so the stats below stay
      // near the top of the page. Needs ≥2 games to draw a trend line.
      // Earlier copy was "Not enough data yet" which read as contradicting
      // the populated stat values below the chart (#287); be specific
      // about what's missing instead.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Text(
          AppLocalizations.of(context).statsNeedTwoGames,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space2,
          AppSpacing.space2,
          AppSpacing.space4,
          AppSpacing.space2,
        ),
        child: child,
      ),
    );
  }
}
