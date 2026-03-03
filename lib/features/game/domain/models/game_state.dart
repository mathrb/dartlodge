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
    @Default('standard') String cricketVariant,
    @Default('standard') String aroundTheClockVariant,
    @Default(7) int shanghaiTotalRounds,
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
    String cricketVariant = 'standard';
    String aroundTheClockVariant = 'standard';
    int shanghaiTotalRounds = 7;

    if (game.config is X01GameConfig) {
      final x01Config = game.config as X01GameConfig;
      startingScore = x01Config.startingScore;
      inStrategy = x01Config.inStrategy;
      outStrategy = x01Config.outStrategy;
    } else if (game.config is CricketGameConfig) {
      startingScore = 0;
      cricketVariant = (game.config as CricketGameConfig).variant;
    } else if (game.config is AroundTheClockGameConfig) {
      startingScore = 0;
      aroundTheClockVariant = (game.config as AroundTheClockGameConfig).variant;
    } else if (game.config is ShanghaiGameConfig) {
      startingScore = 0;
      shanghaiTotalRounds = (game.config as ShanghaiGameConfig).totalRounds;
    } else if (game.config is Bobs27GameConfig) {
      startingScore = 27;
    } else {
      startingScore = 0;
    }

    // Per-competitor initial target depends on game type
    int? initialTarget;
    if (game.config is AroundTheClockGameConfig) {
      initialTarget = aroundTheClockVariant == 'reverse' ? 20 : 1;
    } else if (game.config is CheckoutPracticeGameConfig) {
      initialTarget = 170;
    }

    // Convert competitors to competitor states
    final competitorStates = competitors.map((competitor) => CompetitorState(
      competitorId: competitor.competitorId,
      name: competitor.name,
      playerIds: competitor.players.map((player) => player.playerId).toList(),
      score: startingScore,
      isComplete: false,
      dartThrows: const [],
      isIn: false,
      legsWon: 0,
      turnStartScore: null,
      currentTarget: initialTarget,
      practiceRound: 1,
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
      cricketVariant: cricketVariant,
      aroundTheClockVariant: aroundTheClockVariant,
      shanghaiTotalRounds: shanghaiTotalRounds,
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
    int? currentTarget,
    @Default(1) int practiceRound,
    @Default(0) int practiceAttempts,
    @Default(0) int practiceSuccesses,
  }) = _CompetitorState;

  factory CompetitorState.fromJson(Map<String, dynamic> json) => _$CompetitorStateFromJson(json);
}