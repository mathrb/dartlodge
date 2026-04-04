import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../players/presentation/providers/players_provider.dart';
import '../../domain/entities/player_stats.dart';
import '../providers/statistics_provider.dart';
import '../state/player_stats_page_state.dart';
import '../widgets/atc_annotated_dartboard_widget.dart';
import '../widgets/atc_summary_column_widget.dart';
import '../widgets/cricket_stats_detail_table_widget.dart';
import '../widgets/cricket_variant_chip_selector_widget.dart';
import '../widgets/mpt_trend_chart_widget.dart';
import '../widgets/practice_game_type_chip_selector_widget.dart';
import '../widgets/practice_stats_detail_table_widget.dart';
import '../widgets/practice_trend_chart_widget.dart';
import '../widgets/ppr_trend_chart_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/stats_detail_table_widget.dart';
import '../widgets/summary_cards_row_widget.dart';
import '../widgets/time_range_selector_widget.dart';
import '../widgets/variant_chip_selector_widget.dart';

class PlayerStatsPage extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerStatsPage({super.key, required this.playerId});

  @override
  ConsumerState<PlayerStatsPage> createState() => _PlayerStatsPageState();
}

class _PlayerStatsPageState extends ConsumerState<PlayerStatsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'X01'),
    Tab(text: 'Cricket'),
    Tab(text: 'Practice'),
    Tab(text: 'Others'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      ref
          .read(playerStatsPageProvider(widget.playerId).notifier)
          .setTab(StatsTabIndex.values[_tabController.index]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final asyncPlayer = ref.watch(playerProvider(widget.playerId));
    final playerName = asyncPlayer.value?.name ?? 'Player';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: AppHeader(
                showBack: true,
                onBack: () => context.pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space2,
              ),
              child: Text(
                playerName.toUpperCase(),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: _tabs,
              indicatorColor: cs.primaryFixed,
              indicatorWeight: 2,
              labelColor: cs.primaryFixed,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: AppTextStyles.labelLarge,
              unselectedLabelStyle: AppTextStyles.labelLarge,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _X01TabContent(playerId: widget.playerId),
                  _CricketTabContent(playerId: widget.playerId),
                  _PracticeTabContent(playerId: widget.playerId),
                  const _ComingSoonTab(label: 'Others'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _X01TabContent extends ConsumerWidget {
  final String playerId;

  const _X01TabContent({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(filteredPlayerStatsProvider(playerId));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: asyncStats.when(
              loading: () => const LoadingSpinnerWidget(height: 80),
              error: (e, _) => ErrorRetryWidget(
                message: 'Failed to load stats: $e',
                onRetry: () =>
                    ref.invalidate(filteredPlayerStatsProvider(playerId)),
              ),
              data: (stats) => SummaryCardsRowWidget(stats: stats),
            ),
          ),
          VariantChipSelectorWidget(playerId: playerId),
          TimeRangeSelectorWidget(playerId: playerId),
          const SizedBox(height: AppSpacing.space2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: PprTrendChartWidget(playerId: playerId),
          ),
          const SizedBox(height: AppSpacing.space4),
          asyncStats.when(
            loading: () => const LoadingSpinnerWidget(height: 200),
            error: (e, _) => ErrorRetryWidget(
              message: 'Failed to load stats: $e',
              onRetry: () =>
                  ref.invalidate(filteredPlayerStatsProvider(playerId)),
            ),
            data: (stats) => StatsDetailTableWidget(stats: stats),
          ),
        ],
      ),
    );
  }
}

class _CricketTabContent extends ConsumerWidget {
  final String playerId;

  const _CricketTabContent({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(filteredCricketStatsProvider(playerId));

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: asyncStats.when(
              loading: () => const LoadingSpinnerWidget(height: 80),
              error: (e, _) => ErrorRetryWidget(
                message: 'Failed to load stats: $e',
                onRetry: () =>
                    ref.invalidate(filteredCricketStatsProvider(playerId)),
              ),
              data: (stats) => SummaryCardsRowWidget(stats: stats),
            ),
          ),
          CricketVariantChipSelectorWidget(playerId: playerId),
          TimeRangeSelectorWidget(playerId: playerId),
          const SizedBox(height: AppSpacing.space2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: MptTrendChartWidget(playerId: playerId),
          ),
          const SizedBox(height: AppSpacing.space4),
          asyncStats.when(
            loading: () => const LoadingSpinnerWidget(height: 200),
            error: (e, _) => ErrorRetryWidget(
              message: 'Failed to load stats: $e',
              onRetry: () =>
                  ref.invalidate(filteredCricketStatsProvider(playerId)),
            ),
            data: (stats) => CricketStatsDetailTableWidget(stats: stats),
          ),
        ],
      ),
    );
  }
}

class _PracticeTabContent extends ConsumerWidget {
  final String playerId;

  const _PracticeTabContent({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(filteredPracticeStatsProvider(playerId));
    final pageState = ref.watch(playerStatsPageProvider(playerId));
    final isAtc =
        pageState.selectedPracticeGameType == GameType.aroundTheClock;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space4),
          PracticeGameTypeChipSelectorWidget(playerId: playerId),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: asyncStats.when(
              loading: () => const LoadingSpinnerWidget(height: 80),
              error: (e, _) => ErrorRetryWidget(
                message: 'Failed to load stats: $e',
                onRetry: () =>
                    ref.invalidate(filteredPracticeStatsProvider(playerId)),
              ),
              data: (stats) => _PracticeSummaryCards(stats: stats),
            ),
          ),
          TimeRangeSelectorWidget(playerId: playerId),
          const SizedBox(height: AppSpacing.space2),
          asyncStats.when(
            loading: () => const LoadingSpinnerWidget(height: 200),
            error: (e, _) => ErrorRetryWidget(
              message: 'Failed to load stats: $e',
              onRetry: () =>
                  ref.invalidate(filteredPracticeStatsProvider(playerId)),
            ),
            data: (stats) => isAtc
                ? _AtcBoardAndSummary(stats: stats)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                        child: PracticeTrendChartWidget(playerId: playerId),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      PracticeStatsDetailTableWidget(stats: stats),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AtcBoardAndSummary extends StatelessWidget {
  final PlayerStats stats;

  const _AtcBoardAndSummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: AtcAnnotatedDartboardWidget(
              hits: stats.atcSegmentHits,
              attempts: stats.atcSegmentAttempts,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: AtcSummaryColumnWidget(
              hits: stats.atcSegmentHits,
              attempts: stats.atcSegmentAttempts,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeSummaryCards extends StatelessWidget {
  final PlayerStats stats;

  const _PracticeSummaryCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    String fmtPct(double? v) =>
        v != null ? '${(v * 100).toStringAsFixed(1)}%' : '—';

    final (label1, val1, label2, val2, label3, val3) = switch (stats.gameType) {
      GameType.aroundTheClock => (
          'Drills Played',
          stats.totalGames.toString(),
          'Completions',
          stats.atcCompletions.toString(),
          'Hit Rate',
          fmtPct(stats.atcHitRate),
        ),
      GameType.bobs27 => (
          'Drills Played',
          stats.totalGames.toString(),
          'Best Score',
          stats.bobs27BestScore?.toString() ?? '—',
          'Avg Score',
          stats.bobs27AvgScore?.toStringAsFixed(1) ?? '—',
        ),
      GameType.shanghai => (
          'Drills Played',
          stats.totalGames.toString(),
          'Best Score',
          stats.shanghaiBestScore?.toString() ?? '—',
          'Shanghais',
          stats.shanghaiCount.toString(),
        ),
      GameType.catch40 => (
          'Drills Played',
          stats.totalGames.toString(),
          'Best Score',
          stats.catch40BestScore?.toString() ?? '—',
          'Avg Score',
          stats.catch40AvgScore?.toStringAsFixed(1) ?? '—',
        ),
      GameType.checkoutPractice => (
          'Attempts',
          stats.checkoutAttempts.toString(),
          'Successes',
          stats.checkoutSuccesses.toString(),
          'Success Rate',
          fmtPct(stats.checkoutSuccessRate),
        ),
      _ => (
          'Games Played',
          stats.totalGames.toString(),
          '—',
          '—',
          '—',
          '—',
        ),
    };

    return Row(
      children: [
        Expanded(child: StatsCardWidget(label: label1, value: val1)),
        Expanded(child: StatsCardWidget(label: label2, value: val2)),
        Expanded(child: StatsCardWidget(label: label3, value: val3)),
      ],
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String label;

  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.6,
      child: Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Stats for $label coming soon',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

