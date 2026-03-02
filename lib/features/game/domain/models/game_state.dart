import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/constants.dart';
import '../engines/base_game_engine.dart';
import '../entities/game.dart';
import '../entities/competitor.dart';
import '../models/game_config.dart';

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
    @Default(false) bool turnActive,
    @Default(1) int legsToWin,
    @Default(0) int currentLegIndex,
    @Default('straight') String inStrategy,
    @Default('double') String outStrategy,
    @Default(501) int startingScore,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);

  /// Creates an initial GameState from a Game and its competitors
  /// This is used for state reconstruction from events
  factory GameState.initial(Game game, List<Competitor> competitors) {
    // Extract configuration from game config
    int startingScore = 501; // Default for X01 games
    String inStrategy = 'straight';
    String outStrategy = 'straight';

    // Use runtime type checking to extract configuration
    if (game.config is X01GameConfig) {
      final x01Config = game.config as X01GameConfig;
      startingScore = x01Config.startingScore;
      inStrategy = x01Config.inStrategy;
      outStrategy = x01Config.outStrategy;
    } else {
      // For non-X01 games, use default values
      startingScore = 0;
    }

    // Convert competitors to competitor states
    final competitorStates = competitors.map((competitor) => CompetitorState(
      competitorId: competitor.competitorId,
      name: competitor.name,
      playerIds: competitor.players.map((player) => player.playerId).toList(),
      score: startingScore, // Score is set based on game type above
      isComplete: false,
      dartThrows: const [],
      isIn: false,
      legsWon: 0,
      turnStartScore: null,
    )).toList();

    return GameState(
      gameId: game.gameId,
      gameType: game.gameType,
      competitors: competitorStates,
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: game.isComplete ?? false,
      winnerCompetitorId: game.winnerCompetitorId,
      status: GameEngineStatus.initialized,
      turnActive: false,
      legsToWin: (game.config is X01GameConfig)
          ? (game.config as X01GameConfig).legsToWin
          : 1,
      currentLegIndex: 0,
      inStrategy: inStrategy,
      outStrategy: outStrategy,
      startingScore: startingScore,
    );
  }
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
    @Default(false) bool isIn,
    @Default(0) int legsWon,
    int? turnStartScore, // Null means same as score
    @Default(<String, int>{}) Map<String, int> marksPerNumber,
    int? closeOrder,
  }) = _CompetitorState;

  factory CompetitorState.fromJson(Map<String, dynamic> json) => _$CompetitorStateFromJson(json);
}