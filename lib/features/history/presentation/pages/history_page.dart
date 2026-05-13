import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/widgets/error_retry_widget.dart';
import 'package:dart_lodge/core/widgets/loading_spinner_widget.dart';
import 'package:dart_lodge/features/history/presentation/providers/game_history_provider.dart';
import 'package:dart_lodge/features/history/presentation/widgets/game_summary_card_widget.dart';
import 'package:dart_lodge/features/history/presentation/widgets/history_filter_bar_widget.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(gameHistoryProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(gameHistoryProvider);
    final notifier = ref.read(gameHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(GameRoutes.home);
            }
          },
        ),
        title: const Text('History'),
      ),
      body: asyncState.when(
        loading: () => const LoadingSpinnerWidget(),
        error: (e, _) => ErrorRetryWidget(
          message: 'Error loading history: $e',
          onRetry: () => ref.invalidate(gameHistoryProvider),
        ),
        data: (historyState) => Column(
          children: [
            HistoryFilterBarWidget(
              selectedGameType: historyState.filterGameType,
              selectedDateFrom: historyState.filterDateFrom,
              selectedDateTo: historyState.filterDateTo,
              onGameTypeChanged: notifier.setGameTypeFilter,
              onDateRangeChanged: notifier.setDateRange,
              onClearFilters: notifier.clearFilters,
            ),
            Expanded(
              child: historyState.games.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No completed games yet'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: notifier.refresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: historyState.games.length +
                            (historyState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == historyState.games.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final game = historyState.games[index];
                          final competitors =
                              historyState.competitorsByGameId[game.gameId] ??
                                  [];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GameSummaryCardWidget(
                              game: game,
                              competitors: competitors,
                              onTap: () => context
                                  .push('/game/history/${game.gameId}'),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
