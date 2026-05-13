// Statistics Repository Contract Tests
// Shared test suite that verifies every StatisticsRepository implementation
// honours the contracts defined in REPOSITORY_INTERFACES.md §5.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import '../drift_test_base.dart';

void runStatisticsRepositoryContractTests(DriftTestBase base) {
  late StatisticsRepository statsRepo;
  late PlayerRepository playerRepo;
  late GameRepository gameRepo;
  late DartThrowRepository dartThrowRepo;
  late GameEventRepository gameEventRepo;

  setUp(() async {
    statsRepo = await base.createStatisticsRepository();
    playerRepo = await base.createPlayerRepository();
    gameRepo = await base.createGameRepository();
    dartThrowRepo = await base.createDartThrowRepository();
    gameEventRepo = await base.createGameEventRepository();
  });

  // ── getGameStats ──────────────────────────────────────────────────────────

  group('getGameStats', () {
    test('throws GameNotFoundException for non-existent game', () async {
      await expectLater(
        statsRepo.getGameStats('non-existent-game'),
        throwsA(isA<GameNotFoundException>()),
      );
    });

    test('returns GameStats with empty competitor list for game with no dart throws', () async {
      await _createPlayerAndGame(playerRepo, gameRepo, playerId: 'p1', gameId: 'g1');

      final stats = await statsRepo.getGameStats('g1');
      expect(stats.gameId, 'g1');
      expect(stats.byCompetitor, isEmpty);
    });

    test('sets gameType to x01 for an X01 game', () async {
      await _createPlayerAndGame(playerRepo, gameRepo, playerId: 'p1', gameId: 'g1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1', score: 60);
      await gameRepo.completeGame(
          gameId: 'g1', winnerCompetitorId: 'c1', endTime: DateTime.now());

      final stats = await statsRepo.getGameStats('g1');
      expect(stats.gameType, GameType.x01.name);
    });

    test('cricket game populates gameType and cricket fields', () async {
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1', gameId: 'g1', competitorId: 'c1');

      final stats = await statsRepo.getGameStats('g1');
      expect(stats.gameType, GameType.cricket.name);
      expect(stats.byCompetitor, hasLength(1));

      final c = stats.byCompetitor.single;
      // Turn 0: 1+3+2 = 6 marks; Turn 1: 3+3+3 = 9 marks → MPR = 15/2 = 7.5
      expect(c.marksPerRound, isNotNull);
      expect(c.marksPerRound!, closeTo(7.5, 0.01));
      // 15 marks across 1 leg of first 9 darts → 15 / (1*3) = 5.0
      expect(c.firstNineMarksPerRound, isNotNull);
      expect(c.firstNineMarksPerRound!, closeTo(5.0, 0.01));
      // Mark buckets are exact-count: turn 0 = exactly 6, turn 1 = exactly 9.
      expect(c.sixMarkTurns, 1);
      expect(c.nineMarkTurns, 1);
    });
  });

  // ── getPlayerStats ────────────────────────────────────────────────────────

  group('getPlayerStats', () {
    test('throws PlayerNotFoundException for non-existent player', () async {
      await expectLater(
        statsRepo.getPlayerStats('non-existent-player',
            gameType: GameType.x01),
        throwsA(isA<PlayerNotFoundException>()),
      );
    });

    test('returns zero stats for player with no dart throws', () async {
      await _createPlayer(playerRepo, 'p1');

      final stats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.x01);
      expect(stats.playerId, 'p1');
      expect(stats.totalDartsThrown, 0);
      expect(stats.threeDartAverage, 0.0);
    });

    test('filters out darts from games of a different gameType', () async {
      await _createPlayerAndGame(playerRepo, gameRepo, playerId: 'p1', gameId: 'g1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1', score: 60);
      await gameRepo.completeGame(gameId: 'g1', winnerCompetitorId: 'c1', endTime: DateTime.now());

      final x01Stats = await statsRepo.getPlayerStats('p1', gameType: GameType.x01);
      final cricketStats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.cricket);

      expect(x01Stats.totalDartsThrown, greaterThan(0));
      expect(cricketStats.totalDartsThrown, 0);
    });
  });

  // ── getPlayerStatsForGame ─────────────────────────────────────────────────

  group('getPlayerStatsForGame', () {
    test('throws GameNotFoundException for non-existent game', () async {
      await expectLater(
        statsRepo.getPlayerStatsForGame('p1', 'non-existent-game'),
        throwsA(isA<GameNotFoundException>()),
      );
    });

    test('throws PlayerNotFoundException when player did not participate', () async {
      await _createPlayerAndGame(playerRepo, gameRepo, playerId: 'p1', gameId: 'g1');
      await _createPlayer(playerRepo, 'p2');

      await expectLater(
        statsRepo.getPlayerStatsForGame('p2', 'g1'),
        throwsA(isA<PlayerNotFoundException>()),
      );
    });

    test('returns stats for a player who participated in the game', () async {
      await _createPlayerAndGame(playerRepo, gameRepo, playerId: 'p1', gameId: 'g1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1', score: 60);
      await gameRepo.completeGame(gameId: 'g1', winnerCompetitorId: 'c1', endTime: DateTime.now());

      final stats = await statsRepo.getPlayerStatsForGame('p1', 'g1');
      expect(stats.playerId, 'p1');
      expect(stats.totalDartsThrown, greaterThan(0));
    });
  });

  // ── watchGameStats ────────────────────────────────────────────────────────

  group('watchGameStats', () {
    test(
        'stream re-fires when a game_events row is appended without a dart insert',
        () async {
      // Regression for issue #129 sub-task 7/8: streams previously watched
      // only `dart_throws`. Event-only writes (LegCompleted, GameCompleted,
      // empty-turn busts via TurnEnded) didn't re-trigger the stream because
      // `game_events` wasn't in the watched-table set.
      await _createPlayerAndGame(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1',
          gameId: 'g1',
          competitorId: 'c1',
          playerId: 'p1',
          score: 60);

      final stream = statsRepo.watchGameStats('g1');
      final emissions = <int>[];
      final sub = stream.listen((stats) {
        // Track per-emission competitor count as a stand-in for "stream
        // produced a value". The exact stat values aren't load-bearing —
        // what matters is that an emission occurred after the event-only
        // write.
        emissions.add(stats.byCompetitor.length);
      });

      // Wait for the initial emission so we observe the stream alive.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final initialCount = emissions.length;
      expect(initialCount, greaterThanOrEqualTo(1),
          reason: 'expected initial emission before event-only write');

      // Append a LegCompleted event — no same-transaction dart insert. On
      // `main` (`cecf6d5`) this does NOT re-trigger the stream because
      // `watchGameStats` only watches `dart_throws`.
      await gameEventRepo.appendEvent(GameEvent(
        eventId: 'g1-evt-leg-completed',
        gameId: 'g1',
        eventType: 'LegCompleted',
        localSequence: 1,
        occurredAt: DateTime.now(),
        payload: {'winner_player_id': 'p1', 'winner_competitor_id': 'c1'},
        synced: false,
        actorId: 'p1',
        source: EventSource.client,
      ));

      // Give the watcher time to react. With the fix, drift sees the
      // game_events write and re-runs the asyncMap, producing a new
      // emission.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await sub.cancel();

      expect(emissions.length, greaterThan(initialCount),
          reason:
              'watchGameStats must re-emit after a game_events-only write');
    });
  });

  // ── watchPlayerStats ──────────────────────────────────────────────────────

  group('watchPlayerStats', () {
    test('returns a Stream<PlayerStats> for X01', () {
      final stream = statsRepo.watchPlayerStats('p1', gameType: GameType.x01);
      expect(stream, isA<Stream>());
    });

    test('returns a Stream<PlayerStats> for cricket', () {
      final stream =
          statsRepo.watchPlayerStats('p1', gameType: GameType.cricket);
      expect(stream, isA<Stream>());
    });

    test('emits an initial value promptly without waiting on a poll tick',
        () async {
      // Regression: the sqflite implementation previously started with
      // Stream.periodic(5s), which delayed the first emission by a full
      // poll interval — making the AVG badge empty for ~5s on subscribe.
      await playerRepo.createPlayer(Player(
        playerId: 'p1',
        name: 'P1',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      ));
      final stream = statsRepo.watchPlayerStats('p1', gameType: GameType.x01);
      final first =
          await stream.first.timeout(const Duration(milliseconds: 1500));
      expect(first.playerId, 'p1');
      expect(first.gameType, GameType.x01);
    });
  });

  // ── Cricket statistics ────────────────────────────────────────────────────

  group('getPlayerStats - cricket', () {
    test('legsPlayed and legsWon are computed from LegCompleted events',
        () async {
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1', gameId: 'g1', competitorId: 'c1');

      final stats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.cricket);
      expect(stats.legsPlayed, 1);
      expect(stats.legsWon, 1);
    });

    test('marksPerTurn is the ratio of total marks to total turns', () async {
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1', gameId: 'g1', competitorId: 'c1');

      final stats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.cricket);
      // Turn 0: '20'=1, 'T19'=3, 'D15'=2 → 6 marks
      // Turn 1: 'T20'=3, 'T20'=3, 'T20'=3 → 9 marks
      // MPT = 15 / 2 = 7.5
      expect(stats.marksPerTurn, isNotNull);
      expect(stats.marksPerTurn!, closeTo(7.5, 0.01));
    });

    test('hitRate reflects fraction of darts landing on cricket targets',
        () async {
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1', gameId: 'g1', competitorId: 'c1');

      final stats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.cricket);
      // All 6 darts hit cricket targets (20, 19, 15 family)
      expect(stats.hitRate, isNotNull);
      expect(stats.hitRate!, closeTo(1.0, 0.01));
    });

    test('sixMarkTurns counts turns with 6 or more marks', () async {
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1', gameId: 'g1', competitorId: 'c1');

      final stats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.cricket);
      expect(stats.sixMarkTurns, 2); // turn 0 (6 marks) and turn 1 (9 marks)
    });

    test('nineMarkTurns counts turns with exactly 9 marks', () async {
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1', gameId: 'g1', competitorId: 'c1');

      final stats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.cricket);
      expect(stats.nineMarkTurns, 1); // only turn 1 (T20+T20+T20)
    });

    test('solo cricket games are excluded from legsPlayed and legsWon (#106)',
        () async {
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1',
          gameId: 'g1',
          competitorId: 'c1',
          multiplayer: false);

      final stats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.cricket);
      expect(stats.legsPlayed, 0);
      expect(stats.legsWon, 0);
      // Other stats from solo games still count.
      expect(stats.marksPerTurn, isNotNull);
      expect(stats.totalDartsThrown, greaterThan(0));
    });

    test(
        'mixed solo + multiplayer cricket games only count multiplayer legs (#106)',
        () async {
      // Solo game: should not contribute to legs counts.
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1',
          gameId: 'g-solo',
          competitorId: 'c-solo',
          multiplayer: false);
      // Multiplayer game: should contribute 1 leg played + 1 won.
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1',
          gameId: 'g-multi',
          competitorId: 'c-multi');

      final stats =
          await statsRepo.getPlayerStats('p1', gameType: GameType.cricket);
      expect(stats.legsPlayed, 1);
      expect(stats.legsWon, 1);
    });
  });

  // ── getPlayerCricketVariants ───────────────────────────────────────────────

  group('getPlayerCricketVariants', () {
    test('returns empty list for player with no completed cricket games',
        () async {
      await _createPlayer(playerRepo, 'p1');

      final variants = await statsRepo.getPlayerCricketVariants('p1');
      expect(variants, isEmpty);
    });

    test('returns variant strings for completed cricket games', () async {
      await _setupCompletedCricketGame(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1', gameId: 'g1', competitorId: 'c1');

      final variants = await statsRepo.getPlayerCricketVariants('p1');
      expect(variants, contains('standard'));
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<void> _createPlayer(PlayerRepository repo, String playerId) async {
  try {
    await repo.createPlayer(Player(
      playerId: playerId,
      name: 'Player $playerId',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    ));
  } on DuplicatePlayerException {
    // Idempotent — tests that compose multiple fixtures may seed the same
    // player more than once.
  }
}

/// Creates a player, a complete game, and a solo competitor linking the two.
/// When [multiplayer] is true (default), also creates a second player and a
/// ghost competitor with no throws so the game qualifies as multiplayer for
/// the issue #106 solo-game filter.
Future<void> _createPlayerAndGame(
  PlayerRepository playerRepo,
  GameRepository gameRepo, {
  required String playerId,
  required String gameId,
  bool multiplayer = true,
}) async {
  await _createPlayer(playerRepo, playerId);
  final competitors = <Competitor>[
    Competitor(
      competitorId: 'c1',
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'Player $playerId',
      players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
    ),
  ];
  if (multiplayer) {
    final opponentId = '${playerId}_opp';
    await _createPlayer(playerRepo, opponentId);
    competitors.add(Competitor(
      competitorId: 'c-opp',
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'Player $opponentId',
      players: [
        CompetitorPlayer(playerId: opponentId, rotationPosition: 1),
      ],
    ));
  }
  await gameRepo.createGame(
    Game(
      gameId: gameId,
      gameType: GameType.x01,
      config: const GameConfig.x01(
        startingScore: 501,
        inStrategy: 'straight',
        outStrategy: 'double',
      ),
      startTime: DateTime.now(),
      isComplete: false,
    ),
    competitors,
  );
}

Future<void> _createDartThrow(
  DartThrowRepository repo, {
  required String dartId,
  required String gameId,
  required String competitorId,
  required String playerId,
  required int score,
}) async {
  await repo.insertDart(DartThrow(
    dartId: dartId,
    gameId: gameId,
    competitorId: competitorId,
    playerId: playerId,
    turnNumber: 1,
    dartNumber: 1,
    segment: 'T20',
    score: score,
  ));
}

/// Creates a player + completed cricket game with two turns of darts and
/// matching game events so the test data is valid for both the Drift
/// (SQL over dart_throws) and SQLite (projection engine over game_events)
/// implementations.
///
/// Turn 0: '20' (1 mark), 'T19' (3 marks), 'D15' (2 marks) → 6 marks
/// Turn 1: 'T20' (3 marks), 'T20' (3 marks), 'T20' (3 marks) → 9 marks
/// Total: 15 marks, 6 darts, 2 turns → MPT 7.5, hitRate 1.0,
///        sixMarkTurns 2, nineMarkTurns 1, legsPlayed 1, legsWon 1.
Future<void> _setupCompletedCricketGame(
  PlayerRepository playerRepo,
  GameRepository gameRepo,
  DartThrowRepository dartThrowRepo,
  GameEventRepository gameEventRepo, {
  required String playerId,
  required String gameId,
  required String competitorId,
  bool multiplayer = true,
}) async {
  await _createPlayer(playerRepo, playerId);

  final competitors = <Competitor>[
    Competitor(
      competitorId: competitorId,
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'Player $playerId',
      players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
    ),
  ];
  if (multiplayer) {
    final opponentId = '${playerId}_opp';
    await _createPlayer(playerRepo, opponentId);
    competitors.add(Competitor(
      competitorId: '${competitorId}_opp',
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'Player $opponentId',
      players: [
        CompetitorPlayer(playerId: opponentId, rotationPosition: 1),
      ],
    ));
  }
  await gameRepo.createGame(
    Game(
      gameId: gameId,
      gameType: GameType.cricket,
      config: const GameConfig.cricket(
        variant: 'standard',
        numbers: ['15', '16', '17', '18', '19', '20', 'bull'],
        legsToWin: 1,
      ),
      startTime: DateTime.now(),
      isComplete: false,
    ),
    competitors,
  );

  // dart_throws — queried directly by the Drift implementation.
  final darts = [
    DartThrow(dartId: '$gameId-d1', gameId: gameId, competitorId: competitorId, playerId: playerId, turnNumber: 0, dartNumber: 1, segment: '20',  score: 20),
    DartThrow(dartId: '$gameId-d2', gameId: gameId, competitorId: competitorId, playerId: playerId, turnNumber: 0, dartNumber: 2, segment: 'T19', score: 57),
    DartThrow(dartId: '$gameId-d3', gameId: gameId, competitorId: competitorId, playerId: playerId, turnNumber: 0, dartNumber: 3, segment: 'D15', score: 30),
    DartThrow(dartId: '$gameId-d4', gameId: gameId, competitorId: competitorId, playerId: playerId, turnNumber: 1, dartNumber: 1, segment: 'T20', score: 60),
    DartThrow(dartId: '$gameId-d5', gameId: gameId, competitorId: competitorId, playerId: playerId, turnNumber: 1, dartNumber: 2, segment: 'T20', score: 60),
    DartThrow(dartId: '$gameId-d6', gameId: gameId, competitorId: competitorId, playerId: playerId, turnNumber: 1, dartNumber: 3, segment: 'T20', score: 60),
  ];
  for (final d in darts) {
    await dartThrowRepo.insertDart(d);
  }

  // game_events — replayed by the SQLite projection engine.
  int seq = 1;
  Future<void> appendEvent(
      String type, Map<String, dynamic> payload) async {
    await gameEventRepo.appendEvent(GameEvent(
      eventId: '$gameId-e${seq}',
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

  await appendEvent('TurnStarted', {'player_id': playerId});
  await appendEvent('DartThrown', {'player_id': playerId, 'segment': '20'});
  await appendEvent('DartThrown', {'player_id': playerId, 'segment': 'T19'});
  await appendEvent('DartThrown', {'player_id': playerId, 'segment': 'D15'});
  await appendEvent('TurnEnded',  {'player_id': playerId});
  await appendEvent('TurnStarted', {'player_id': playerId});
  await appendEvent('DartThrown', {'player_id': playerId, 'segment': 'T20'});
  await appendEvent('DartThrown', {'player_id': playerId, 'segment': 'T20'});
  await appendEvent('DartThrown', {'player_id': playerId, 'segment': 'T20'});
  await appendEvent('TurnEnded',  {'player_id': playerId});
  await appendEvent('LegCompleted', {
    'winner_player_id': playerId,
    'winner_competitor_id': competitorId,
  });
  await appendEvent('GameCompleted', {
    'winner_player_id': playerId,
    'winner_competitor_id': competitorId,
  });

  await gameRepo.completeGame(
    gameId: gameId,
    winnerCompetitorId: competitorId,
    endTime: DateTime.now(),
  );
}
