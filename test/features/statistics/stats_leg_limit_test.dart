// Regression tests for the statistics "Last 10 / Last 100" leg window
// (getPlayerStats legLimit):
// - the window keeps the most recent legs by game start time, not by
//   game_id (game ids are random UUIDs);
// - practice drills (no LegCompleted) are windowed per drill;
// - the game count and win rate follow the window.

import 'dart:convert';

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

const _eighteenS20 = [
  [(20, 1), (20, 1), (20, 1)],
  [(20, 1), (20, 1), (20, 1)],
  [(20, 1), (20, 1), (20, 1)],
  [(20, 1), (20, 1), (20, 1)],
  [(20, 1), (20, 1), (20, 1)],
  [(20, 1), (20, 1), (20, 1)],
];

const _nineDarter = [
  [(20, 3), (20, 3), (20, 3)],
  [(20, 3), (20, 3), (20, 3)],
  [(20, 3), (19, 3), (12, 2)],
];

void main() {
  runHybridTests('getPlayerStats legLimit: X01', (base) {
    late dynamic gameRepo;
    late dynamic dartThrowRepo;
    late dynamic gameEventRepo;
    late dynamic statsRepo;

    setUp(() async {
      final playerRepo = await base.createPlayerRepository();
      gameRepo = await base.createGameRepository();
      dartThrowRepo = await base.createDartThrowRepository();
      gameEventRepo = await base.createGameEventRepository();
      statsRepo = await base.createStatisticsRepository();
      await playerRepo.createPlayer(Player(
        playerId: _playerId,
        name: 'P',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ));
      // The OLD game's id sorts LAST and the NEW game's id sorts FIRST, so a
      // game_id-ordered window would pick the old leg.
      await _playSoloX01Game(
        gameRepo: gameRepo,
        dartThrowRepo: dartThrowRepo,
        gameEventRepo: gameEventRepo,
        gameId: 'ffff-old',
        competitorId: 'ffff-c1',
        playerId: _playerId,
        startTime: DateTime(2026, 11, 16, 20),
        turns: _eighteenS20, // leg PPR 60
      );
      await _playSoloX01Game(
        gameRepo: gameRepo,
        dartThrowRepo: dartThrowRepo,
        gameEventRepo: gameEventRepo,
        gameId: '0000-new',
        competitorId: '0000-c1',
        playerId: _playerId,
        startTime: DateTime(2026, 11, 17, 20),
        turns: _nineDarter, // leg PPR 167
      );
    });

    test('Last 1 is the most recently started game, whatever its id',
        () async {
      final last1 = await statsRepo.getPlayerStats(_playerId,
          gameType: GameType.x01, legLimit: 1);
      final history = await statsRepo.getPlayerLegHistory(_playerId,
          gameType: GameType.x01, limit: 1);

      expect(history.single.gameId, '0000-new');
      expect(last1.bestLegPpr, closeTo(167.0, 0.5));
      expect(last1.threeDartAverage, closeTo(167.0, 0.5));
    });

    test('game count and wins follow the window', () async {
      final all =
          await statsRepo.getPlayerStats(_playerId, gameType: GameType.x01);
      final last1 = await statsRepo.getPlayerStats(_playerId,
          gameType: GameType.x01, legLimit: 1);

      expect(all.totalGames, 2);
      expect(all.gamesWon, 2);
      expect(last1.totalGames, 1);
      expect(last1.gamesWon, 1,
          reason: 'the older game\'s GameCompleted is outside the window');
    });

    test('a window wider than the history equals All', () async {
      final all =
          await statsRepo.getPlayerStats(_playerId, gameType: GameType.x01);
      final last10 = await statsRepo.getPlayerStats(_playerId,
          gameType: GameType.x01, legLimit: 10);

      expect(last10.totalGames, all.totalGames);
      expect(last10.threeDartAverage, all.threeDartAverage);
      expect(last10.bestLegPpr, all.bestLegPpr);
    });
  });

  group("getPlayerStats legLimit: Bob's 27 drills", () {
    late DriftTestBase base;
    late StatisticsRepositoryDrift statsRepo;

    setUp(() async {
      base = DriftTestBase();
      await base.setUp();
      statsRepo = StatisticsRepositoryDrift(base.db);
      await base.db.rawInsert('players', {
        'player_id': _playerId,
        'name': 'P',
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    });

    tearDown(() async => base.tearDown());

    /// One round-1 dart at D[hitSegment], then the drill ends.
    /// D1 is a hit (27 + 2 = 29); any other double is a miss (27 - 2 = 25).
    Future<void> drill(String gameId, DateTime start, int hitSegment) async {
      final db = base.db;
      await db.rawInsert('games', {
        'game_id': gameId,
        'game_type': GameType.bobs27.name,
        'config_json': jsonEncode({}),
        'start_time': start.toIso8601String(),
        'is_complete': 1,
      });
      await db.rawInsert('competitors', {
        'competitor_id': '$gameId-c',
        'game_id': gameId,
        'type': 'solo',
        'name': 'P',
      });
      await db.rawInsert('competitor_players', {
        'competitor_id': '$gameId-c',
        'player_id': _playerId,
        'rotation_position': 0,
      });
      final events = <(String, Map<String, dynamic>)>[
        ('TurnStarted', {'player_id': _playerId}),
        (
          'DartThrown',
          {
            'player_id': _playerId,
            'segment': hitSegment,
            'multiplier': 2,
            'score': hitSegment * 2,
          }
        ),
        ('TurnEnded', {'player_id': _playerId, 'reason': 'normal'}),
        ('GameCompleted', {'winner_player_id': _playerId}),
      ];
      var seq = 1;
      for (final (type, payload) in events) {
        await db.rawInsert('game_events', {
          'event_id': '$gameId-e$seq',
          'game_id': gameId,
          'event_type': type,
          'local_sequence': seq++,
          'occurred_at': start.toIso8601String(),
          'payload_json': jsonEncode(payload),
          'synced': 0,
          'actor_id': _playerId,
          'source': EventSource.client.index,
        });
      }
    }

    test('Last 1 is the newest drill only', () async {
      await drill('g-old', DateTime(2026, 11, 1), 1); // 29
      await drill('g-new', DateTime(2026, 11, 17), 2); // 25

      final all =
          await statsRepo.getPlayerStats(_playerId, gameType: GameType.bobs27);
      final last1 = await statsRepo.getPlayerStats(_playerId,
          gameType: GameType.bobs27, legLimit: 1);

      expect(all.bobs27AvgScore, closeTo(27.0, 0.01));
      expect(all.bobs27BestScore, 29);
      expect(all.totalGames, 2);
      expect(last1.bobs27AvgScore, closeTo(25.0, 0.01));
      expect(last1.bobs27BestScore, 25);
      expect(last1.totalGames, 1);
    });

    test('Last 2 of 3 drills drops the oldest one', () async {
      await drill('a-new', DateTime(2026, 11, 17), 1); // 29
      await drill('z-old', DateTime(2026, 11, 1), 1); // 29
      await drill('m-mid', DateTime(2026, 11, 10), 2); // 25

      final last2 = await statsRepo.getPlayerStats(_playerId,
          gameType: GameType.bobs27, legLimit: 2);

      expect(last2.totalGames, 2);
      expect(last2.bobs27AvgScore, closeTo(27.0, 0.01));
      expect(last2.bobs27BestScore, 29);
    });
  });
}

/// Appends a complete solo X01 game made of [turns], started at [startTime]. Each turn is a list of
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
  required DateTime startTime,
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
