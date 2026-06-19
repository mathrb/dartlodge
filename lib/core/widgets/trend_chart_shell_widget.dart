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
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: hasEnoughData
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space2,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space2,
              ),
              child: child,
            )
          : Center(
              child: Text(
                // Needs ≥2 games to draw a trend line. Earlier copy was
                // "Not enough data yet" which read as contradicting the
                // populated stat values below the chart (#287); be
                // specific about what's missing instead.
                AppLocalizations.of(context).statsNeedTwoGames,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
    );
  }
}
