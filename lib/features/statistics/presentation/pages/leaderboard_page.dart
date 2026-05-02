import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../core/widgets/loading_spinner_widget.dart';
import '../providers/statistics_provider.dart';
import '../widgets/leaderboard_row_widget.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  String _selectedMetric = 'threeDartAverage';

  static const _segments = [
    ButtonSegment(value: 'threeDartAverage', label: Text('3-Dart Avg')),
    ButtonSegment(value: 'checkoutPercentage', label: Text('Checkout %')),
    ButtonSegment(value: 'winRate', label: Text('Win Rate')),
    ButtonSegment(value: 'dartsPerLeg', label: Text('Darts/Leg')),
  ];

  @override
  Widget build(BuildContext context) {
    final leaderboard = ref.watch(leaderboardProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: _segments,
                  selected: {_selectedMetric},
                  onSelectionChanged: (selected) {
                    final metric = selected.first;
                    setState(() => _selectedMetric = metric);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Min games',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: '5'),
                onSubmitted: (value) {
                  ref
                      .read(leaderboardProvider.notifier)
                      .setMinGames(int.tryParse(value) ?? 5);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: leaderboard.when(
            loading: () => const LoadingSpinnerWidget(),
            error: (e, _) => ErrorRetryWidget(
              message: 'Failed to load leaderboard: $e',
              onRetry: () => ref.invalidate(leaderboardProvider),
            ),
            data: (stats) {
              if (stats.isEmpty) {
                return const Center(
                  child: Text('No players with enough games yet'),
                );
              }
              return ListView.builder(
                itemCount: stats.length,
                itemBuilder: (context, i) => InkWell(
                  onTap: () =>
                      context.go('/stats/player/${stats[i].playerId}'),
                  child: LeaderboardRowWidget(
                    rank: i + 1,
                    stats: stats[i],
                    metric: _selectedMetric,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
