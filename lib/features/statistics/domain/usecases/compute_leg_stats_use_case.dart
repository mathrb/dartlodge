import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_first_nine_mpr_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_mark_buckets_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_marks_per_turn_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_runner.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_average_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_checkout_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_high_score_buckets_projection.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_highest_checkout_projection.dart';

class ComputeLegStatsUseCase {
  const ComputeLegStatsUseCase();

  /// Events must be sorted by `localSequence` ascending.
  List<LegStatsBreakdown> execute({
    required List<GameEvent> events,
    required List<Competitor> competitors,
    required GameType gameType,
  }) {
    if (competitors.isEmpty) return const [];
    if (gameType != GameType.x01 && gameType != GameType.cricket) {
      return const [];
    }

    final allPlayerIds = <String>[
      for (final c in competitors)
        for (final p in c.players) p.playerId,
    ];

    final legs = <LegStatsBreakdown>[];
    var legNumber = 1;
    var legStart = 0;
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      if (event.eventType != 'LegCompleted') continue;

      final legEvents = events.sublist(legStart, i + 1);
      final winnerCompetitorId =
          event.payload['winner_competitor_id'] as String?;
      final winnerName = competitors
              .where((c) => c.competitorId == winnerCompetitorId)
              .map((c) => c.name)
              .firstOrNull ??
          '—';

      legs.add(LegStatsBreakdown(
        legNumber: legNumber++,
        winnerCompetitorId: winnerCompetitorId,
        winnerName: winnerName,
        byCompetitor: [
          for (final competitor in competitors)
            _competitorStatsForLeg(
              events: legEvents,
              competitor: competitor,
              allPlayerIds: allPlayerIds,
              gameType: gameType,
            ),
        ],
      ));
      legStart = i + 1;
    }
    return legs;
  }

  LegCompetitorStats _competitorStatsForLeg({
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
    var fiveMarks = 0, sixMarks = 0, sevenMarks = 0, eightMarks = 0,
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
}
