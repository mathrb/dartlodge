import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';

class ComputeLegStatsUseCase {
  const ComputeLegStatsUseCase({
    PlayerStatsAssembler? assembler,
  }) : _assembler = assembler ?? const PlayerStatsAssembler();

  final PlayerStatsAssembler _assembler;

  /// Events must be sorted by `localSequence` ascending.
  ///
  /// Emits one [LegStatsBreakdown] per `LegCompleted` event for every game
  /// type. For X01/Cricket the per-competitor stats are populated via the
  /// projection assembler; for other game types only `dartsThrown` is
  /// counted (other fields stay null/0) so that callers can still render
  /// a per-leg row + a turn breakdown.
  List<LegStatsBreakdown> execute({
    required List<GameEvent> events,
    required List<Competitor> competitors,
    required GameType gameType,
    String outStrategy = 'double',
  }) {
    if (competitors.isEmpty) return const [];

    final supportsRichStats =
        gameType == GameType.x01 || gameType == GameType.cricket;
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

      final dartsByCompetitor = supportsRichStats
          ? const <String, int>{}
          : _countDartsByCompetitor(legEvents);

      legs.add(LegStatsBreakdown(
        legNumber: legNumber++,
        winnerCompetitorId: winnerCompetitorId,
        winnerName: winnerName,
        byCompetitor: [
          for (final competitor in competitors)
            supportsRichStats
                ? _assembler.legCompetitorStatsFromEvents(
                    events: legEvents,
                    competitor: competitor,
                    allPlayerIds: allPlayerIds,
                    gameType: gameType,
                    outStrategy: outStrategy,
                  )
                : LegCompetitorStats(
                    competitorId: competitor.competitorId,
                    competitorName: competitor.name,
                    dartsThrown:
                        dartsByCompetitor[competitor.competitorId] ?? 0,
                  ),
        ],
      ));
      legStart = i + 1;
    }
    return legs;
  }

  Map<String, int> _countDartsByCompetitor(List<GameEvent> legEvents) {
    final counts = <String, int>{};
    for (final e in legEvents) {
      if (e.eventType != 'DartThrown') continue;
      final id = e.payload['competitor_id'] as String?;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }
}
