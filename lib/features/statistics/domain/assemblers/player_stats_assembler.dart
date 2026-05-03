// PlayerStatsAssembler
// Pure-Dart projection-replay layer shared between repository backends.
//
// Takes already-loaded events and metadata; returns a PlayerStats snapshot.
// Owns:
//   - projection runner wiring (X01 / cricket / practice)
//   - DartCorrected replay handling
//   - snapshot → PlayerStats mapping
//
// Does NOT own:
//   - loading events / counting darts / listing games (platform repo job)
//   - leg-limit event trimming (caller passes already-trimmed events)
//   - reactivity / streams (platform repo job)

import 'dart:math' show min;

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_best_game_hit_rate_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_best_leg_mpt_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_hit_rate_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_legs_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_mark_buckets_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_marks_per_turn_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_win_rate_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_runner.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_average_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_avg_checkout_score_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_best_game_checkout_percentage_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_best_leg_ppr_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_bust_rate_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_checkout_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_darts_per_leg_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_double_out_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_first_dart_in_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_first_nine_ppr_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_high_score_buckets_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_highest_checkout_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_highest_turn_score_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_legs_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_win_rate_projection.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';

class PlayerStatsAssembler {
  const PlayerStatsAssembler();

  static const Set<GameType> _practiceGameTypes = {
    GameType.aroundTheClock,
    GameType.bobs27,
    GameType.shanghai,
    GameType.catch40,
    GameType.checkoutPractice,
  };

  /// Builds a PlayerStats snapshot from events the caller has already
  /// loaded, filtered to the player's completed games of [gameType], and
  /// (if applicable) leg-limit-trimmed.
  ///
  /// [inStrategy] / [outStrategy] / [atcVariant] are extracted by the
  /// caller from the latest game's config. The assembler does no JSON
  /// parsing.
  PlayerStats fromEvents({
    required String playerId,
    required GameType gameType,
    required List<GameEvent> events,
    required int totalGames,
    required int totalDartsThrown,
    String inStrategy = 'straight',
    String outStrategy = 'double',
    String atcVariant = 'standard',
  }) {
    if (_practiceGameTypes.contains(gameType)) {
      return _buildPracticeStats(
        playerId: playerId,
        gameType: gameType,
        events: events,
        totalGames: totalGames,
        totalDartsThrown: totalDartsThrown,
        atcVariant: atcVariant,
      );
    }

    final isCricket = gameType == GameType.cricket;
    final context = ProjectionContext(
      playerId: playerId,
      gameType: gameType,
      inStrategy: inStrategy,
      outStrategy: outStrategy,
      playerIds: [playerId],
    );

    final runner = isCricket
        ? ProjectionRunner([
            CricketMarksPerTurnProjection(),
            CricketHitRateProjection(),
            CricketMarkBucketsProjection(),
            CricketLegsProjection(),
            CricketWinRateProjection(),
            CricketBestLegMptProjection(),
            CricketBestGameHitRateProjection(),
          ])
        : ProjectionRunner([
            X01AverageProjection(),
            X01BustRateProjection(),
            X01CheckoutProjection(),
            X01DartsPerLegProjection(),
            X01DoubleOutProjection(),
            X01FirstDartInProjection(),
            X01HighestCheckoutProjection(),
            X01HighestTurnScoreProjection(),
            X01LegsProjection(),
            X01WinRateProjection(),
            X01HighScoreBucketsProjection(),
            X01FirstNinePprProjection(),
            X01BestLegPprProjection(),
            X01AvgCheckoutScoreProjection(),
            X01BestGameCheckoutPercentageProjection(),
          ]);

    runner.init(context);
    runner.run(events);

    // Replay from the earliest DartCorrected if any are present.
    final correctedEvents =
        events.where((e) => e.eventType == 'DartCorrected').toList();
    if (correctedEvents.isNotEmpty) {
      final minSeq = correctedEvents.map((e) => e.localSequence).reduce(min);
      runner.replayFrom(events, minSeq);
    }

    final snap = runner.snapshot();

    if (isCricket) {
      final mptSnap = snap['cricket.mpt'] ?? {};
      final hitRateSnap = snap['cricket.hitRate'] ?? {};
      final bucketsSnap = snap['cricket.markBuckets'] ?? {};
      final legsSnap = snap['cricket.legs'] ?? {};
      final winSnap = snap['cricket.winRate'] ?? {};
      final bestLegMptSnap = snap['cricket.bestLegMpt'] ?? {};
      final bestGameHitRateSnap = snap['cricket.bestGameHitRate'] ?? {};

      return PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: totalGames,
        totalDartsThrown: totalDartsThrown,
        threeDartAverage: 0.0,
        bustRate: 0.0,
        highestTurnScore: 0,
        dartsPerLeg: 0.0,
        winRate: (winSnap['winRate'] as num?)?.toDouble() ?? 0.0,
        gamesWon: winSnap['gamesWon'] as int? ?? 0,
        legsPlayed: legsSnap['legsPlayed'] as int? ?? 0,
        legsWon: legsSnap['legsWon'] as int? ?? 0,
        marksPerTurn: (mptSnap['marksPerTurn'] as num?)?.toDouble(),
        hitRate: (hitRateSnap['hitRate'] as num?)?.toDouble(),
        sixMarkTurns: bucketsSnap['sixMarkTurns'] as int? ?? 0,
        nineMarkTurns: bucketsSnap['nineMarkTurns'] as int? ?? 0,
        bestLegMpt: (bestLegMptSnap['bestLegMpt'] as num?)?.toDouble(),
        bestGameHitRate:
            (bestGameHitRateSnap['bestGameHitRate'] as num?)?.toDouble(),
      );
    }

    final avgSnap = snap['x01_average'] ?? {};
    final bustSnap = snap['x01_bust_rate'] ?? {};
    final checkoutSnap = snap['x01_checkout'] ?? {};
    final dartsPerLegSnap = snap['x01.dartsPerLeg'] ?? {};
    final highestCheckoutSnap = snap['x01_highest_checkout'] ?? {};
    final highestTurnSnap = snap['x01_highest_turn_score'] ?? {};
    final winSnap = snap['x01.winRate'] ?? {};
    final legsSnap = snap['x01.legs'] ?? {};
    final bucketsSnap = snap['x01.highScoreBuckets'] ?? {};
    final firstNineSnap = snap['x01.firstNinePpr'] ?? {};
    final bestLegPprSnap = snap['x01.bestLegPpr'] ?? {};
    final avgCheckoutSnap = snap['x01.avgCheckoutScore'] ?? {};
    final bestGameCoSnap = snap['x01.bestGameCheckoutPercentage'] ?? {};

    return PlayerStats(
      playerId: playerId,
      gameType: gameType,
      totalGames: totalGames,
      totalDartsThrown: totalDartsThrown,
      threeDartAverage: (avgSnap['threeDartAverage'] as num?)?.toDouble() ?? 0.0,
      bustRate: (bustSnap['bustRate'] as num?)?.toDouble() ?? 0.0,
      checkoutPercentage:
          (checkoutSnap['checkoutPercentage'] as num?)?.toDouble(),
      highestCheckout: highestCheckoutSnap['highestCheckout'] as int?,
      highestTurnScore: highestTurnSnap['highestTurnScore'] as int? ?? 0,
      dartsPerLeg: (dartsPerLegSnap['dartsPerLeg'] as num?)?.toDouble() ?? 0.0,
      winRate: (winSnap['winRate'] as num?)?.toDouble() ?? 0.0,
      gamesWon: winSnap['gamesWon'] as int? ?? 0,
      legsPlayed: legsSnap['legsPlayed'] as int? ?? 0,
      legsWon: legsSnap['legsWon'] as int? ?? 0,
      sixtyPlusTurns: bucketsSnap['sixtyPlusTurns'] as int? ?? 0,
      oneHundredPlusTurns: bucketsSnap['oneHundredPlusTurns'] as int? ?? 0,
      oneFortyPlusTurns: bucketsSnap['oneFortyPlusTurns'] as int? ?? 0,
      oneEightyTurns: bucketsSnap['oneEightyTurns'] as int? ?? 0,
      firstNinePpr: (firstNineSnap['firstNinePpr'] as num?)?.toDouble(),
      bestLegPpr: (bestLegPprSnap['bestLegPpr'] as num?)?.toDouble(),
      bestFirstNinePpr:
          (bestLegPprSnap['bestFirstNinePpr'] as num?)?.toDouble(),
      avgCheckoutScore:
          (avgCheckoutSnap['avgCheckoutScore'] as num?)?.toDouble(),
      bestGameCheckoutPercentage:
          (bestGameCoSnap['bestGameCheckoutPercentage'] as num?)?.toDouble(),
    );
  }

  // ── Practice statistics ────────────────────────────────────────────────────

  PlayerStats _buildPracticeStats({
    required String playerId,
    required GameType gameType,
    required List<GameEvent> events,
    required int totalGames,
    required int totalDartsThrown,
    required String atcVariant,
  }) {
    return switch (gameType) {
      GameType.aroundTheClock => _computeAtcStats(
          playerId, events, totalGames, totalDartsThrown, atcVariant),
      GameType.bobs27 =>
        _computeBobs27Stats(playerId, events, totalGames, totalDartsThrown),
      GameType.shanghai =>
        _computeShanghaiStats(playerId, events, totalGames, totalDartsThrown),
      GameType.catch40 =>
        _computeCatch40Stats(playerId, events, totalGames, totalDartsThrown),
      GameType.checkoutPractice =>
        _computeCheckoutStats(playerId, events, totalGames, totalDartsThrown),
      _ => throw ArgumentError('Not a practice game type: $gameType'),
    };
  }

  PlayerStats _emptyPracticeStats(
          String playerId, GameType gameType, int totalGames) =>
      PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: totalGames,
        gamesWon: 0,
        winRate: 0.0,
        threeDartAverage: 0.0,
        highestTurnScore: 0,
        totalDartsThrown: 0,
        dartsPerLeg: 0.0,
        bustRate: 0.0,
      );

  PlayerStats _computeAtcStats(
    String playerId,
    List<GameEvent> events,
    int totalGames,
    int totalDartsThrown,
    String variant,
  ) {
    int totalDartsAtTargets = 0;
    int totalHits = 0;
    int completions = 0;
    int totalTurnsForCompletions = 0;
    int? bestTurns;
    final Map<int, int> segHits = {};
    final Map<int, int> segAttempts = {};

    int currentTarget = 1;
    int gameTurns = 0;
    bool inPlayerTurn = false;

    for (final event in events) {
      switch (event.eventType) {
        case 'TurnStarted':
          inPlayerTurn = true;
          gameTurns++;
        case 'DartThrown':
          if (!inPlayerTurn) break;
          final seg = (event.payload['segment'] as num?)?.toInt() ?? 0;
          final mult = (event.payload['multiplier'] as num?)?.toInt() ?? 1;
          if (currentTarget <= 20) {
            totalDartsAtTargets++;
            segAttempts[currentTarget] = (segAttempts[currentTarget] ?? 0) + 1;
            final hit = variant == 'doublesOnly'
                ? (seg == currentTarget && mult == 2)
                : (seg == currentTarget);
            if (hit) {
              totalHits++;
              segHits[currentTarget] = (segHits[currentTarget] ?? 0) + 1;
              currentTarget++;
            }
          }
        case 'TurnEnded':
          inPlayerTurn = false;
        case 'LegCompleted':
          if (currentTarget > 20) {
            completions++;
            totalTurnsForCompletions += gameTurns;
            if (bestTurns == null || gameTurns < bestTurns) {
              bestTurns = gameTurns;
            }
          }
          currentTarget = 1;
          gameTurns = 0;
          inPlayerTurn = false;
        case 'GameCompleted':
          // ATC is a 1-leg practice game: GameCompleted signals drill completion
          // (LegCompleted is never emitted when legsToWin==1).
          if (currentTarget > 20) {
            completions++;
            totalTurnsForCompletions += gameTurns;
            if (bestTurns == null || gameTurns < bestTurns) {
              bestTurns = gameTurns;
            }
          }
          currentTarget = 1;
          gameTurns = 0;
          inPlayerTurn = false;
      }
    }

    final hitRate =
        totalDartsAtTargets > 0 ? totalHits / totalDartsAtTargets : null;
    final avgTurns =
        completions > 0 ? totalTurnsForCompletions / completions : null;

    return _emptyPracticeStats(playerId, GameType.aroundTheClock, totalGames)
        .copyWith(
      totalDartsThrown: totalDartsThrown,
      atcCompletions: completions,
      atcHitRate: hitRate,
      atcAvgTurns: avgTurns,
      atcBestTurns: bestTurns,
      atcSegmentHits: segHits,
      atcSegmentAttempts: segAttempts,
    );
  }

  PlayerStats _computeBobs27Stats(
    String playerId,
    List<GameEvent> events,
    int totalGames,
    int totalDartsThrown,
  ) {
    int totalScore = 0;
    int? bestScore;
    int completedGames = 0;
    int successfulCompletions = 0;
    int doubleAttempts = 0;
    int doubleHits = 0;

    int currentRound = 1;
    int currentScore = 27;
    int turnDoubleHits = 0;
    bool inPlayerTurn = false;

    for (final event in events) {
      final epid = event.payload['player_id'] as String?;
      switch (event.eventType) {
        case 'TurnStarted':
          if (epid != playerId) break;
          inPlayerTurn = true;
          turnDoubleHits = 0;
        case 'DartThrown':
          if (!inPlayerTurn || epid != playerId) break;
          final seg = (event.payload['segment'] as num?)?.toInt() ?? 0;
          final mult = (event.payload['multiplier'] as num?)?.toInt() ?? 1;
          if (mult == 2) {
            doubleAttempts++;
            if (seg == currentRound) {
              doubleHits++;
              turnDoubleHits++;
            }
          }
        case 'TurnEnded':
          if (!inPlayerTurn || epid != playerId) break;
          inPlayerTurn = false;
          if (turnDoubleHits > 0) {
            currentScore += turnDoubleHits * currentRound * 2;
          } else {
            currentScore -= currentRound * 2;
          }
          currentRound++;
        case 'LegCompleted':
          completedGames++;
          if (currentScore > 0) {
            successfulCompletions++;
            totalScore += currentScore;
            if (bestScore == null || currentScore > bestScore) {
              bestScore = currentScore;
            }
          }
          currentRound = 1;
          currentScore = 27;
          inPlayerTurn = false;
        case 'GameCompleted':
          currentRound = 1;
          currentScore = 27;
          inPlayerTurn = false;
      }
    }

    final avgScore =
        successfulCompletions > 0 ? totalScore / successfulCompletions : null;
    final completionRate =
        completedGames > 0 ? successfulCompletions / completedGames : null;
    final doubleHitRate =
        doubleAttempts > 0 ? doubleHits / doubleAttempts : null;

    return _emptyPracticeStats(playerId, GameType.bobs27, totalGames).copyWith(
      totalDartsThrown: totalDartsThrown,
      bobs27AvgScore: avgScore,
      bobs27BestScore: bestScore,
      bobs27CompletionRate: completionRate,
      bobs27DoubleHitRate: doubleHitRate,
    );
  }

  PlayerStats _computeShanghaiStats(
    String playerId,
    List<GameEvent> events,
    int totalGames,
    int totalDartsThrown,
  ) {
    int shanghaiCount = 0;
    int scoreAcc = 0;
    int gamesCompleted = 0;
    int totalScore = 0;
    int? bestScore;

    int currentRound = 1;
    bool inPlayerTurn = false;
    final Set<int> turnMultipliers = {};

    for (final event in events) {
      final epid = event.payload['player_id'] as String?;
      switch (event.eventType) {
        case 'TurnStarted':
          if (epid != playerId) break;
          inPlayerTurn = true;
          turnMultipliers.clear();
        case 'DartThrown':
          if (epid != playerId) break;
          final score = (event.payload['score'] as num?)?.toInt() ?? 0;
          scoreAcc += score;
          if (inPlayerTurn) {
            final seg = (event.payload['segment'] as num?)?.toInt() ?? 0;
            final mult = (event.payload['multiplier'] as num?)?.toInt() ?? 1;
            if (seg == currentRound) turnMultipliers.add(mult);
          }
        case 'TurnEnded':
          if (!inPlayerTurn || epid != playerId) break;
          inPlayerTurn = false;
          if (turnMultipliers.containsAll({1, 2, 3})) shanghaiCount++;
          currentRound++;
        case 'LegCompleted':
          gamesCompleted++;
          totalScore += scoreAcc;
          if (bestScore == null || scoreAcc > bestScore) bestScore = scoreAcc;
          scoreAcc = 0;
          currentRound = 1;
          inPlayerTurn = false;
        case 'GameCompleted':
          scoreAcc = 0;
          currentRound = 1;
          inPlayerTurn = false;
      }
    }

    final avgScore = gamesCompleted > 0 ? totalScore / gamesCompleted : null;

    return _emptyPracticeStats(playerId, GameType.shanghai, totalGames)
        .copyWith(
      totalDartsThrown: totalDartsThrown,
      shanghaiAvgScore: avgScore,
      shanghaiBestScore: bestScore,
      shanghaiCount: shanghaiCount,
    );
  }

  PlayerStats _computeCatch40Stats(
    String playerId,
    List<GameEvent> events,
    int totalGames,
    int totalDartsThrown,
  ) {
    int totalScore = 0;
    int? bestScore;
    int gamesCompleted = 0;
    int twoDart = 0;
    int threeDart = 0;
    int fourSixDart = 0;
    int failed = 0;

    int gameScore = 0;
    int turnDarts = 0;
    bool inPlayerTurn = false;

    for (final event in events) {
      final epid = event.payload['player_id'] as String?;
      switch (event.eventType) {
        case 'TurnStarted':
          if (epid != playerId) break;
          inPlayerTurn = true;
          turnDarts = 0;
        case 'DartThrown':
          if (!inPlayerTurn || epid != playerId) break;
          final score = (event.payload['score'] as num?)?.toInt() ?? 0;
          gameScore += score;
          turnDarts++;
        case 'TurnEnded':
          if (!inPlayerTurn || epid != playerId) break;
          inPlayerTurn = false;
          final reason = event.payload['reason'] as String?;
          if (reason == 'checkout') {
            if (turnDarts == 2) {
              twoDart++;
            } else if (turnDarts == 3) {
              threeDart++;
            } else if (turnDarts >= 4 && turnDarts <= 6) {
              fourSixDart++;
            }
          } else if (reason == 'failed') {
            failed++;
          }
        case 'LegCompleted':
          gamesCompleted++;
          totalScore += gameScore;
          if (bestScore == null || gameScore > bestScore) bestScore = gameScore;
          gameScore = 0;
          inPlayerTurn = false;
        case 'GameCompleted':
          gameScore = 0;
          inPlayerTurn = false;
      }
    }

    final avgScore = gamesCompleted > 0 ? totalScore / gamesCompleted : null;

    return _emptyPracticeStats(playerId, GameType.catch40, totalGames)
        .copyWith(
      totalDartsThrown: totalDartsThrown,
      catch40AvgScore: avgScore,
      catch40BestScore: bestScore,
      catch40TwoDartCheckouts: twoDart,
      catch40ThreeDartCheckouts: threeDart,
      catch40FourSixDartCheckouts: fourSixDart,
      catch40FailedCheckouts: failed,
    );
  }

  PlayerStats _computeCheckoutStats(
    String playerId,
    List<GameEvent> events,
    int totalGames,
    int totalDartsThrown,
  ) {
    int attempts = 0;
    int successes = 0;

    for (final event in events) {
      final epid = event.payload['player_id'] as String?;
      if (epid != playerId) continue;
      switch (event.eventType) {
        case 'TurnEnded':
          attempts++;
          final reason = event.payload['reason'] as String?;
          if (reason == 'checkout') successes++;
        default:
          break;
      }
    }

    final successRate = attempts > 0 ? successes / attempts : null;

    return _emptyPracticeStats(playerId, GameType.checkoutPractice, totalGames)
        .copyWith(
      totalDartsThrown: totalDartsThrown,
      checkoutAttempts: attempts,
      checkoutSuccesses: successes,
      checkoutSuccessRate: successRate,
    );
  }
}
