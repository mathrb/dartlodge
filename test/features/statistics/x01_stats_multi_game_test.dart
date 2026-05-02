// Regression test: X01 stats across multiple completed games.
// Reproduces a bug where events from multiple games were ordered only by
// `local_sequence`, causing events from different games to be interleaved
// (since each game restarts its local sequence at 1). This corrupted
// projection state — `bestLegPpr` and `bestFirstNinePpr` reported values from
// a phantom "merged leg" instead of the actual best leg across games.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import '../../hybrid_test_runner.dart';

void main() {
  runHybridTests('X01 stats across multiple completed games', (base) {
    test(
      'getPlayerStats: best PPR and best first-9 PPR reflect the better game',
      () async {
        final playerRepo = await base.createPlayerRepository();
        final gameRepo = await base.createGameRepository();
        final dartThrowRepo = await base.createDartThrowRepository();
        final gameEventRepo = await base.createGameEventRepository();
        final statsRepo = await base.createStatisticsRepository();

        const playerId = 'p1';

        await playerRepo.createPlayer(Player(
          playerId: playerId,
          name: 'Player One',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        ));

        // ── Game 1: 18 darts to win (leg PPR = 501/18*3 = 83.5) ───────────
        // The projection only needs the starting score from the first
        // TurnStarted (501), the dart count, and a winning LegCompleted —
        // exact dart values don't influence the leg PPR formula.
        await _playSoloX01Game(
          gameRepo: gameRepo,
          dartThrowRepo: dartThrowRepo,
          gameEventRepo: gameEventRepo,
          gameId: 'g1',
          competitorId: 'g1-c1',
          playerId: playerId,
          turns: const [
            [(20, 1), (20, 1), (20, 1)],
            [(20, 1), (20, 1), (20, 1)],
            [(20, 1), (20, 1), (20, 1)],
            [(20, 1), (20, 1), (20, 1)],
            [(20, 1), (20, 1), (20, 1)],
            [(20, 1), (20, 1), (20, 1)],
          ],
        );

        // ── Game 2: 9-dart finish (leg PPR = 501/9*3 = 167) ───────────────
        await _playSoloX01Game(
          gameRepo: gameRepo,
          dartThrowRepo: dartThrowRepo,
          gameEventRepo: gameEventRepo,
          gameId: 'g2',
          competitorId: 'g2-c1',
          playerId: playerId,
          turns: const [
            [(20, 3), (20, 3), (20, 3)], // 180
            [(20, 3), (20, 3), (20, 3)], // 180
            [(20, 3), (19, 3), (12, 2)], // 60+57+24 = 141 (checkout)
          ],
        );

        // Both games above have overlapping local_sequence values
        // (each restarts at 1). The projection runner must order by
        // (game_id, local_sequence) so each game is processed contiguously;
        // sorting by local_sequence alone would interleave them.
        final stats = await statsRepo.getPlayerStats(
          playerId,
          gameType: GameType.x01,
        );

        expect(stats.totalGames, 2);
        // The 9-dart leg gives 501/9*3 = 167 PPR — best leg across games.
        expect(stats.bestLegPpr, isNotNull);
        expect(stats.bestLegPpr!, closeTo(167.0, 0.5));
        // First nine darts of the 9-dart leg = 501 → 167 PPR.
        expect(stats.bestFirstNinePpr, isNotNull);
        expect(stats.bestFirstNinePpr!, closeTo(167.0, 0.5));
      },
    );
  });
}

/// Append a complete solo X01 game made of [turns]. Each turn is a list of
/// `(segValue, multiplier)` darts; the leg is closed with TurnEnded +
/// LegCompleted + GameCompleted, all attributed to [playerId]. Scores are
/// computed as `segValue * multiplier`. Events use local_sequence 1..N
/// scoped to this game.
Future<void> _playSoloX01Game({
  required dynamic gameRepo,
  required dynamic dartThrowRepo,
  required dynamic gameEventRepo,
  required String gameId,
  required String competitorId,
  required String playerId,
  required List<List<(int, int)>> turns,
}) async {
  final config = const GameConfig.x01(
    startingScore: 501,
    inStrategy: 'straight',
    outStrategy: 'double',
  );

  await gameRepo.createGame(
    Game(
      gameId: gameId,
      gameType: GameType.x01,
      config: config,
      startTime: DateTime.now(),
      isComplete: false,
    ),
    [
      Competitor(
        competitorId: competitorId,
        gameId: gameId,
        type: CompetitorType.solo,
        name: 'Player',
        players: [
          CompetitorPlayer(playerId: playerId, rotationPosition: 0),
        ],
      ),
    ],
  );

  int seq = 1;
  int dartNum = 0;
  int remaining = 501;

  Future<void> appendEvent(
      String type, Map<String, dynamic> payload) async {
    await gameEventRepo.appendEvent(GameEvent(
      eventId: '$gameId-e$seq',
      gameId: gameId,
      eventType: type,
      localSequence: seq++,
      occurredAt: DateTime.now(),
      payload: payload,
      synced: false,
      actorId: playerId,
      source: EventSource.client,
    ));
  }

  for (var t = 0; t < turns.length; t++) {
    await appendEvent('TurnStarted', {
      'competitor_id': competitorId,
      'player_id': playerId,
      'starting_score': remaining,
      'turn_index': 0,
      'leg_index': 0,
    });
    var turnScore = 0;
    final darts = turns[t];
    for (var d = 0; d < darts.length; d++) {
      dartNum++;
      final (seg, mult) = darts[d];
      final score = seg * mult;
      turnScore += score;
      await dartThrowRepo.insertDart(DartThrow(
        dartId: '$gameId-d$dartNum',
        gameId: gameId,
        competitorId: competitorId,
        playerId: playerId,
        turnNumber: t,
        dartNumber: d + 1,
        segment: '${mult}x$seg',
        score: score,
      ));
      await appendEvent('DartThrown', {
        'competitor_id': competitorId,
        'player_id': playerId,
        'segment': seg,
        'multiplier': mult,
        'score': score,
        'input_method': 'manual',
      });
    }
    await appendEvent('TurnEnded', {
      'competitor_id': competitorId,
      'player_id': playerId,
      'reason': 'normal',
    });
    remaining -= turnScore;
  }

  await appendEvent('LegCompleted', {
    'winner_competitor_id': competitorId,
    'winner_player_id': playerId,
  });
  await appendEvent('GameCompleted', {
    'winner_competitor_id': competitorId,
    'winner_player_id': playerId,
  });

  await gameRepo.completeGame(
    gameId: gameId,
    winnerCompetitorId: competitorId,
    endTime: DateTime.now(),
  );
}
