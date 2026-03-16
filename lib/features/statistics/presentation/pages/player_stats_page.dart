import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../players/presentation/providers/players_provider.dart';
import '../providers/statistics_provider.dart';
import '../state/player_stats_page_state.dart';
import '../widgets/ppr_trend_chart_widget.dart';
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
    final asyncPlayer = ref.watch(playerProvider(widget.playerId));
    final playerName = asyncPlayer.value?.name ?? 'Player';

    return Scaffold(
      appBar: AppBar(
        title: Text('$playerName — Stats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 2,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.labelLarge,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _X01TabContent(playerId: widget.playerId),
          const _ComingSoonTab(label: 'Cricket'),
          const _ComingSoonTab(label: 'Practice'),
          const _ComingSoonTab(label: 'Others'),
        ],
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: asyncStats.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorRetry(
                message: 'Failed to load stats: $e',
                onRetry: () => ref.invalidate(filteredPlayerStatsProvider(playerId)),
              ),
              data: (stats) => SummaryCardsRowWidget(stats: stats),
            ),
          ),
          VariantChipSelectorWidget(playerId: playerId),
          TimeRangeSelectorWidget(playerId: playerId),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PprTrendChartWidget(playerId: playerId),
          ),
          const SizedBox(height: 16),
          asyncStats.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorRetry(
              message: 'Failed to load stats: $e',
              onRetry: () => ref.invalidate(filteredPlayerStatsProvider(playerId)),
            ),
            data: (stats) => StatsDetailTableWidget(stats: stats),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String label;

  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Center(
        child: Text(
          'Stats for $label coming soon',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
