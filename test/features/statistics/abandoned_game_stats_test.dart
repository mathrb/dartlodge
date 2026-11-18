// Regression tests for #280 on the lazy-abandon path: a game left active
// (page reload, app killed) and closed when the next game starts. Games
// stored before that path wrote GameCompleted have no terminating event, so
// the stats replay must treat the game boundary itself as a leg and match
// boundary, or the abandoned darts bleed into the next game's best leg.


import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/persistence/drift/repositories/statistics_repository_drift.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import '../../hybrid_test_runner.dart';

const _playerId = 'p1';

const _twoVisitsOf60 = [
  [(20, 1), (20, 1), (20, 1)],
  [(20, 1), (20, 1), (20, 1)],
];

const _nineDarter = [
  [(20, 3), (20, 3), (20, 3)],
  [(20, 3), (20, 3), (20, 3)],
  [(20, 3), (19, 3), (12, 2)],
];

void main() {
  for (final viaEndGameMenu in [true, false]) {
    final label = viaEndGameMenu
        ? 'abandoned via End Game (GameCompleted written)'
        : 'closed with no GameCompleted (stored before the lazy-abandon fix)';
    runHybridTests('X01 stats after a game $label', (base) {
      late StatisticsRepositoryDrift statsRepo;

      setUp(() async {
        final playerRepo = await base.createPlayerRepository();
        final gameRepo = await base.createGameRepository();
        final dartThrowRepo = await base.createDartThrowRepository();
        final gameEventRepo = await base.createGameEventRepository();
        statsRepo = await base.createStatisticsRepository();
        await playerRepo.createPlayer(Player(
          playerId: _playerId,
          name: 'P',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        ));
        // Abandoned after two visits of 60 (the tab was closed / app killed).
        await _playSoloX01Game(
          gameRepo: gameRepo,
          dartThrowRepo: dartThrowRepo,
          gameEventRepo: gameEventRepo,
          gameId: '0000-abandoned',
          competitorId: '0000-c1',
          playerId: _playerId,
          startTime: DateTime(2026, 11, 17, 20),
          turns: _twoVisitsOf60,
          finish: false,
          emitGameCompletedOnAbandon: viaEndGameMenu,
        );
        // Next game: a nine-darter (leg PPR 167).
        await _playSoloX01Game(
          gameRepo: gameRepo,
          dartThrowRepo: dartThrowRepo,
          gameEventRepo: gameEventRepo,
          gameId: 'ffff-next',
          competitorId: 'ffff-c1',
          playerId: _playerId,
          startTime: DateTime(2026, 11, 17, 21),
          turns: _nineDarter,
        );
      });

      test('best leg and best first 9 are the nine-darter alone', () async {
        final stats =
            await statsRepo.getPlayerStats(_playerId, gameType: GameType.x01);
        expect(stats.bestLegPpr, closeTo(167.0, 0.5));
        expect(stats.bestFirstNinePpr, closeTo(167.0, 0.5));
      });
    });
  }
}

Future<void> _playSoloX01Game({
  required dynamic gameRepo,
  required dynamic dartThrowRepo,
  required dynamic gameEventRepo,
  required String gameId,
  required String competitorId,
  required String playerId,
  required List<List<(int, int)>> turns,
  required DateTime startTime,
  bool finish = true,
  bool emitGameCompletedOnAbandon = false,
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
      startTime: startTime,
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

  if (!finish) {
    // Abandoned mid-leg. The End Game menu (ActiveGameNotifier.endGame)
    // appends GameCompleted(winner=null) via appendEventsAndCompleteGame.
    // Games closed by the old lazy-abandon path (a new game started while
    // this one was still active) have no event.
    if (emitGameCompletedOnAbandon) {
      await appendEvent('GameCompleted', {'winner_competitor_id': null});
    }
    await gameRepo.completeGame(
      gameId: gameId,
      winnerCompetitorId: null,
      endTime: DateTime.now(),
    );
    return;
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
