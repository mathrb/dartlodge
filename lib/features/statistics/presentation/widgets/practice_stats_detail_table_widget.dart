import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/player_stats.dart';

class PracticeStatsDetailTableWidget extends StatelessWidget {
  final PlayerStats stats;

  const PracticeStatsDetailTableWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String fmtDouble(double? v, {int decimals = 2}) =>
        v != null ? v.toStringAsFixed(decimals) : '—';

    String fmtPct(double? v) =>
        v != null ? '${(v * 100).toStringAsFixed(1)}%' : '—';

    String fmtInt(int? v) => v != null ? v.toString() : '—';

    final rows = switch (stats.gameType) {
      GameType.aroundTheClock => <_TableRow>[
          _SectionHeader('METRIC', 'VALUE'),
          _DataRow('Drills Played', stats.totalGames.toString()),
          _DataRow('Completions', stats.atcCompletions.toString()),
          _DataRow('Hit Rate', fmtPct(stats.atcHitRate)),
          _DataRow('Avg Turns to Complete', fmtDouble(stats.atcAvgTurns, decimals: 1)),
          _DataRow('Best Turns to Complete', fmtInt(stats.atcBestTurns)),
        ],
      GameType.bobs27 => <_TableRow>[
          _SectionHeader('METRIC', 'VALUE'),
          _DataRow('Drills Played', stats.totalGames.toString()),
          _DataRow('Avg Score', fmtDouble(stats.bobs27AvgScore, decimals: 1)),
          _DataRow('Best Score', fmtInt(stats.bobs27BestScore)),
          _DataRow('Completion Rate', fmtPct(stats.bobs27CompletionRate)),
          _DataRow('Doubles Hit Rate', fmtPct(stats.bobs27DoubleHitRate)),
        ],
      GameType.shanghai => <_TableRow>[
          _SectionHeader('METRIC', 'VALUE'),
          _DataRow('Drills Played', stats.totalGames.toString()),
          _DataRow('Avg Score', fmtDouble(stats.shanghaiAvgScore, decimals: 1)),
          _DataRow('Best Score', fmtInt(stats.shanghaiBestScore)),
          _DataRow('Shanghai Count', stats.shanghaiCount.toString()),
        ],
      GameType.catch40 => <_TableRow>[
          _SectionHeader('METRIC', 'VALUE'),
          _DataRow('Drills Played', stats.totalGames.toString()),
          _DataRow('Avg Score (/ 120)', fmtDouble(stats.catch40AvgScore, decimals: 1)),
          _DataRow('Best Score', fmtInt(stats.catch40BestScore)),
          _DataRow('2-dart checkouts', stats.catch40TwoDartCheckouts.toString()),
          _DataRow('3-dart checkouts', stats.catch40ThreeDartCheckouts.toString()),
          _DataRow('4–6 dart checkouts', stats.catch40FourSixDartCheckouts.toString()),
          _DataRow('Failed', stats.catch40FailedCheckouts.toString()),
        ],
      GameType.checkoutPractice => <_TableRow>[
          _SectionHeader('METRIC', 'VALUE'),
          _DataRow('Total Attempts', stats.checkoutAttempts.toString()),
          _DataRow('Total Successes', stats.checkoutSuccesses.toString()),
          _DataRow('Success Rate', fmtPct(stats.checkoutSuccessRate)),
        ],
      _ => <_TableRow>[],
    };

    int dataRowIndex = 0;
    final children = <Widget>[];
    for (final row in rows) {
      switch (row) {
        case _SectionHeader r:
          children.add(_buildHeader(theme, colorScheme, r));
        case _DataRow r:
          final bg = dataRowIndex.isEven
              ? colorScheme.surface
              : theme.scaffoldBackgroundColor;
          dataRowIndex++;
          children.add(_buildDataRow(theme, colorScheme, r, bg));
      }
    }

    return Column(children: children);
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, _SectionHeader row) {
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 1.2,
    );
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(row.col1, style: labelStyle),
          ),
          SizedBox(
            width: 100,
            child: Text(row.col2, style: labelStyle, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(ThemeData theme, ColorScheme colorScheme, _DataRow row, Color bg) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              row.value,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

sealed class _TableRow {}

class _SectionHeader extends _TableRow {
  final String col1;
  final String col2;
  _SectionHeader(this.col1, this.col2);
}

class _DataRow extends _TableRow {
  final String label;
  final String value;
  _DataRow(this.label, this.value);
}
