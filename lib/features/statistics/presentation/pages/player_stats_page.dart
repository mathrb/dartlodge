import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../../../core/widgets/app_header.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../domain/entities/player_stats.dart';
import '../providers/player_stats_page_provider.dart';
import '../state/player_stats_page_state.dart';
import '../widgets/atc_annotated_dartboard_widget.dart';
import '../widgets/atc_summary_column_widget.dart';
import '../widgets/cricket_stats_detail_table_widget.dart';
import '../widgets/cricket_target_mode_chip_selector_widget.dart';
import '../widgets/cricket_variant_chip_selector_widget.dart';
import '../widgets/mpt_trend_chart_widget.dart';
import '../widgets/practice_game_type_chip_selector_widget.dart';
import '../widgets/practice_stats_detail_table_widget.dart';
import '../widgets/practice_trend_chart_widget.dart';
import '../widgets/ppr_trend_chart_widget.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/stats_detail_table_widget.dart';
import '../widgets/stats_heatmap_section_widget.dart';
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

  // X01/Cricket/Practice are fixed game-type names; "Others" is localized
  // (built in build()).
  static const _tabCount = 4;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
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
    final l10n = AppLocalizations.of(context);
    final asyncPlayer = ref.watch(playerProvider(widget.playerId));
    final playerName = asyncPlayer.value?.name ?? l10n.statsPlayerFallback;
    final tabs = [
      const Tab(text: 'X01'),
      const Tab(text: 'Cricket'),
      Tab(text: l10n.statsPracticeTab),
      Tab(text: l10n.statsOthersTab),
    ];

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
                trailing: IconButton(
                  icon: const Icon(Icons.emoji_events_outlined),
                  color: cs.onSurface,
                  tooltip: l10n.achievementsPageTitle,
                  onPressed: () => context
                      .push(GameRoutes.achievements(widget.playerId)),
                ),
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
              tabs: tabs,
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
                  _ComingSoonTab(label: l10n.statsOthersTab),
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
    final l10n = AppLocalizations.of(context);

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
                message: l10n.statsLoadFailed(e.toString()),
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
              message: l10n.statsLoadFailed(e.toString()),
              onRetry: () =>
                  ref.invalidate(filteredPlayerStatsProvider(playerId)),
            ),
            data: (stats) => StatsDetailTableWidget(stats: stats),
          ),
          StatsHeatmapSectionWidget(
            playerId: playerId,
            gameType: GameType.x01,
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
    final l10n = AppLocalizations.of(context);

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
                message: l10n.statsLoadFailed(e.toString()),
                onRetry: () =>
                    ref.invalidate(filteredCricketStatsProvider(playerId)),
              ),
              data: (stats) => SummaryCardsRowWidget(stats: stats),
            ),
          ),
          CricketTargetModeChipSelectorWidget(playerId: playerId),
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
              message: l10n.statsLoadFailed(e.toString()),
              onRetry: () =>
                  ref.invalidate(filteredCricketStatsProvider(playerId)),
            ),
            data: (stats) => CricketStatsDetailTableWidget(stats: stats),
          ),
          StatsHeatmapSectionWidget(
            playerId: playerId,
            gameType: GameType.cricket,
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
    final l10n = AppLocalizations.of(context);
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
                message: l10n.statsLoadFailed(e.toString()),
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
              message: l10n.statsLoadFailed(e.toString()),
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
          StatsHeatmapSectionWidget(
            playerId: playerId,
            gameType: pageState.selectedPracticeGameType,
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
    final l10n = AppLocalizations.of(context);
    final (label1, val1, label2, val2, label3, val3) = switch (stats.gameType) {
      GameType.aroundTheClock => (
          l10n.statsDrillsPlayed,
          stats.totalGames.toString(),
          l10n.statsCompletions,
          stats.atcCompletions.toString(),
          l10n.statsHitRate,
          StatFormatter.fmtPct(stats.atcHitRate),
        ),
      GameType.bobs27 => (
          l10n.statsDrillsPlayed,
          stats.totalGames.toString(),
          l10n.statsBestScore,
          StatFormatter.fmtInt(stats.bobs27BestScore),
          l10n.statsAvgScore,
          StatFormatter.fmtDouble(stats.bobs27AvgScore),
        ),
      GameType.shanghai => (
          l10n.statsDrillsPlayed,
          stats.totalGames.toString(),
          l10n.statsBestScore,
          StatFormatter.fmtInt(stats.shanghaiBestScore),
          l10n.statsShanghais,
          stats.shanghaiCount.toString(),
        ),
      GameType.catch40 => (
          l10n.statsDrillsPlayed,
          stats.totalGames.toString(),
          l10n.statsBestScore,
          StatFormatter.fmtInt(stats.catch40BestScore),
          l10n.statsAvgScore,
          StatFormatter.fmtDouble(stats.catch40AvgScore),
        ),
      GameType.checkoutPractice => (
          l10n.statsAttempts,
          stats.checkoutAttempts.toString(),
          l10n.statsSuccesses,
          stats.checkoutSuccesses.toString(),
          l10n.statsSuccessRate,
          StatFormatter.fmtPct(stats.checkoutSuccessRate),
        ),
      _ => (
          l10n.statsGamesPlayed,
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
    final l10n = AppLocalizations.of(context);
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
                l10n.statsComingSoon(label),
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

