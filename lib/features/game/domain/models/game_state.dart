import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/constants.dart';
import '../engines/base_game_engine.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

@freezed
abstract class GameState with _$GameState {
  const factory GameState({
    required String gameId,
    required GameType gameType,
    required List<CompetitorState> competitors,
    required int currentTurnIndex,
    required int dartsThrownInTurn,
    required bool isComplete,
    String? winnerCompetitorId,
    @Default(GameEngineStatus.initialized) GameEngineStatus status,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);
}

@freezed
abstract class CompetitorState with _$CompetitorState {
  const factory CompetitorState({
    required String competitorId,
    required String name,
    required List<String> playerIds,
    required int score,
    @Default(false) bool isComplete,
    @Default([]) List<String> dartThrows, // Canonical segment strings
  }) = _CompetitorState;

  factory CompetitorState.fromJson(Map<String, dynamic> json) => _$CompetitorStateFromJson(json);
}