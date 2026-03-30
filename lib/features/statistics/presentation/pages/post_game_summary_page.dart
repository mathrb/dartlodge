import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/entities/game_stats.dart';
import '../providers/statistics_provider.dart';

class PostGameSummaryPage extends ConsumerWidget {
  const PostGameSummaryPage({required this.gameId, super.key});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(gameStatsProvider(gameId));

    return Scaffold(
      body: SafeArea(
        child: asyncStats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (gameStats) => _SummaryBody(gameStats: gameStats),
        ),
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.gameStats});

  final GameStats gameStats;

  CompetitorStats? _findWinner() {
    if (gameStats.byCompetitor.isEmpty) return null;
    return gameStats.byCompetitor.reduce(
      (a, b) => a.legsWon >= b.legsWon ? a : b,
    );
  }

  @override
  Widget build(BuildContext context) {
    final winner = _findWinner();
    final opponents = winner == null
        ? gameStats.byCompetitor
        : gameStats.byCompetitor
            .where((c) => c.competitorId != winner.competitorId)
            .toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(),
              if (winner != null) ...[
                _WinnerCard(winner: winner),
                const SizedBox(height: 16),
              ],
              if (opponents.isNotEmpty) ...[
                ...opponents.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OpponentCard(stats: c),
                    )),
                const SizedBox(height: 16),
              ],
              _StatsBreakdownSection(
                allCompetitors: gameStats.byCompetitor,
                winnerId: winner?.competitorId,
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyFooter(),
        ),
      ],
    );
  }
}

// ── Winner Card ───────────────────────────────────────────────────────────────

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.winner});

  final CompetitorStats winner;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border(
            left: BorderSide(color: cs.primaryFixed, width: 4),
          ),
        ),
        child: IntrinsicHeight(
         child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Identity section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    // Ghost trophy watermark
                    Positioned(
                      right: -24,
                      top: -24,
                      child: Icon(
                        Icons.emoji_events,
                        size: 120,
                        color: cs.onSurface.withValues(alpha: 0.04),
                        semanticLabel: null,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.primaryFixed,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                'WINNER',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onPrimaryFixed,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.stars,
                              color: cs.primaryFixed,
                              size: 20,
                              semanticLabel: 'Winner star',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          winner.competitorName.toUpperCase(),
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${winner.legsWon} LEG${winner.legsWon == 1 ? '' : 'S'} WON',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Stats panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border(
                  left: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BigStat(
                    label: 'AVG PPR',
                    value: winner.threeDartAverage.toStringAsFixed(1),
                    color: cs.primaryFixed,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    width: 48,
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  _BigStat(
                    label: 'DARTS',
                    value: '${winner.totalDartsThrown}',
                    color: cs.onSurface,
                  ),
                ],
              ),
            ),
          ],
         ),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.scoreMedium(context).copyWith(color: color),
        ),
      ],
    );
  }
}

// ── Opponent Card ─────────────────────────────────────────────────────────────

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({required this.stats});

  final CompetitorStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border(
          left: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.competitorName.toUpperCase(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'OPPONENT',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              _SmallStat(
                label: 'PPR',
                value: stats.threeDartAverage.toStringAsFixed(1),
              ),
              const SizedBox(width: 24),
              _SmallStat(
                label: 'DARTS',
                value: '${stats.totalDartsThrown}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.scoreSmall(context).copyWith(
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Stats Breakdown Table ─────────────────────────────────────────────────────

class _StatsBreakdownSection extends StatelessWidget {
  const _StatsBreakdownSection({
    required this.allCompetitors,
    required this.winnerId,
  });

  final List<CompetitorStats> allCompetitors;
  final String? winnerId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 1, color: cs.primaryFixed),
            const SizedBox(width: 12),
            Text(
              'STATISTICS BREAKDOWN',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _StatsTable(
              allCompetitors: allCompetitors,
              winnerId: winnerId,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsTable extends StatelessWidget {
  const _StatsTable({
    required this.allCompetitors,
    required this.winnerId,
  });

  final List<CompetitorStats> allCompetitors;
  final String? winnerId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final rows = <_StatRow>[
      _StatRow(
        category: 'Avg PPR',
        values: allCompetitors
            .map((c) => c.threeDartAverage.toStringAsFixed(1))
            .toList(),
        highlights: allCompetitors.map((c) => c.competitorId == winnerId).toList(),
      ),
      _StatRow(
        category: 'Checkout',
        values: allCompetitors
            .map((c) => c.checkoutPercentage != null
                ? '${c.checkoutPercentage!.round()}%'
                : '—')
            .toList(),
        highlights: allCompetitors.map((_) => false).toList(),
      ),
      _StatRow(
        category: 'Best Out',
        values: allCompetitors
            .map((c) => c.highestCheckout != null ? '${c.highestCheckout}' : '—')
            .toList(),
        highlights: allCompetitors.map((_) => false).toList(),
      ),
      _StatRow(
        category: '180s',
        values: allCompetitors.map((c) => c.oneEightyTurns.toString()).toList(),
        highlights: allCompetitors.map((_) => false).toList(),
      ),
      _StatRow(
        category: '60+',
        values: allCompetitors.map((c) => c.sixtyPlusTurns.toString()).toList(),
        highlights: allCompetitors.map((_) => false).toList(),
      ),
      _StatRow(
        category: '100+',
        values: allCompetitors.map((c) => c.oneHundredPlusTurns.toString()).toList(),
        highlights: allCompetitors.map((_) => false).toList(),
      ),
      _StatRow(
        category: '140+',
        values: allCompetitors.map((c) => c.oneFortyPlusTurns.toString()).toList(),
        highlights: allCompetitors.map((_) => false).toList(),
      ),
    ];

    final headerStyle = tt.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w900,
    );
    final categoryStyle = tt.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w700,
    );
    const cellPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder(
        horizontalInside: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.08),
        ),
      ),
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLarge),
            ),
          ),
          children: [
            Padding(
              padding: cellPadding,
              child: Text('CATEGORY', style: headerStyle),
            ),
            ...allCompetitors.map((c) {
              final isWinner = c.competitorId == winnerId;
              return Padding(
                padding: cellPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shortName(c.competitorName),
                      style: tt.labelMedium?.copyWith(
                        color: isWinner ? cs.primaryFixed : cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isWinner ? 'WINNER' : 'OPPONENT',
                      style: tt.labelSmall?.copyWith(
                        color: isWinner
                            ? cs.primaryFixed.withValues(alpha: 0.7)
                            : cs.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        // Data rows
        ...rows.map((row) => TableRow(
              children: [
                Padding(
                  padding: cellPadding,
                  child: Text(
                    row.category.toUpperCase(),
                    style: categoryStyle,
                  ),
                ),
                ...List.generate(allCompetitors.length, (i) {
                  final isHighlight = row.highlights[i];
                  return Padding(
                    padding: cellPadding,
                    child: Text(
                      row.values[i],
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: isHighlight ? cs.primaryFixed : cs.onSurface,
                        fontSize: 20,
                      ),
                    ),
                  );
                }),
              ],
            )),
      ],
    );
  }

  String _shortName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return name;
    return '${parts.first} ${parts.last[0]}.';
  }
}

class _StatRow {
  const _StatRow({
    required this.category,
    required this.values,
    required this.highlights,
  });

  final String category;
  final List<String> values;
  final List<bool> highlights;
}

// ── Sticky Footer ─────────────────────────────────────────────────────────────

class _StickyFooter extends StatelessWidget {
  const _StickyFooter();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: cs.surfaceContainer.withValues(alpha: 0.3),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: _FooterButton(
                  label: 'DONE',
                  icon: Icons.check_circle_outline,
                  isPrimary: false,
                  onTap: () => context.go('/'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FooterButton(
                  label: 'PLAY AGAIN',
                  icon: Icons.refresh,
                  isPrimary: true,
                  onTap: () => context.go('/game-setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor = isPrimary ? cs.primaryFixed : cs.surfaceContainerHighest;
    final fgColor = isPrimary ? cs.onPrimaryFixed : cs.onSurface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: isPrimary
                ? null
                : Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fgColor, size: 20,
                  semanticLabel: label),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
