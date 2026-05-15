import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';

part 'game_history_state.freezed.dart';

@freezed
abstract class GameHistoryState with _$GameHistoryState {
  const factory GameHistoryState({
    @Default(<Game>[]) List<Game> games,
    @Default(<String, List<Competitor>>{})
    Map<String, List<Competitor>> competitorsByGameId,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
    GameType? filterGameType,
    DateTime? filterDateFrom,
    DateTime? filterDateTo,
  }) = _GameHistoryState;

  factory GameHistoryState.initial() => const GameHistoryState();
}
