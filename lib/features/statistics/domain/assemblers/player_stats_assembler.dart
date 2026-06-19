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

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/utils/cricket_segment_utils.dart';
import 'package:dart_lodge/features/game/domain/engines/event_replay.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
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
import 'package:dart_lodge/features/statistics/domain/engines/x01/games_501_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/nine_darter_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_high_score_buckets_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_highest_checkout_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_highest_turn_score_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_legs_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_win_rate_projection.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';

/// The cross-type metric bundle for achievement evaluation (#521/#524).
///
/// A statistics-owned record (not the achievements feature's `AchievementMetrics`)
/// so the statistics layer never imports the achievements feature — the
/// achievements watcher (SI-4) maps this record to `AchievementMetrics`,
/// keeping the dependency one-way (achievements → statistics).
typedef AchievementMetricsData = ({
  int total180s,
  int highestCheckout,
  int totalWins,
  int totalDartsThrown,
  int games501Played,
  bool hasNineDarter,
});

class PlayerStatsAssembler {
  const PlayerStatsAssembler();

  static const Set<GameType> _practiceGameTypes = {
    GameType.aroundTheClock,
    GameType.bobs27,
    GameType.shanghai,
    GameType.catch40,
    GameType.checkoutPractice,
  };

  /// Computes the cross-type achievement metric bundle for [playerId] (#524).
  ///
  /// [events] is the player's full history across ALL game types, sorted
  /// `(game_id, local_sequence)`; [gameTypesById] maps each gameId to its type
  /// so X01-only projections see only X01 events (a cricket turn scoring 180
  /// points must not inflate the 180 count). [totalDartsThrown] is supplied by
  /// the repository (a `dart_throws` row count), not derived here.
  ///
  /// - total180s: X01 + Count-Up `oneEightyTurns` (both score-max formats).
  /// - highestCheckout / games501Played / hasNineDarter: X01 only.
  /// - totalWins: every `GameCompleted` the player won, across all types
  ///   (solo practice completions carry a null winner and are excluded).
  AchievementMetricsData achievementMetricsFromEvents({
    required String playerId,
    required List<GameEvent> events,
    required int totalDartsThrown,
    required Map<String, GameType> gameTypesById,
  }) {
    final stripped = _stripCorrectedDarts(events);
    final x01Events = [
      for (final e in stripped)
        if (gameTypesById[e.gameId] == GameType.x01) e
    ];
    final countUpEvents = [
      for (final e in stripped)
        if (gameTypesById[e.gameId] == GameType.countUp) e
    ];

    final x01Runner = ProjectionRunner([
      X01HighScoreBucketsProjection(),
      X01HighestCheckoutProjection(),
      NineDarterProjection(),
      Games501Projection(),
    ])
      ..init(ProjectionContext(
        playerId: playerId,
        gameType: GameType.x01,
        inStrategy: 'straight',
        outStrategy: 'double',
      ));
    x01Runner.run(x01Events);
    final xs = x01Runner.snapshot();

    final countUpRunner = ProjectionRunner([CountUpHighScoreBucketsProjection()])
      ..init(ProjectionContext(
        playerId: playerId,
        gameType: GameType.countUp,
        inStrategy: 'straight',
        outStrategy: 'double',
      ));
    countUpRunner.run(countUpEvents);
    final cus = countUpRunner.snapshot();

    final total180s = (xs['x01.highScoreBuckets']?['oneEightyTurns'] as int? ?? 0) +
        (cus['count_up.highScoreBuckets']?['oneEightyTurns'] as int? ?? 0);
    final totalWins = stripped
        .where((e) =>
            e.eventType == 'GameCompleted' &&
            e.payload['winner_player_id'] == playerId)
        .length;

    return (
      total180s: total180s,
      highestCheckout: (xs['x01_highest_checkout']?['highestCheckout'] as int?) ?? 0,
      totalWins: totalWins,
      totalDartsThrown: totalDartsThrown,
      games501Played: (xs['x01.games501']?['games501Played'] as int? ?? 0),
      hasNineDarter: (xs['x01.nineDarter']?['hasNineDarter'] as bool? ?? false),
    );
  }

  /// Computes the canonical Bob's 27 score for one leg of events, scoped to
  /// [playerId]. Mirrors the bonus/penalty replay in `_computeBobs27Stats`:
  /// starts at 27, adds `turnDoubleHits * currentRound * 2` per turn that
  /// landed at least one double on the round's target, otherwise subtracts
  /// `currentRound * 2`. Returns null if no player turns were observed.
  /// See #190.
  static int? _bobs27LegScore(List<GameEvent> legEvents, String playerId) {
    int score = 27;
    int currentRound = 1;
    int turnDoubleHits = 0;
    bool inPlayerTurn = false;
    bool sawAnyTurn = false;

    for (final event in legEvents) {
      final epid = event.payload['player_id'] as String?;
      switch (event.eventType) {
        case 'TurnStarted':
          if (epid != playerId) break;
          inPlayerTurn = true;
          turnDoubleHits = 0;
          sawAnyTurn = true;
        case 'DartThrown':
          if (!inPlayerTurn || epid != playerId) break;
          final seg = (event.payload['segment'] as num?)?.toInt() ?? 0;
          final mult = (event.payload['multiplier'] as num?)?.toInt() ?? 1;
          if (mult == 2 && seg == currentRound) turnDoubleHits++;
        case 'TurnEnded':
          if (!inPlayerTurn || epid != playerId) break;
          inPlayerTurn = false;
          if (turnDoubleHits > 0) {
            score += turnDoubleHits * currentRound * 2;
          } else {
            score -= currentRound * 2;
          }
          currentRound++;
      }
    }

    return sawAnyTurn ? score : null;
  }

  /// Strips events superseded by any DartCorrected payload. Two flavours
  /// of skip:
  ///
  ///   * `original_event_id` — the corrected `DartThrown` event; remove
  ///     the original dart from the stream so projections see only the
  ///     replacement (#187).
  ///   * `superseded_event_ids` — turn-boundary events (TurnEnded /
  ///     TurnStarted) that bracketed a cross-turn undo. Without removing
  ///     these, a per-turn projection like Cricket's
  ///     `CricketMarksPerTurnProjection` double-counts the closing
  ///     TurnEnded of the undone turn and inflates the turn denominator,
  ///     dragging AVG MPR below the true value (#321). `event_replay.dart`
  ///     already honours both sets on cold-load; this brings the
  ///     assembler in line so subsequent projection passes agree.
  ///
  /// Applied at every public method entry that consumes raw events, not
  /// just the career path. Delegates to the shared [stripSupersededEvents]
  /// (single source of truth for DartCorrected skip handling).
  static List<GameEvent> _stripCorrectedDarts(List<GameEvent> events) =>
      stripSupersededEvents(events);

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
    // Strip corrected darts upfront so both the practice branch and the
    // X01/cricket/countUp branch below see post-correction events (#187).
    final stripped = _stripCorrectedDarts(events);

    if (_practiceGameTypes.contains(gameType)) {
      return _buildPracticeStats(
        playerId: playerId,
        gameType: gameType,
        events: stripped,
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
      soloGameIds: soloGameIds,
    );

    final runner = isCricket
        ? ProjectionRunner([
            CricketMarksPerTurnProjection(),
            CricketHitRateProjection(),
            CricketMarkBucketsProjection(),
            CricketFirstNineMprProjection(),
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

    // `stripped` (computed above) has already removed corrected DartThrown
    // events — replay-aware code mirrors UndoLastDartUseCase.
    final filteredEvents = stripped;

    // One pass over filteredEvents is sufficient: corrected DartThrown events
    // are already excluded, so the snapshot reflects post-correction state.
    //
    // A second replayFrom(filteredEvents, fromSequencePerGame) pass used to
    // run here, but it re-initialised every engine and replayed only events
    // with localSequence >= DartCorrected.localSequence — silently dropping
    // every earlier event (including TurnStarted at the start of the leg)
    // from the snapshot. See #164.
    runner.init(context);
    runner.run(filteredEvents);

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
      final firstNineSnap = snap['cricket.firstNineMpr'] ?? {};
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
        fiveMarkTurns: bucketsSnap['fiveMarkTurns'] as int? ?? 0,
        sixMarkTurns: bucketsSnap['sixMarkTurns'] as int? ?? 0,
        sevenMarkTurns: bucketsSnap['sevenMarkTurns'] as int? ?? 0,
        eightMarkTurns: bucketsSnap['eightMarkTurns'] as int? ?? 0,
        nineMarkTurns: bucketsSnap['nineMarkTurns'] as int? ?? 0,
        bestLegMpt: (bestLegMptSnap['bestLegMpt'] as num?)?.toDouble(),
        bestGameHitRate:
            (bestGameHitRateSnap['bestGameHitRate'] as num?)?.toDouble(),
        firstNineMpr: (firstNineSnap['firstNineMpr'] as num?)?.toDouble(),
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
    final doubleOutSnap = snap['x01.doubleOut'] ?? {};
    final firstDartInSnap = snap['x01.firstDartIn'] ?? {};

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
      doubleOutSuccessRate:
          (doubleOutSnap['doubleOutSuccessRate'] as num?)?.toDouble(),
      firstDartInSuccessRate:
          (firstDartInSnap['firstDartInSuccessRate'] as num?)?.toDouble(),
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

    // Strip corrected darts so per-game stats reflect post-undo state (#187).
    events = _stripCorrectedDarts(events);

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

      // Per-player engine instances. We walk `events` ONCE and dispatch each
      // event to every player's engine set — the engines already filter on
      // `context.playerId`, so this is the cheapest way to keep the existing
      // snapshot contract while eliminating the O(P × E) re-pass that
      // `ProjectionRunner.run(events)` would impose per player. (Issue #137
      // sub-task 4.)
      if (isX01) {
        final perPlayer = <String, List<ProjectionEngine>>{};
        for (final playerId in playerIds) {
          final engines = <ProjectionEngine>[
            X01CheckoutProjection(),
            X01HighScoreBucketsProjection(),
            X01HighestCheckoutProjection(),
          ];
          for (final engine in engines) {
            engine.init(ProjectionContext(
              playerId: playerId,
              gameType: GameType.x01,
              inStrategy: 'straight',
              outStrategy: 'double',
            ));
          }
          perPlayer[playerId] = engines;
        }
        _runMultiPlayer(events, perPlayer.values);
        for (final engines in perPlayer.values) {
          final snap = <String, Map<String, dynamic>>{
            for (final e in engines) e.descriptor.id: e.snapshot(),
          };
          final buckets = snap['x01.highScoreBuckets'] ?? const {};
          totalOneEighty += (buckets['oneEightyTurns'] as int? ?? 0);
          totalFortyPlus += (buckets['oneFortyPlusTurns'] as int? ?? 0);
          totalHundredPlus += (buckets['oneHundredPlusTurns'] as int? ?? 0);
          totalSixtyPlus += (buckets['sixtyPlusTurns'] as int? ?? 0);

          final checkout = snap['x01_checkout'] ?? const {};
          totalCheckoutAttempts += (checkout['checkoutAttempts'] as int? ?? 0);
          totalSuccessfulCheckouts +=
              (checkout['successfulCheckouts'] as int? ?? 0);

          final hcSnap = snap['x01_highest_checkout'] ?? const {};
          final hc = hcSnap['highestCheckout'] as int?;
          if (hc != null &&
              (competitorHighestCheckout == null ||
                  hc > competitorHighestCheckout)) {
            competitorHighestCheckout = hc;
          }
        }
      } else if (isCountUp) {
        final perPlayer = <String, List<ProjectionEngine>>{};
        for (final playerId in playerIds) {
          final engines = <ProjectionEngine>[
            CountUpHighScoreBucketsProjection(),
          ];
          for (final engine in engines) {
            engine.init(ProjectionContext(
              playerId: playerId,
              gameType: GameType.countUp,
              inStrategy: 'straight',
              outStrategy: 'straight',
            ));
          }
          perPlayer[playerId] = engines;
        }
        _runMultiPlayer(events, perPlayer.values);
        for (final engines in perPlayer.values) {
          final snap = <String, Map<String, dynamic>>{
            for (final e in engines) e.descriptor.id: e.snapshot(),
          };
          final buckets = snap['count_up.highScoreBuckets'] ?? const {};
          totalOneEighty += (buckets['oneEightyTurns'] as int? ?? 0);
          totalFortyPlus += (buckets['oneFortyPlusTurns'] as int? ?? 0);
          totalHundredPlus += (buckets['oneHundredPlusTurns'] as int? ?? 0);
          totalSixtyPlus += (buckets['sixtyPlusTurns'] as int? ?? 0);
        }
      } else if (isCricket) {
        final perPlayer = <String, List<ProjectionEngine>>{};
        for (final playerId in playerIds) {
          final engines = <ProjectionEngine>[
            CricketMarksPerTurnProjection(),
            CricketMarkBucketsProjection(),
            CricketFirstNineMprProjection(),
          ];
          for (final engine in engines) {
            engine.init(ProjectionContext(
              playerId: playerId,
              gameType: GameType.cricket,
              inStrategy: 'straight',
              outStrategy: 'straight',
            ));
          }
          perPlayer[playerId] = engines;
        }
        _runMultiPlayer(events, perPlayer.values);
        for (final engines in perPlayer.values) {
          final snap = <String, Map<String, dynamic>>{
            for (final e in engines) e.descriptor.id: e.snapshot(),
          };
          final mptSnap = snap['cricket.mpt'] ?? const {};
          totalMarks += (mptSnap['totalMarks'] as int? ?? 0);
          totalTurns += (mptSnap['totalTurns'] as int? ?? 0);

          final bucketsSnap = snap['cricket.markBuckets'] ?? const {};
          cricketFiveMark += (bucketsSnap['fiveMarkExact'] as int? ?? 0);
          cricketSixMark += (bucketsSnap['sixMarkExact'] as int? ?? 0);
          cricketSevenMark += (bucketsSnap['sevenMarkExact'] as int? ?? 0);
          cricketEightMark += (bucketsSnap['eightMarkExact'] as int? ?? 0);
          cricketNineMark += (bucketsSnap['nineMarkExact'] as int? ?? 0);

          final fn9Snap = snap['cricket.firstNineMpr'] ?? const {};
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

  // ── Per-leg checkout stats (single player) ─────────────────────────────────

  /// Computes X01 checkout stats for ONE leg's events for [playerId].
  ///
  /// Runs a fresh [X01CheckoutProjection] over the supplied leg-scoped
  /// events. The projection is cumulative by design (its `reset(leg)` is a
  /// no-op), but feeding it a single leg's events makes its snapshot
  /// leg-scoped in practice. The returned percentage is
  /// `successes / attempts * 100` (null when there are no attempts).
  ///
  /// Used by the leg-history loader to render the per-leg checkout %
  /// series — the loader has the per-leg event slice already, so passing
  /// it here keeps the computation in the assembler (single source of
  /// truth) and replaces the historical bogus formula `(1 / attempts) * 100`.
  ({int attempts, int successes, double? percentage})
      legCheckoutStatsFromEvents({
    required String playerId,
    required List<GameEvent> legEvents,
  }) {
    final projection = X01CheckoutProjection();
    projection.init(ProjectionContext(
      playerId: playerId,
      gameType: GameType.x01,
      inStrategy: 'straight',
      outStrategy: 'double',
    ));
    // Strip corrected darts so an undo inside the leg doesn't double-count
    // the corrected DartThrown and its replacement (#187).
    legEvents = _stripCorrectedDarts(legEvents);
    for (final event in legEvents) {
      if (projection.descriptor.consumedEventTypes.contains(event.eventType)) {
        projection.apply(event);
      }
    }
    final snap = projection.snapshot();
    return (
      attempts: snap['checkoutAttempts'] as int? ?? 0,
      successes: snap['successfulCheckouts'] as int? ?? 0,
      percentage: (snap['checkoutPercentage'] as num?)?.toDouble(),
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

    // Strip corrected darts so per-leg stats reflect post-undo state (#187).
    events = _stripCorrectedDarts(events);

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

      final perPlayer = <String, List<ProjectionEngine>>{};
      for (final playerId in playerIds) {
        final engines = <ProjectionEngine>[
          CountUpAverageProjection(),
          CountUpHighScoreBucketsProjection(),
        ];
        for (final engine in engines) {
          engine.init(ProjectionContext(
            playerId: playerId,
            gameType: GameType.countUp,
            inStrategy: 'straight',
            outStrategy: 'straight',
          ));
        }
        perPlayer[playerId] = engines;
      }
      _runMultiPlayer(events, perPlayer.values);
      for (final engines in perPlayer.values) {
        final snap = <String, Map<String, dynamic>>{
          for (final e in engines) e.descriptor.id: e.snapshot(),
        };
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

      final perPlayer = <String, List<ProjectionEngine>>{};
      for (final playerId in playerIds) {
        final engines = <ProjectionEngine>[
          X01AverageProjection(),
          X01CheckoutProjection(),
          X01HighestCheckoutProjection(),
          X01HighScoreBucketsProjection(),
        ];
        for (final engine in engines) {
          engine.init(ProjectionContext(
            playerId: playerId,
            gameType: GameType.x01,
            inStrategy: 'straight',
            outStrategy: 'double',
          ));
        }
        perPlayer[playerId] = engines;
      }
      _runMultiPlayer(events, perPlayer.values);
      for (final engines in perPlayer.values) {
        final snap = <String, Map<String, dynamic>>{
          for (final e in engines) e.descriptor.id: e.snapshot(),
        };
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

    final perPlayer = <String, List<ProjectionEngine>>{};
    for (final playerId in playerIds) {
      final engines = <ProjectionEngine>[
        CricketMarksPerTurnProjection(),
        CricketMarkBucketsProjection(),
        CricketFirstNineMprProjection(),
      ];
      for (final engine in engines) {
        engine.init(ProjectionContext(
          playerId: playerId,
          gameType: GameType.cricket,
          inStrategy: 'straight',
          outStrategy: 'straight',
        ));
      }
      perPlayer[playerId] = engines;
    }
    _runMultiPlayer(events, perPlayer.values);
    for (final engines in perPlayer.values) {
      final snap = <String, Map<String, dynamic>>{
        for (final e in engines) e.descriptor.id: e.snapshot(),
      };

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

  // ── Per-leg history (single player × single game) ──────────────────────────

  /// Builds a `List<PlayerLegSnapshot>` for one player across one game.
  ///
  /// Walks [events] in order, tracking per-leg accumulators (PPR, MPT,
  /// ATC hit-rate, X01 checkout score/percentage) and emitting one snapshot
  /// at every `LegCompleted`. The returned list reflects whichever legs
  /// completed within [events] — caller is responsible for cross-game
  /// concatenation and any global limit slicing.
  ///
  /// Scope is `(playerId, gameId)`: all output snapshots inherit [gameId],
  /// [gameDate] and [startingScore]; only events whose `player_id` matches
  /// [playerId] feed the player-scoped accumulators (darts/score/marks).
  /// Events with no `player_id` (e.g. `LegCompleted`) still drive leg-end
  /// emission.
  ///
  /// Behaviour preserved from the historical drift-loader implementation
  /// (issue #137 §legHistoryFromEvents):
  ///   - PPR = (legScoreTotal / legDartCount) * 3, zero when no darts.
  ///   - MPT = legTotalMarks / legTotalTurns, null when no turns.
  ///   - X01 checkout-% goes through [legCheckoutStatsFromEvents] (real
  ///     successes ÷ attempts) — never the legacy `(1 / attempts) * 100`.
  ///   - X01 `checkoutScore` is the player's most recent `TurnStarted`
  ///     `starting_score` BEFORE `LegCompleted` IFF that player won the leg.
  ///   - ATC practice score = atcHits / atcDartsAtTarget for current player;
  ///     other practice gametypes use raw leg score. All three ATC variants
  ///     (`standard`, `reverse`, `doublesOnly`) are supported — target
  ///     progression and hit detection mirror
  ///     `StatelessAroundTheClockEngine` (issue #157).
  ///
  /// [gameType] selects the practice-score branch. Pass `null` to treat the
  /// game as non-practice (no `practiceScore`). [atcVariant] is consulted only
  /// when [gameType] is [GameType.aroundTheClock]; valid values are
  /// `'standard'`, `'reverse'`, `'doublesOnly'`. Defaults to `'standard'`.
  List<PlayerLegSnapshot> legHistoryFromEvents({
    required String playerId,
    required String gameId,
    required DateTime gameDate,
    required GameType? gameType,
    required int? startingScore,
    required List<GameEvent> events,
    int startingLegIndex = 0,
    String atcVariant = 'standard',
  }) {
    // Strip corrected darts so leg-history reflects post-undo state (#187).
    events = _stripCorrectedDarts(events);

    final isPracticeGame =
        gameType != null && _practiceGameTypes.contains(gameType);

    final snapshots = <PlayerLegSnapshot>[];
    int legIndex = startingLegIndex;

    int legDartCount = 0;
    int legScoreTotal = 0;
    int legTotalMarks = 0;
    int legTotalTurns = 0;
    int currentTurnMarks = 0;

    // ATC hit-rate tracking (player-scoped). Target progression mirrors
    // `StatelessAroundTheClockEngine`:
    //   - 'standard' / 'doublesOnly': ascend 1 → 20
    //   - 'reverse':                  descend 20 → 1
    // 'doublesOnly' additionally requires `multiplier == 2` to register a hit.
    final bool atcReverse = atcVariant == 'reverse';
    final bool atcDoublesOnly = atcVariant == 'doublesOnly';
    final int atcInitialTarget = atcReverse ? 20 : 1;
    int atcDartsAtTarget = 0;
    int atcHits = 0;
    int atcCurrentTarget = atcInitialTarget;
    bool atcInPlayerTurn = false;

    // X01 checkout-score tracking.
    int? lastPlayerTurnStartingScore;

    // Active cricket target set for this game. Resets to the canonical
    // fixed set on each `GameCreated`; replaced by the assigned 6 numbers
    // (+ implicit Bull 25) on `CricketTargetsAssigned`. See
    // `docs/plans/2026-05-19-cricket-target-modes-design.md` §6.
    Set<int> activeCricketTargets = kCricketTargets;

    final currentLegEvents = <GameEvent>[];

    for (final event in events) {
      currentLegEvents.add(event);
      final payload = event.payload;
      switch (event.eventType) {
        case 'GameCreated':
          activeCricketTargets = kCricketTargets;
        case 'CricketTargetsAssigned':
          final raw = payload['targets'] as List<dynamic>;
          activeCricketTargets = {
            for (final t in raw) (t as num).toInt(),
            25,
          };
        case 'CrazyTargetsRolled':
          // Crazy Cricket: targets rotate every turn. Marks here are
          // counted from `DartThrown` payloads within each turn (this
          // assembler is already turn-scoped via `currentTurnMarks`),
          // never from cross-turn board diffs — discard-on-rotate makes
          // cumulative marks non-monotonic. See
          // `docs/statistics/statistics.architecture.md` §7.3.
          final raw = payload['open_targets'] as List<dynamic>;
          activeCricketTargets = {
            for (final t in raw) (t as num).toInt(),
            25,
          };
        case 'TurnStarted':
          final pid = payload['player_id'] as String?;
          if (pid != playerId) break;
          currentTurnMarks = 0;
          atcInPlayerTurn = true;
          lastPlayerTurnStartingScore =
              (payload['starting_score'] as num?)?.toInt();
        case 'DartThrown':
          final pid = payload['player_id'] as String?;
          if (pid != playerId) break;
          legDartCount++;
          final rawSeg = payload['segment'];
          final segInt = rawSeg is num ? rawSeg.toInt() : null;
          final mult = (payload['multiplier'] as num?)?.toInt();
          final score = (segInt != null && mult != null)
              ? segInt * mult
              : (payload['score'] as num?)?.toInt() ?? 0;
          legScoreTotal += score;

          // Cricket marks (numeric or canonical-string segment). Uses the
          // active target set so Random Cricket marks land correctly.
          if (rawSeg is String) {
            currentTurnMarks +=
                cricketMarksForSegment(rawSeg, targets: activeCricketTargets);
          } else if (segInt != null) {
            final multInt = mult ?? 1;
            if (activeCricketTargets.contains(segInt)) {
              currentTurnMarks += multInt.clamp(0, 3);
            }
          }

          // ATC progression (player-scoped). Hit detection and target
          // advancement mirror `StatelessAroundTheClockEngine` (issue #157):
          //   - 'standard' / 'doublesOnly': ascend 1 → 20; complete at 20.
          //   - 'reverse':                  descend 20 → 1; complete at 1.
          //   - 'doublesOnly':              hit requires multiplier == 2.
          // Once the sequence is complete (target stepped past the terminal
          // value) no further darts count toward atcDartsAtTarget — matches
          // the historical "<= 20" gate.
          if (isPracticeGame &&
              gameType == GameType.aroundTheClock &&
              atcInPlayerTurn) {
            final segVal = segInt ?? 0;
            final multVal = mult ?? 1;
            final bool sequenceActive = atcReverse
                ? atcCurrentTarget >= 1
                : atcCurrentTarget <= 20;
            if (sequenceActive) {
              atcDartsAtTarget++;
              final bool segmentMatches = segVal == atcCurrentTarget;
              final bool multiplierOk = !atcDoublesOnly || multVal == 2;
              if (segmentMatches && multiplierOk) {
                atcHits++;
                atcCurrentTarget =
                    atcReverse ? atcCurrentTarget - 1 : atcCurrentTarget + 1;
              }
            }
          }
        case 'TurnEnded':
          final pid = payload['player_id'] as String?;
          if (pid != playerId) break;
          legTotalMarks += currentTurnMarks;
          legTotalTurns++;
          currentTurnMarks = 0;
          atcInPlayerTurn = false;
        case 'LegCompleted':
          legIndex++;
          final ppr =
              legDartCount > 0 ? (legScoreTotal / legDartCount) * 3 : 0.0;
          final mpt =
              legTotalTurns > 0 ? legTotalMarks / legTotalTurns : null;

          // Checkout % via X01CheckoutProjection (decision 4 of issue #129).
          // For non-X01 games the projection's snapshot stays at zero
          // attempts, so the resulting percentage is null — matching the
          // prior behaviour off-X01.
          final checkoutStats = legCheckoutStatsFromEvents(
            playerId: playerId,
            legEvents: currentLegEvents,
          );

          final winnerPlayerId = payload['winner_player_id'] as String?;
          final legCheckoutScore =
              winnerPlayerId == playerId ? lastPlayerTurnStartingScore : null;

          double? practiceScore;
          if (isPracticeGame) {
            // Per-leg score must match the canonical score the game-specific
            // _compute*Stats methods produce — otherwise the leg-history
            // trend chart plots a different series than the post-game /
            // detail screens (#190).
            //
            // - aroundTheClock: hit ratio (matches _computeAtcStats).
            // - bobs27: bonus/penalty mechanics (matches _computeBobs27Stats);
            //   raw dart sum is WRONG because Bob's 27 doesn't accumulate
            //   dart values — doubles on the current round target add
            //   `currentRound * 2`, misses subtract `currentRound * 2`.
            // - shanghai / catch40: raw dart sum matches the existing
            //   _computeShanghaiStats / _computeCatch40Stats logic. Both
            //   methods sum `DartThrown.score` directly. (Whether THAT
            //   matches the canonical game-rule score is a separate concern
            //   tracked outside #190; here we just keep the trend chart
            //   consistent with the detail screen.)
            // - checkoutPractice: no per-leg score concept; the canonical
            //   metric is attempts/successes (consumer should pivot to
            //   _computeCheckoutStats for that).
            switch (gameType) {
              case GameType.aroundTheClock:
                practiceScore =
                    atcDartsAtTarget > 0 ? atcHits / atcDartsAtTarget : null;
              case GameType.bobs27:
                practiceScore =
                    _bobs27LegScore(currentLegEvents, playerId)?.toDouble();
              case GameType.shanghai:
              case GameType.catch40:
                practiceScore = legScoreTotal.toDouble();
              case GameType.checkoutPractice:
                practiceScore = null;
              case GameType.x01:
              case GameType.cricket:
              case GameType.countUp:
                // Not practice game types — should be unreachable given the
                // isPracticeGame gate, but kept explicit to satisfy the
                // exhaustive switch.
                practiceScore = null;
            }
          }

          snapshots.add(PlayerLegSnapshot(
            gameId: gameId,
            legIndex: legIndex,
            gameDate: gameDate,
            ppr: ppr,
            checkoutPct: checkoutStats.percentage,
            checkoutScore: legCheckoutScore,
            startingScore: startingScore,
            mpt: mpt,
            practiceScore: practiceScore,
          ));

          // Reset for next leg.
          legDartCount = 0;
          legScoreTotal = 0;
          legTotalMarks = 0;
          legTotalTurns = 0;
          currentTurnMarks = 0;
          atcDartsAtTarget = 0;
          atcHits = 0;
          atcCurrentTarget = atcInitialTarget;
          atcInPlayerTurn = false;
          lastPlayerTurnStartingScore = null;
          currentLegEvents.clear();
      }
    }

    return snapshots;
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
    // Strip corrected darts so per-player-per-game stats reflect post-undo
    // state (#187). Note: AVG uses caller-supplied dart aggregates, so an
    // undo that happened mid-game must also be reflected in
    // playerDartsInGame / playerScoreInGame — those are the caller's
    // responsibility. This filter only governs the projection branches
    // below.
    events = _stripCorrectedDarts(events);

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

    if (gameType == GameType.cricket) {
      // Per-game cricket bundle. Wires the same cricket projections as the
      // career path in `fromEvents`, so per-game `PlayerStats` exposes the
      // same shape (incl. `bestLegMpt` / `bestGameHitRate` — meaningful on
      // a single-game slice for multi-leg cricket). Reads `*Exact` keys for
      // mark buckets, per the per-game "exact-N" convention (see CLAUDE.md
      // "Cricket mark-bucket field overload").
      final runner = ProjectionRunner([
        CricketMarksPerTurnProjection(),
        CricketHitRateProjection(),
        CricketMarkBucketsProjection(),
        CricketLegsProjection(),
        CricketBestLegMptProjection(),
        CricketBestGameHitRateProjection(),
      ]);
      runner.init(ProjectionContext(
        playerId: playerId,
        gameType: GameType.cricket,
        inStrategy: 'straight',
        outStrategy: 'straight',
      ));
      runner.run(events);
      final snap = runner.snapshot();

      final mptSnap = snap['cricket.mpt'] ?? {};
      final hitRateSnap = snap['cricket.hitRate'] ?? {};
      final bucketsSnap = snap['cricket.markBuckets'] ?? {};
      final legsSnap = snap['cricket.legs'] ?? {};
      final bestLegMptSnap = snap['cricket.bestLegMpt'] ?? {};
      final bestGameHitRateSnap = snap['cricket.bestGameHitRate'] ?? {};

      final legsPlayed = legsSnap['legsPlayed'] as int? ?? 0;
      final legsWon = legsSnap['legsWon'] as int? ?? 0;

      return PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: 1,
        gamesWon: legsWon > 0 ? 1 : 0,
        winRate: legsWon > 0 ? 1.0 : 0.0,
        // threeDartAverage is computed from raw dart scores for parity with
        // the X01/countUp branches. For cricket it has no scoring meaning
        // but callers that render generic per-game tiles still expect it.
        threeDartAverage: threeDartAverage,
        bustRate: 0.0,
        highestTurnScore: 0,
        totalDartsThrown: playerDartsInGame,
        dartsPerLeg: legsPlayed > 0 ? playerDartsInGame / legsPlayed : 0.0,
        legsPlayed: legsPlayed,
        legsWon: legsWon,
        marksPerTurn: (mptSnap['marksPerTurn'] as num?)?.toDouble(),
        hitRate: (hitRateSnap['hitRate'] as num?)?.toDouble(),
        sixMarkTurns: bucketsSnap['sixMarkExact'] as int? ?? 0,
        nineMarkTurns: bucketsSnap['nineMarkExact'] as int? ?? 0,
        bestLegMpt: (bestLegMptSnap['bestLegMpt'] as num?)?.toDouble(),
        bestGameHitRate:
            (bestGameHitRateSnap['bestGameHitRate'] as num?)?.toDouble(),
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

  // ── Multi-player single-pass projection helper ─────────────────────────────

  /// Single-pass projection driver for multiple per-player engine sets.
  ///
  /// Mirrors `ProjectionRunner.run`'s reset/apply ordering (turn reset on
  /// `TurnStarted`, leg reset on `LegCompleted`, match reset on
  /// `GameCompleted`) but folds all per-player engine sets into one event
  /// walk. The engines already self-filter on `context.playerId`, so it is
  /// safe to dispatch every event to every player's engines; this collapses
  /// the historical O(P × E) "fresh ProjectionRunner per player" loop into
  /// O(E) work (issue #137 sub-task 4).
  ///
  /// Caller is responsible for `init()`-ing each engine with the correct
  /// `ProjectionContext`. Events are sorted by `(gameId, localSequence)`
  /// before the pass — `local_sequence` restarts at 1 per game, so a global
  /// sort interleaves games and corrupts projection state across game
  /// boundaries (per CLAUDE.md "local_sequence is per-game").
  void _runMultiPlayer(
    List<GameEvent> events,
    Iterable<List<ProjectionEngine>> perPlayerEngines,
  ) {
    final sorted = [...events]
      ..sort((a, b) {
        final byGame = a.gameId.compareTo(b.gameId);
        if (byGame != 0) return byGame;
        return a.localSequence.compareTo(b.localSequence);
      });
    final allEngines = perPlayerEngines.expand((e) => e).toList(growable: false);

    for (final event in sorted) {
      if (event.eventType == 'TurnStarted') {
        for (final engine in allEngines) {
          engine.reset(ProjectionScope.turn);
        }
      }
      for (final engine in allEngines) {
        if (engine.descriptor.consumedEventTypes.contains(event.eventType)) {
          engine.apply(event);
        }
      }
      if (event.eventType == 'LegCompleted') {
        for (final engine in allEngines) {
          engine.reset(ProjectionScope.leg);
        }
      } else if (event.eventType == 'GameCompleted') {
        for (final engine in allEngines) {
          engine.reset(ProjectionScope.match);
        }
      }
    }
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
          String playerId, GameType gameType, int totalGames, int totalDartsThrown) =>
      PlayerStats(
        playerId: playerId,
        gameType: gameType,
        totalGames: totalGames,
        gamesWon: 0,
        winRate: 0.0,
        threeDartAverage: 0.0,
        highestTurnScore: 0,
        totalDartsThrown: totalDartsThrown,
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
    // Variant target-progression mirrors StatelessAroundTheClockEngine:
    //   'standard' / 'doublesOnly': ascend 1→20, completion when target > 20
    //   'reverse':                 descend 20→1, completion when target < 1
    // 'doublesOnly' additionally requires multiplier == 2 to register a hit.
    final isReverse = variant == 'reverse';
    final initialTarget = isReverse ? 20 : 1;
    bool sequenceActive(int t) => isReverse ? t >= 1 : t <= 20;
    bool sequenceComplete(int t) => isReverse ? t < 1 : t > 20;
    int advance(int t) => isReverse ? t - 1 : t + 1;

    int totalDartsAtTargets = 0;
    int totalHits = 0;
    int completions = 0;
    int totalTurnsForCompletions = 0;
    int? bestTurns;
    final Map<int, int> segHits = {};
    final Map<int, int> segAttempts = {};

    int currentTarget = initialTarget;
    int gameTurns = 0;
    bool inPlayerTurn = false;

    for (final event in events) {
      // Gate per-player events on payload.player_id so the loop ignores
      // events from other competitors. ATC is solo-only today, but a
      // future multi-competitor ATC variant (or any shared-event load
      // path) would otherwise count other players' turns into gameTurns
      // and segment-attempts — mirrors _computeBobs27Stats (#191).
      final epid = event.payload['player_id'] as String?;
      switch (event.eventType) {
        case 'TurnStarted':
          if (epid != playerId) break;
          inPlayerTurn = true;
          gameTurns++;
        case 'DartThrown':
          if (!inPlayerTurn || epid != playerId) break;
          final seg = (event.payload['segment'] as num?)?.toInt() ?? 0;
          final mult = (event.payload['multiplier'] as num?)?.toInt() ?? 1;
          if (sequenceActive(currentTarget)) {
            totalDartsAtTargets++;
            segAttempts[currentTarget] = (segAttempts[currentTarget] ?? 0) + 1;
            final hit = variant == 'doublesOnly'
                ? (seg == currentTarget && mult == 2)
                : (seg == currentTarget);
            if (hit) {
              totalHits++;
              segHits[currentTarget] = (segHits[currentTarget] ?? 0) + 1;
              currentTarget = advance(currentTarget);
            }
          }
        case 'TurnEnded':
          if (epid != playerId) break;
          inPlayerTurn = false;
        case 'LegCompleted':
          if (sequenceComplete(currentTarget)) {
            completions++;
            totalTurnsForCompletions += gameTurns;
            if (bestTurns == null || gameTurns < bestTurns) {
              bestTurns = gameTurns;
            }
          }
          currentTarget = initialTarget;
          gameTurns = 0;
          inPlayerTurn = false;
        case 'GameCompleted':
          // ATC is a 1-leg practice game: GameCompleted signals drill completion
          // (LegCompleted is never emitted when legsToWin==1).
          if (sequenceComplete(currentTarget)) {
            completions++;
            totalTurnsForCompletions += gameTurns;
            if (bestTurns == null || gameTurns < bestTurns) {
              bestTurns = gameTurns;
            }
          }
          currentTarget = initialTarget;
          gameTurns = 0;
          inPlayerTurn = false;
      }
    }

    final hitRate =
        totalDartsAtTargets > 0 ? totalHits / totalDartsAtTargets : null;
    final avgTurns =
        completions > 0 ? totalTurnsForCompletions / completions : null;

    return _emptyPracticeStats(
      playerId,
      GameType.aroundTheClock,
      totalGames,
      totalDartsThrown,
    ).copyWith(
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
          // "Doubles Hit Rate" = darts that landed on the round's target
          // double / total darts thrown at the target. The original code
          // gated `doubleAttempts++` on `mult == 2`, so the denominator
          // was "darts that landed on any double" (often a small fraction
          // of total throws), making the rate read implausibly high.
          // Counting every dart as an attempt matches the user-facing
          // expectation (#261): if you throw 60 darts at Bob's 27 and
          // land 19 on the round's double, the rate should be 31.7%, not
          // 19/something-smaller.
          doubleAttempts++;
          if (mult == 2 && seg == currentRound) {
            doubleHits++;
            turnDoubleHits++;
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
        case 'GameCompleted':
          // Bob's 27 ends on either bust (score ≤ 0) or finishing round
          // 20 — both paths emit GameCompleted directly with no preceding
          // LegCompleted (see `StatelessBobs27Engine._applyDartThrown`).
          // Gate score accumulation on GameCompleted, not LegCompleted,
          // and include busted final scores in Best/Avg so the stats
          // don't read as blank ("—") next to a non-zero Drills Played
          // (#292). Completion Rate stays gated on `currentScore > 0`
          // (a successful drill is one that didn't bust).
          completedGames++;
          totalScore += currentScore;
          if (bestScore == null || currentScore > bestScore) {
            bestScore = currentScore;
          }
          if (currentScore > 0) {
            successfulCompletions++;
          }
          currentRound = 1;
          currentScore = 27;
          inPlayerTurn = false;
      }
    }

    final avgScore =
        completedGames > 0 ? totalScore / completedGames : null;
    final completionRate =
        completedGames > 0 ? successfulCompletions / completedGames : null;
    final doubleHitRate =
        doubleAttempts > 0 ? doubleHits / doubleAttempts : null;

    return _emptyPracticeStats(
      playerId,
      GameType.bobs27,
      totalGames,
      totalDartsThrown,
    ).copyWith(
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

    return _emptyPracticeStats(
      playerId,
      GameType.shanghai,
      totalGames,
      totalDartsThrown,
    ).copyWith(
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

    // Catch 40 in production emits GameCompleted on natural drill completion
    // and skips LegCompleted (solo, 1-leg drill). The original projection
    // only counted gamesCompleted on LegCompleted and would silently report
    // `Drills Played: 0` for real drills (#253). Handle both event types so
    // the synthetic-event tests using LegCompleted still pass, while the
    // real flow's GameCompleted also accumulates. `gameCounted` prevents
    // double-counting if a stream ever emits both for the same game; resets
    // per game.
    String? currentGameId;
    bool gameCounted = false;
    void closeGame() {
      if (gameCounted) return;
      gameCounted = true;
      gamesCompleted++;
      totalScore += gameScore;
      final prev = bestScore;
      if (prev == null || gameScore > prev) bestScore = gameScore;
      gameScore = 0;
      inPlayerTurn = false;
    }

    for (final event in events) {
      if (event.gameId != currentGameId) {
        currentGameId = event.gameId;
        gameCounted = false;
        gameScore = 0;
        inPlayerTurn = false;
        turnDarts = 0;
      }
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
          // `darts_on_target` covers checkouts that straddle visit 1 → visit 2
          // (e.g. 3 darts in turn 1, 1 dart in turn 2 → 4-dart checkout). The
          // per-turn `turnDarts` would under-count to 1 in that case. Falls
          // back to `turnDarts` for legacy events that didn't emit the field.
          final dartsOnTarget =
              (event.payload['darts_on_target'] as num?)?.toInt() ?? turnDarts;
          if (reason == 'checkout') {
            if (dartsOnTarget <= 2) {
              twoDart++;
            } else if (dartsOnTarget == 3) {
              threeDart++;
            } else if (dartsOnTarget >= 4 && dartsOnTarget <= 6) {
              fourSixDart++;
            }
          } else if (reason == 'failed') {
            failed++;
          }
        case 'LegCompleted':
          closeGame();
        case 'GameCompleted':
          closeGame();
      }
    }

    final avgScore = gamesCompleted > 0 ? totalScore / gamesCompleted : null;

    return _emptyPracticeStats(
      playerId,
      GameType.catch40,
      totalGames,
      totalDartsThrown,
    ).copyWith(
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

    return _emptyPracticeStats(
      playerId,
      GameType.checkoutPractice,
      totalGames,
      totalDartsThrown,
    ).copyWith(
      checkoutAttempts: attempts,
      checkoutSuccesses: successes,
      checkoutSuccessRate: successRate,
    );
  }
}
