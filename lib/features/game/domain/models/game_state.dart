import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/checkout_target.dart';
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
    @Default(1) int currentRoundInLeg,
    int? x01TotalRounds,
    int? cricketTotalRounds,
    @Default('straight') String inStrategy,
    @Default('double') String outStrategy,
    @Default(501) int startingScore,
    @Default('standard') String cricketScoring,
    @Default('fixed') String cricketTargetMode,
    @Default(<int>[15, 16, 17, 18, 19, 20]) List<int> cricketTargets,
    @Default(<int>{}) Set<int> cricketLockedTargets,
    @Default('standard') String aroundTheClockVariant,
    @Default(7) int shanghaiTotalRounds,
    @Default(0) int catch40TargetRemaining,
    @Default(0) int catch40DartsOnTarget,
    int? checkoutTargetSuccesses,
    // Checkout-Practice target mode (#636): how each run's checkout target is
    // chosen. Mirrors CheckoutPracticeGameConfig; read by the engine + stats
    // via checkoutTargetForRun. Defaults reproduce the legacy fixed-170 drill.
    @Default('fixed') String checkoutTargetMode,
    @Default(170) int checkoutFixedTarget,
    @Default(40) int checkoutMinTarget,
    @Default(170) int checkoutMaxTarget,
    @Default(10) int checkoutProgressionStep,
    int? countUpTotalRounds,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);

  /// Creates an initial GameState from a Game and its competitors.
  /// Used for state reconstruction from events.
  ///
  /// Configuration extraction uses `GameConfig.maybeMap(...)` (per CLAUDE.md
  /// "Key Rules"); the `orElse` branch covers config variants without
  /// game-specific state (Killer/Baseball/Golf/Scram/HalveIt/HighScore and
  /// the Blind* set), all of which start scoreless with default flags.
  factory GameState.initial(Game game, List<Competitor> competitors) {
    final config = game.config;

    // Bundle of per-config initial values. Every field has a safe default so
    // the `orElse` branch (unhandled variants) doesn't have to repeat them.
    final init = config.maybeMap(
      x01: (c) => _GameStateInit(
        startingScore: c.startingScore,
        inStrategy: c.inStrategy,
        outStrategy: c.outStrategy,
        legsToWin: c.legsToWin,
        x01TotalRounds: c.totalRounds,
        handicaps: c.handicaps,
      ),
      cricket: (c) => _GameStateInit(
        startingScore: 0,
        cricketScoring: c.scoring,
        cricketTargetMode: c.targetMode,
        legsToWin: c.legsToWin,
        cricketTotalRounds: c.totalRounds,
      ),
      aroundTheClock: (c) => _GameStateInit(
        startingScore: 0,
        aroundTheClockVariant: c.variant,
        initialTarget: c.variant == 'reverse' ? 20 : 1,
      ),
      shanghai: (c) => _GameStateInit(
        startingScore: 0,
        shanghaiTotalRounds: c.totalRounds,
      ),
      catch40: (c) => const _GameStateInit(
        startingScore: 0,
        catch40TargetRemaining: 61, // First target is 61
      ),
      bobs27: (c) => const _GameStateInit(startingScore: 27),
      checkoutPractice: (c) => _GameStateInit(
        // First run's target FROM which the player checks out (runIndex 0).
        // Subsequent runs are resolved by the engine via checkoutTargetForRun
        // off the run-start TurnStarted's `from_score` stamp (#636).
        startingScore: checkoutTargetForRun(
          mode: c.targetMode,
          fixedTarget: c.fixedTarget,
          minTarget: c.minTarget,
          maxTarget: c.maxTarget,
          step: c.progressionStep,
          gameId: game.gameId,
          runIndex: 0,
        ),
        checkoutTargetSuccesses: c.targetSuccesses,
        checkoutTargetMode: c.targetMode,
        checkoutFixedTarget: c.fixedTarget,
        checkoutMinTarget: c.minTarget,
        checkoutMaxTarget: c.maxTarget,
        checkoutProgressionStep: c.progressionStep,
      ),
      countUp: (c) => _GameStateInit(
        startingScore: 0,
        handicaps: c.handicaps,
        countUpTotalRounds: c.totalRounds,
      ),
      orElse: () => const _GameStateInit(startingScore: 0),
    );

    // Convert competitors to competitor states.
    final competitorStates = competitors.map((competitor) {
      final effectiveStart =
          init.startingScore + (init.handicaps[competitor.competitorId] ?? 0);
      return CompetitorState(
        competitorId: competitor.competitorId,
        name: competitor.name,
        playerIds: competitor.players.map((player) => player.playerId).toList(),
        score: effectiveStart,
        startingScore: effectiveStart,
        isComplete: false,
        dartThrows: const [],
        isIn: false,
        legsWon: 0,
        turnStartScore: null,
        currentTarget: init.initialTarget,
        practiceRound: 1,
      );
    }).toList();

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
      legsToWin: init.legsToWin,
      x01TotalRounds: init.x01TotalRounds,
      cricketTotalRounds: init.cricketTotalRounds,
      currentLegIndex: 0,
      inStrategy: init.inStrategy,
      outStrategy: init.outStrategy,
      startingScore: init.startingScore,
      cricketScoring: init.cricketScoring,
      cricketTargetMode: init.cricketTargetMode,
      // Issue #236: only `fixed` is populated; random/crazy seed targets via
      // their respective events (CricketTargetsAssigned / CrazyTargetsRolled).
      cricketTargets: init.cricketTargetMode == 'fixed'
          ? const <int>[15, 16, 17, 18, 19, 20]
          : const <int>[],
      cricketLockedTargets: const <int>{},
      aroundTheClockVariant: init.aroundTheClockVariant,
      shanghaiTotalRounds: init.shanghaiTotalRounds,
      catch40TargetRemaining: init.catch40TargetRemaining,
      catch40DartsOnTarget: 0,
      checkoutTargetSuccesses: init.checkoutTargetSuccesses,
      checkoutTargetMode: init.checkoutTargetMode,
      checkoutFixedTarget: init.checkoutFixedTarget,
      checkoutMinTarget: init.checkoutMinTarget,
      checkoutMaxTarget: init.checkoutMaxTarget,
      checkoutProgressionStep: init.checkoutProgressionStep,
      countUpTotalRounds: init.countUpTotalRounds,
    );
  }
}

/// Internal scratchpad collecting per-config initialisers for `GameState.initial`.
/// Kept private to this file — it is purely a code-organisation aid and never
/// crosses the file boundary.
class _GameStateInit {
  final int startingScore;
  final String inStrategy;
  final String outStrategy;
  final int legsToWin;
  final int? x01TotalRounds;
  final int? cricketTotalRounds;
  final String cricketScoring;
  final String cricketTargetMode;
  final String aroundTheClockVariant;
  final int shanghaiTotalRounds;
  final int catch40TargetRemaining;
  final int? checkoutTargetSuccesses;
  final String checkoutTargetMode;
  final int checkoutFixedTarget;
  final int checkoutMinTarget;
  final int checkoutMaxTarget;
  final int checkoutProgressionStep;
  final int? countUpTotalRounds;
  final int? initialTarget;
  final Map<String, int> handicaps;

  const _GameStateInit({
    required this.startingScore,
    this.inStrategy = 'straight',
    this.outStrategy = 'straight',
    this.legsToWin = 1,
    this.x01TotalRounds,
    this.cricketTotalRounds,
    this.cricketScoring = 'standard',
    this.cricketTargetMode = 'fixed',
    this.aroundTheClockVariant = 'standard',
    this.shanghaiTotalRounds = 7,
    this.catch40TargetRemaining = 0,
    this.checkoutTargetSuccesses,
    this.checkoutTargetMode = 'fixed',
    this.checkoutFixedTarget = 170,
    this.checkoutMinTarget = 40,
    this.checkoutMaxTarget = 170,
    this.checkoutProgressionStep = 10,
    this.countUpTotalRounds,
    this.initialTarget,
    this.handicaps = const {},
  });
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
    @Default(0) int startingScore,
  }) = _CompetitorState;

  factory CompetitorState.fromJson(Map<String, dynamic> json) => _$CompetitorStateFromJson(json);
}