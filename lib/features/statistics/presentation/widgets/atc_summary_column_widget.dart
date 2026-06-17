import 'package:flutter/material.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/stat_formatter.dart';

class AtcSummaryColumnWidget extends StatelessWidget {
  const AtcSummaryColumnWidget({
    super.key,
    required this.hits,
    required this.attempts,
  });

  final Map<int, int> hits;
  final Map<int, int> attempts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final totalAttempts = attempts.values.fold(0, (a, b) => a + b);
    final totalHits = hits.values.fold(0, (a, b) => a + b);
    final overall = totalAttempts > 0 ? totalHits / totalAttempts : null;

    // Per-segment rates (only for attempted segments)
    final rates = <int, double>{
      for (final k in attempts.keys)
        if ((attempts[k] ?? 0) > 0) k: (hits[k] ?? 0) / attempts[k]!,
    };

    final sorted = rates.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });

    final best3 = sorted.take(3).toList();
    // Filter out segments already shown in best3 to avoid overlap
    final best3Keys = best3.map((e) => e.key).toSet();
    final worst3 = sorted.reversed
        .where((e) => !best3Keys.contains(e.key))
        .take(3)
        .toList();

    final colorSuccess = AppTheme.success(context);

    String fmtRate(double v) => StatFormatter.fmtPct(v, decimals: 0);

    Widget sectionHeader(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            text,
            style: AppTextStyles.labelSmall
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
        );

    Widget rateRow(int segment, double rate, Color labelColor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$segment',
                style: AppTextStyles.labelMedium
                    .copyWith(color: labelColor, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                fmtRate(rate),
                style: AppTextStyles.labelMedium
                    .copyWith(color: colorScheme.onSurface),
              ),
            ],
          ),
        );

    Widget emptyState(String msg) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            msg,
            style: AppTextStyles.bodySmall
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
        );

    return Card(
      color: colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionHeader(l10n.summaryOverall.toUpperCase()),
            // The OVERALL value uses scoreSmall (36pt). On a 412px-wide
            // screen this column gets ~82px (Row flex 4:1 split), and
            // "100%" overflows — it wraps into "10\n0\n%" across three
            // lines. FittedBox(scaleDown) keeps the headline value on
            // one line by shrinking to fit; smaller values render at
            // the natural size (#261).
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: overall != null
                  ? Text(
                      fmtRate(overall),
                      maxLines: 1,
                      style: AppTextStyles.scoreSmall
                          .copyWith(color: colorScheme.primary),
                    )
                  : Text(
                      '—',
                      maxLines: 1,
                      style: AppTextStyles.scoreSmall
                          .copyWith(color: colorScheme.onSurfaceVariant),
                    ),
            ),
            Divider(color: colorScheme.outline, height: 16),
            sectionHeader(l10n.summaryBest.toUpperCase()),
            if (best3.isEmpty)
              emptyState(l10n.summaryNoData)
            else
              for (final e in best3) rateRow(e.key, e.value, colorSuccess),
            Divider(color: colorScheme.outline, height: 16),
            sectionHeader(l10n.summaryWeakest.toUpperCase()),
            if (worst3.isEmpty)
              emptyState(l10n.summaryNoData)
            else
              for (final e in worst3)
                rateRow(e.key, e.value, colorScheme.error),
          ],
        ),
      ),
    );
  }
}
