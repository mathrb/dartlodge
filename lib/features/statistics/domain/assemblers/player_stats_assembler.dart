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
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';
import 'package:dart_lodge/features/statistics/domain/engines/count_up/count_up_average_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/count_up/count_up_first_nine_ppr_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/count_up/count_up_high_score_buckets_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_best_game_hit_rate_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_first_nine_mpr_projection.dart';
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
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
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
    Set<String> soloGameIds = const {},
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
    final isCountUp = gameType == GameType.countUp;
    final context = ProjectionContext(
      playerId: playerId,
      gameType: gameType,
      inStrategy: inStrategy,
      outStrategy: outStrategy,
      playerIds: [playerId],
      soloGameIds: soloGameIds,
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
        : isCountUp
            ? ProjectionRunner([
                CountUpAverageProjection(),
                CountUpFirstNinePprProjection(),
                CountUpHighScoreBucketsProjection(),
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

    if (isCountUp) {
      final avgSnap = snap['count_up.average'] ?? {};
      final firstNineSnap = snap['count_up.firstNineAverage'] ?? {};
      final bucketsSnap = snap['count_up.highScoreBuckets'] ?? {};

      return PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: totalGames,
        totalDartsThrown: totalDartsThrown,
        threeDartAverage:
            (avgSnap['threeDartAverage'] as num?)?.toDouble() ?? 0.0,
        bustRate: 0.0,
        highestTurnScore: 0,
        dartsPerLeg: 0.0,
        winRate: 0.0,
        gamesWon: 0,
        legsPlayed: 0,
        legsWon: 0,
        firstNinePpr: (firstNineSnap['firstNinePpr'] as num?)?.toDouble(),
        sixtyPlusTurns: bucketsSnap['sixtyPlusTurns'] as int? ?? 0,
        oneHundredPlusTurns: bucketsSnap['oneHundredPlusTurns'] as int? ?? 0,
        oneFortyPlusTurns: bucketsSnap['oneFortyPlusTurns'] as int? ?? 0,
        oneEightyTurns: bucketsSnap['oneEightyTurns'] as int? ?? 0,
      );
    }

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

  // ── Per-game stats ─────────────────────────────────────────────────────────

  /// Builds a GameStats snapshot from one game's events + dart throws.
  ///
  /// [throws] is a flat list of dart throws across all competitors and
  /// players in the game. The assembler groups them itself.
  /// [competitorNames] maps competitorId → display name (for output only).
  GameStats gameStatsFromEvents({
    required String gameId,
    required GameType gameType,
    required List<({String competitorId, String playerId, int score})> throws,
    required Map<String, String> competitorNames,
    required List<GameEvent> events,
  }) {
    if (throws.isEmpty) {
      return GameStats(
        gameId: gameId,
        byCompetitor: const [],
        gameType: gameType.name,
      );
    }

    // Group throws by competitor → by player.
    final Map<String, Map<String, List<int>>> byCompetitor = {};
    for (final t in throws) {
      byCompetitor
          .putIfAbsent(t.competitorId, () => {})
          .putIfAbsent(t.playerId, () => [])
          .add(t.score);
    }

    final isX01 = gameType == GameType.x01;
    final isCricket = gameType == GameType.cricket;
    final isCountUp = gameType == GameType.countUp;

    final List<CompetitorStats> competitorStats = [];
    for (final entry in byCompetitor.entries) {
      final competitorId = entry.key;
      final competitorName = competitorNames[competitorId];
      if (competitorName == null) continue;

      final byPlayer = entry.value;
      final List<PlayerTurnStats> playerTurnStats = [];
      int competitorDarts = 0;
      int competitorScore = 0;
      for (final playerEntry in byPlayer.entries) {
        final playerId = playerEntry.key;
        final playerScores = playerEntry.value;
        final playerDarts = playerScores.length;
        final playerTotal =
            playerScores.fold<int>(0, (sum, s) => sum + s);
        final playerAvg =
            playerDarts > 0 ? (playerTotal / playerDarts) * 3 : 0.0;
        playerTurnStats.add(PlayerTurnStats(
          playerId: playerId,
          threeDartAverage: playerAvg,
          dartsThrown: playerDarts,
        ));
        competitorDarts += playerDarts;
        competitorScore += playerTotal;
      }
      final competitorAvg =
          competitorDarts > 0 ? (competitorScore / competitorDarts) * 3 : 0.0;

      // Legs won — count LegCompleted events with this competitor as winner.
      final legsWon = events.where((e) {
        if (e.eventType != 'LegCompleted') return false;
        return e.payload['winner_competitor_id'] == competitorId;
      }).length;

      // Per-player projection aggregates.
      int totalOneEighty = 0,
          totalSixtyPlus = 0,
          totalHundredPlus = 0,
          totalFortyPlus = 0;
      int totalCheckoutAttempts = 0, totalSuccessfulCheckouts = 0;
      int? competitorHighestCheckout;
      int totalMarks = 0, totalTurns = 0;
      int firstNineMarksTotal = 0, firstNineLegsTotal = 0;
      int cricketFiveMark = 0,
          cricketSixMark = 0,
          cricketSevenMark = 0,
          cricketEightMark = 0,
          cricketNineMark = 0;

      final playerIds = byPlayer.keys.toList();

      if (isX01) {
        for (final playerId in playerIds) {
          final runner = ProjectionRunner([
            X01CheckoutProjection(),
            X01HighScoreBucketsProjection(),
            X01HighestCheckoutProjection(),
          ]);
          runner.init(ProjectionContext(
            playerId: playerId,
            gameType: GameType.x01,
            inStrategy: 'straight',
            outStrategy: 'double',
            playerIds: playerIds,
          ));
          runner.run(events);
          final snap = runner.snapshot();

          final buckets = snap['x01.highScoreBuckets'] ?? {};
          totalOneEighty += (buckets['oneEightyTurns'] as int? ?? 0);
          totalFortyPlus += (buckets['oneFortyPlusTurns'] as int? ?? 0);
          totalHundredPlus += (buckets['oneHundredPlusTurns'] as int? ?? 0);
          totalSixtyPlus += (buckets['sixtyPlusTurns'] as int? ?? 0);

          final checkout = snap['x01_checkout'] ?? {};
          totalCheckoutAttempts += (checkout['checkoutAttempts'] as int? ?? 0);
          totalSuccessfulCheckouts +=
              (checkout['successfulCheckouts'] as int? ?? 0);

          final hcSnap = snap['x01_highest_checkout'] ?? {};
          final hc = hcSnap['highestCheckout'] as int?;
          if (hc != null &&
              (competitorHighestCheckout == null ||
                  hc > competitorHighestCheckout)) {
            competitorHighestCheckout = hc;
          }
        }
      } else if (isCountUp) {
        for (final playerId in playerIds) {
          final runner = ProjectionRunner([
            CountUpHighScoreBucketsProjection(),
          ]);
          runner.init(ProjectionContext(
            playerId: playerId,
            gameType: GameType.countUp,
            inStrategy: 'straight',
            outStrategy: 'straight',
            playerIds: playerIds,
          ));
          runner.run(events);
          final snap = runner.snapshot();

          final buckets = snap['count_up.highScoreBuckets'] ?? {};
          totalOneEighty += (buckets['oneEightyTurns'] as int? ?? 0);
          totalFortyPlus += (buckets['oneFortyPlusTurns'] as int? ?? 0);
          totalHundredPlus += (buckets['oneHundredPlusTurns'] as int? ?? 0);
          totalSixtyPlus += (buckets['sixtyPlusTurns'] as int? ?? 0);
        }
      } else if (isCricket) {
        for (final playerId in playerIds) {
          final runner = ProjectionRunner([
            CricketMarksPerTurnProjection(),
            CricketMarkBucketsProjection(),
            CricketFirstNineMprProjection(),
          ]);
          runner.init(ProjectionContext(
            playerId: playerId,
            gameType: GameType.cricket,
            inStrategy: 'straight',
            outStrategy: 'straight',
            playerIds: playerIds,
          ));
          runner.run(events);
          final snap = runner.snapshot();

          final mptSnap = snap['cricket.mpt'] ?? {};
          totalMarks += (mptSnap['totalMarks'] as int? ?? 0);
          totalTurns += (mptSnap['totalTurns'] as int? ?? 0);

          final bucketsSnap = snap['cricket.markBuckets'] ?? {};
          cricketFiveMark += (bucketsSnap['fiveMarkExact'] as int? ?? 0);
          cricketSixMark += (bucketsSnap['sixMarkExact'] as int? ?? 0);
          cricketSevenMark += (bucketsSnap['sevenMarkExact'] as int? ?? 0);
          cricketEightMark += (bucketsSnap['eightMarkExact'] as int? ?? 0);
          cricketNineMark += (bucketsSnap['nineMarkExact'] as int? ?? 0);

          final fn9Snap = snap['cricket.firstNineMpr'] ?? {};
          firstNineMarksTotal += (fn9Snap['totalFirstNineMarks'] as int? ?? 0);
          firstNineLegsTotal += (fn9Snap['totalFirstNineLegs'] as int? ?? 0);
        }
      }

      final checkoutPercentage = totalCheckoutAttempts > 0
          ? (totalSuccessfulCheckouts / totalCheckoutAttempts) * 100
          : null;
      final cricketMpr = totalTurns > 0 ? totalMarks / totalTurns : null;
      final cricketFirstNineMpr = firstNineLegsTotal > 0
          ? firstNineMarksTotal / (firstNineLegsTotal * 3)
          : null;

      competitorStats.add(CompetitorStats(
        competitorId: competitorId,
        competitorName: competitorName,
        byPlayer: playerTurnStats,
        threeDartAverage: competitorAvg,
        legsWon: legsWon,
        totalDartsThrown: competitorDarts,
        checkoutPercentage: checkoutPercentage,
        highestCheckout: competitorHighestCheckout,
        oneEightyTurns: totalOneEighty,
        sixtyPlusTurns: totalSixtyPlus,
        oneHundredPlusTurns: totalHundredPlus,
        oneFortyPlusTurns: totalFortyPlus,
        marksPerRound: cricketMpr,
        firstNineMarksPerRound: cricketFirstNineMpr,
        fiveMarkTurns: cricketFiveMark,
        sixMarkTurns: cricketSixMark,
        sevenMarkTurns: cricketSevenMark,
        eightMarkTurns: cricketEightMark,
        nineMarkTurns: cricketNineMark,
      ));
    }

    return GameStats(
      gameId: gameId,
      byCompetitor: competitorStats,
      gameType: gameType.name,
    );
  }

  // ── Per-leg competitor stats ───────────────────────────────────────────────

  /// Builds per-competitor stats for a single leg's worth of events.
  ///
  /// AVG uses [X01AverageProjection] (events-driven, bust-inclusive). The
  /// caller is responsible for slicing all-game events into per-leg windows
  /// before calling this method (see `ComputeLegStatsUseCase`).
  ///
  /// [allPlayerIds] is the full list of player IDs across the game's
  /// competitors — required by the ProjectionContext so projections can
  /// distinguish "this player" from "any player".
  LegCompetitorStats legCompetitorStatsFromEvents({
    required List<GameEvent> events,
    required Competitor competitor,
    required List<String> allPlayerIds,
    required GameType gameType,
  }) {
    final playerIds = competitor.players.map((p) => p.playerId).toList();

    var darts = 0;
    for (final e in events) {
      if (e.eventType != 'DartThrown') continue;
      if (e.payload['competitor_id'] == competitor.competitorId) darts++;
    }

    if (playerIds.isEmpty) {
      return LegCompetitorStats(
        competitorId: competitor.competitorId,
        competitorName: competitor.name,
        dartsThrown: darts,
      );
    }

    if (gameType == GameType.countUp) {
      var scoredPoints = 0;
      var scoringDarts = 0;
      var oneEighty = 0, sixtyPlus = 0, hundredPlus = 0, fortyPlus = 0;

      for (final playerId in playerIds) {
        final runner = ProjectionRunner([
          CountUpAverageProjection(),
          CountUpHighScoreBucketsProjection(),
        ]);
        runner.init(ProjectionContext(
          playerId: playerId,
          gameType: GameType.countUp,
          inStrategy: 'straight',
          outStrategy: 'straight',
          playerIds: allPlayerIds,
        ));
        runner.run(events);
        final snap = runner.snapshot();

        final avg = snap['count_up.average'] ?? const {};
        scoredPoints += (avg['totalScoredPoints'] as int? ?? 0);
        scoringDarts += (avg['totalDartsThrown'] as int? ?? 0);

        final buckets = snap['count_up.highScoreBuckets'] ?? const {};
        oneEighty += (buckets['oneEightyTurns'] as int? ?? 0);
        sixtyPlus += (buckets['sixtyPlusTurns'] as int? ?? 0);
        hundredPlus += (buckets['oneHundredPlusTurns'] as int? ?? 0);
        fortyPlus += (buckets['oneFortyPlusTurns'] as int? ?? 0);
      }

      return LegCompetitorStats(
        competitorId: competitor.competitorId,
        competitorName: competitor.name,
        dartsThrown: darts,
        threeDartAverage:
            scoringDarts > 0 ? (scoredPoints / scoringDarts) * 3 : null,
        oneEightyTurns: oneEighty,
        sixtyPlusTurns: sixtyPlus,
        oneHundredPlusTurns: hundredPlus,
        oneFortyPlusTurns: fortyPlus,
      );
    }

    if (gameType == GameType.x01) {
      var scoredPoints = 0;
      var scoringDarts = 0;
      var checkoutAttempts = 0;
      var successfulCheckouts = 0;
      int? highestCheckout;
      var oneEighty = 0, sixtyPlus = 0, hundredPlus = 0, fortyPlus = 0;

      for (final playerId in playerIds) {
        final runner = ProjectionRunner([
          X01AverageProjection(),
          X01CheckoutProjection(),
          X01HighestCheckoutProjection(),
          X01HighScoreBucketsProjection(),
        ]);
        runner.init(ProjectionContext(
          playerId: playerId,
          gameType: GameType.x01,
          inStrategy: 'straight',
          outStrategy: 'double',
          playerIds: allPlayerIds,
        ));
        runner.run(events);
        final snap = runner.snapshot();

        final avg = snap['x01_average'] ?? const {};
        scoredPoints += (avg['totalScoredPoints'] as int? ?? 0);
        scoringDarts += (avg['totalDartsThrown'] as int? ?? 0);

        final ch = snap['x01_checkout'] ?? const {};
        checkoutAttempts += (ch['checkoutAttempts'] as int? ?? 0);
        successfulCheckouts += (ch['successfulCheckouts'] as int? ?? 0);

        final hc = (snap['x01_highest_checkout'] ?? const {})['highestCheckout']
            as int?;
        if (hc != null && (highestCheckout == null || hc > highestCheckout)) {
          highestCheckout = hc;
        }

        final buckets = snap['x01.highScoreBuckets'] ?? const {};
        oneEighty += (buckets['oneEightyTurns'] as int? ?? 0);
        sixtyPlus += (buckets['sixtyPlusTurns'] as int? ?? 0);
        hundredPlus += (buckets['oneHundredPlusTurns'] as int? ?? 0);
        fortyPlus += (buckets['oneFortyPlusTurns'] as int? ?? 0);
      }

      return LegCompetitorStats(
        competitorId: competitor.competitorId,
        competitorName: competitor.name,
        dartsThrown: darts,
        threeDartAverage:
            scoringDarts > 0 ? (scoredPoints / scoringDarts) * 3 : null,
        checkoutPercentage: checkoutAttempts > 0
            ? (successfulCheckouts / checkoutAttempts) * 100
            : null,
        highestCheckout: highestCheckout,
        oneEightyTurns: oneEighty,
        sixtyPlusTurns: sixtyPlus,
        oneHundredPlusTurns: hundredPlus,
        oneFortyPlusTurns: fortyPlus,
      );
    }

    // Cricket
    var totalMarks = 0;
    var totalTurns = 0;
    var fiveMarks = 0,
        sixMarks = 0,
        sevenMarks = 0,
        eightMarks = 0,
        nineMarks = 0;
    var firstNineMarks = 0;
    var firstNineLegs = 0;

    for (final playerId in playerIds) {
      final runner = ProjectionRunner([
        CricketMarksPerTurnProjection(),
        CricketMarkBucketsProjection(),
        CricketFirstNineMprProjection(),
      ]);
      runner.init(ProjectionContext(
        playerId: playerId,
        gameType: GameType.cricket,
        inStrategy: 'straight',
        outStrategy: 'straight',
        playerIds: allPlayerIds,
      ));
      runner.run(events);
      final snap = runner.snapshot();

      final mpt = snap['cricket.mpt'] ?? const {};
      totalMarks += (mpt['totalMarks'] as int? ?? 0);
      totalTurns += (mpt['totalTurns'] as int? ?? 0);

      final buckets = snap['cricket.markBuckets'] ?? const {};
      fiveMarks += (buckets['fiveMarkExact'] as int? ?? 0);
      sixMarks += (buckets['sixMarkExact'] as int? ?? 0);
      sevenMarks += (buckets['sevenMarkExact'] as int? ?? 0);
      eightMarks += (buckets['eightMarkExact'] as int? ?? 0);
      nineMarks += (buckets['nineMarkExact'] as int? ?? 0);

      final fn9 = snap['cricket.firstNineMpr'] ?? const {};
      firstNineMarks += (fn9['totalFirstNineMarks'] as int? ?? 0);
      firstNineLegs += (fn9['totalFirstNineLegs'] as int? ?? 0);
    }

    return LegCompetitorStats(
      competitorId: competitor.competitorId,
      competitorName: competitor.name,
      dartsThrown: darts,
      marksPerRound: totalTurns > 0 ? totalMarks / totalTurns : null,
      firstNineMarksPerRound:
          firstNineLegs > 0 ? firstNineMarks / (firstNineLegs * 3) : null,
      fiveMarkTurns: fiveMarks,
      sixMarkTurns: sixMarks,
      sevenMarkTurns: sevenMarks,
      eightMarkTurns: eightMarks,
      nineMarkTurns: nineMarks,
    );
  }

  // ── Per-game player stats ──────────────────────────────────────────────────

  /// Builds a per-game PlayerStats slice for one player in one game.
  ///
  /// AVG uses the caller-supplied dart aggregate (matches the historical
  /// raw-throw semantic and works with fixtures that insert dart_throws
  /// without corresponding DartThrown events). Other stats come from
  /// projections over [events].
  PlayerStats playerStatsForGameFromEvents({
    required String playerId,
    required GameType gameType,
    required int playerDartsInGame,
    required int playerScoreInGame,
    required List<GameEvent> events,
  }) {
    final threeDartAverage = playerDartsInGame > 0
        ? (playerScoreInGame / playerDartsInGame) * 3
        : 0.0;

    if (gameType == GameType.countUp) {
      final runner = ProjectionRunner([
        CountUpFirstNinePprProjection(),
        CountUpHighScoreBucketsProjection(),
      ]);
      runner.init(ProjectionContext(
        playerId: playerId,
        gameType: GameType.countUp,
        inStrategy: 'straight',
        outStrategy: 'straight',
        playerIds: [playerId],
      ));
      runner.run(events);
      final snap = runner.snapshot();

      final firstNineSnap = snap['count_up.firstNineAverage'] ?? {};
      final bucketsSnap = snap['count_up.highScoreBuckets'] ?? {};

      // count-up has no winner-per-game distinction at the player level
      // (winner is a competitor); the caller can derive it from
      // GameCompleted's winner_id payload instead.
      return PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: 1,
        gamesWon: 0,
        winRate: 0.0,
        threeDartAverage: threeDartAverage,
        bustRate: 0.0,
        highestTurnScore: 0,
        totalDartsThrown: playerDartsInGame,
        dartsPerLeg: 0.0,
        legsPlayed: 1,
        legsWon: 0,
        firstNinePpr: (firstNineSnap['firstNinePpr'] as num?)?.toDouble(),
        sixtyPlusTurns: bucketsSnap['sixtyPlusTurns'] as int? ?? 0,
        oneHundredPlusTurns: bucketsSnap['oneHundredPlusTurns'] as int? ?? 0,
        oneFortyPlusTurns: bucketsSnap['oneFortyPlusTurns'] as int? ?? 0,
        oneEightyTurns: bucketsSnap['oneEightyTurns'] as int? ?? 0,
      );
    }

    final runner = ProjectionRunner([
      X01BustRateProjection(),
      X01CheckoutProjection(),
      X01HighestCheckoutProjection(),
      X01HighestTurnScoreProjection(),
      X01LegsProjection(),
    ]);
    runner.init(ProjectionContext(
      playerId: playerId,
      gameType: gameType,
      inStrategy: 'straight',
      outStrategy: 'double',
      playerIds: [playerId],
    ));
    runner.run(events);
    final snap = runner.snapshot();

    final bustRateSnap = snap['x01_bust_rate'] ?? {};
    final checkoutSnap = snap['x01_checkout'] ?? {};
    final highestCheckoutSnap = snap['x01_highest_checkout'] ?? {};
    final highestTurnSnap = snap['x01_highest_turn_score'] ?? {};
    final legsSnap = snap['x01.legs'] ?? {};

    final legsPlayed = legsSnap['legsPlayed'] as int? ?? 0;
    final legsWon = legsSnap['legsWon'] as int? ?? 0;

    return PlayerStats(
      playerId: playerId,
      gameType: gameType,
      totalGames: 1,
      gamesWon: legsWon > 0 ? 1 : 0,
      winRate: legsWon > 0 ? 1.0 : 0.0,
      threeDartAverage: threeDartAverage,
      bustRate: (bustRateSnap['bustRate'] as num?)?.toDouble() ?? 0.0,
      checkoutPercentage:
          (checkoutSnap['checkoutPercentage'] as num?)?.toDouble(),
      highestCheckout: highestCheckoutSnap['highestCheckout'] as int?,
      highestTurnScore: highestTurnSnap['highestTurnScore'] as int? ?? 0,
      totalDartsThrown: playerDartsInGame,
      dartsPerLeg:
          legsPlayed > 0 ? playerDartsInGame / legsPlayed : 0.0,
      legsPlayed: legsPlayed,
      legsWon: legsWon,
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
