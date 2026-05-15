import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/history/presentation/state/game_history_state.dart';

part 'game_history_provider.g.dart';

const _pageSize = 20;

@riverpod
class GameHistoryNotifier extends _$GameHistoryNotifier {
  GameType? _filterGameType;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;

  // Synchronous in-flight flag for loadNextPage. The AsyncValue-based
  // `isLoadingMore` check (state.value!.isLoadingMore) is unreliable as a
  // guard because `state = AsyncData(...)` doesn't propagate to readers until
  // the next microtask — rapid scroll events can issue parallel loadNextPage
  // calls before the guard flips and produce duplicate rows.
  bool _loadingNextPage = false;

  @override
  Future<GameHistoryState> build() async {
    final repo = ref.read(gameRepositoryProvider);
    final games = await repo.getCompletedGames(
      limit: _pageSize,
      offset: 0,
      filterByType: _filterGameType,
      dateFrom: _filterDateFrom,
      dateTo: _filterDateTo,
    );

    final competitorsList = await Future.wait(
      games.map((g) => repo.getCompetitors(g.gameId)),
    );

    final competitorMap = <String, List<Competitor>>{
      for (var i = 0; i < games.length; i++) games[i].gameId: competitorsList[i],
    };

    return GameHistoryState(
      games: games,
      competitorsByGameId: competitorMap,
      hasMore: games.length >= _pageSize,
      filterGameType: _filterGameType,
      filterDateFrom: _filterDateFrom,
      filterDateTo: _filterDateTo,
    );
  }

  Future<void> loadNextPage() async {
    if (_loadingNextPage) return;
    final current = state.value;
    if (current == null || !current.hasMore) return;
    _loadingNextPage = true;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final repo = ref.read(gameRepositoryProvider);
      final games = await repo.getCompletedGames(
        limit: _pageSize,
        offset: current.games.length,
        filterByType: _filterGameType,
        dateFrom: _filterDateFrom,
        dateTo: _filterDateTo,
      );

      final competitorsList = await Future.wait(
        games.map((g) => repo.getCompetitors(g.gameId)),
      );

      final newCompMap = <String, List<Competitor>>{
        for (var i = 0; i < games.length; i++) games[i].gameId: competitorsList[i],
      };

      state = AsyncData(current.copyWith(
        games: [...current.games, ...games],
        competitorsByGameId: {...current.competitorsByGameId, ...newCompMap},
        hasMore: games.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _loadingNextPage = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  void setGameTypeFilter(GameType? type) {
    _filterGameType = type;
    ref.invalidateSelf();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _filterDateFrom = from;
    _filterDateTo = to;
    ref.invalidateSelf();
  }

  void clearFilters() {
    _filterGameType = null;
    _filterDateFrom = null;
    _filterDateTo = null;
    ref.invalidateSelf();
  }
}
