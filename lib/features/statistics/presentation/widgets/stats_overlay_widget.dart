import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/statistics_provider.dart';

class StatsOverlayWidget extends ConsumerWidget {
  const StatsOverlayWidget({
    required this.gameId,
    required this.onDismiss,
    super.key,
  });

  final String gameId;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(liveGameStatsProvider(gameId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: AppTheme.shadowAlphaSheet),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Live Stats',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
                ],
              ),
              const Divider(),
              asyncStats.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: LoadingSpinnerWidget(),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorRetryWidget(
                    message: 'Error: $err',
                    onRetry: () =>
                        ref.invalidate(liveGameStatsProvider(gameId)),
                  ),
                ),
                data: (gameStats) {
                  return Column(
                    children: gameStats.byCompetitor.map((cs) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cs.competitorName,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              'Avg: ${StatFormatter.fmtDouble(cs.threeDartAverage)} | Darts: ${cs.totalDartsThrown}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
