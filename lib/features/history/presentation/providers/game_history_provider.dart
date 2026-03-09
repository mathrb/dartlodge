import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/history/presentation/state/game_history_state.dart';

part 'game_history_provider.g.dart';

const _pageSize = 20;

@riverpod
class GameHistoryNotifier extends _$GameHistoryNotifier {
  GameType? _filterGameType;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  List<String> _filterPlayerIds = [];

  @override
  Future<GameHistoryState> build() async {
    final repo = ref.read(gameRepositoryProvider);
    final games = await repo.getCompletedGames(
      limit: _pageSize,
      offset: 0,
      filterByType: _filterGameType,
    );

    final competitorsList = await Future.wait(
      games.map((g) => repo.getCompetitors(g.gameId)),
    );

    final competitorMap = <String, List<Competitor>>{
      for (var i = 0; i < games.length; i++) games[i].gameId: competitorsList[i],
    };

    final filtered = _applyDateFilter(games);
    final filteredCompMap = <String, List<Competitor>>{
      for (final g in filtered) g.gameId: competitorMap[g.gameId] ?? [],
    };

    return GameHistoryState(
      games: filtered,
      competitorsByGameId: filteredCompMap,
      hasMore: games.length >= _pageSize,
      filterGameType: _filterGameType,
      filterDateFrom: _filterDateFrom,
      filterDateTo: _filterDateTo,
      filterPlayerIds: _filterPlayerIds,
    );
  }

  List<Game> _applyDateFilter(List<Game> games) {
    if (_filterDateFrom == null && _filterDateTo == null) return games;
    return games.where((g) {
      if (g.endTime == null) return false;
      final end = g.endTime!;
      if (_filterDateFrom != null && end.isBefore(_filterDateFrom!)) return false;
      if (_filterDateTo != null &&
          end.isAfter(_filterDateTo!.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final repo = ref.read(gameRepositoryProvider);
      final games = await repo.getCompletedGames(
        limit: _pageSize,
        offset: current.games.length,
        filterByType: _filterGameType,
      );

      final competitorsList = await Future.wait(
        games.map((g) => repo.getCompetitors(g.gameId)),
      );

      final newCompMap = <String, List<Competitor>>{
        for (var i = 0; i < games.length; i++) games[i].gameId: competitorsList[i],
      };

      final filtered = _applyDateFilter(games);
      final filteredCompMap = <String, List<Competitor>>{
        for (final g in filtered) g.gameId: newCompMap[g.gameId] ?? [],
      };

      state = AsyncData(current.copyWith(
        games: [...current.games, ...filtered],
        competitorsByGameId: {...current.competitorsByGameId, ...filteredCompMap},
        hasMore: games.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
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
    _filterPlayerIds = [];
    ref.invalidateSelf();
  }
}
