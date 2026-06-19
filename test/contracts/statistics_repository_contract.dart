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
      // Only 2 turns (6 darts) — first-9 MPR is undefined until the
      // player has at least 3 turns (9 darts) on record. Mirrors the
      // gate added in #290 for X01's first-9 PPR.
      expect(c.firstNineMarksPerRound, isNull);
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

    test(
        'startingScore filter matches games whose config has that startingScore (#154)',
        () async {
      // The fixture configures the X01 game with startingScore: 501. Pre-#154
      // the loader read `cfg['starting_score']` (snake_case) while the on-disk
      // JSON encoding uses camelCase (`startingScore`), so this filter
      // silently matched nothing. With the fix, `startingScore: 501` matches
      // the fixture game and yields a non-zero dart count; `startingScore: 301`
      // matches no games and yields zero darts.
      await _createPlayerAndGame(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1',
          gameId: 'g1',
          competitorId: 'c1',
          playerId: 'p1',
          score: 60);
      await gameRepo.completeGame(
          gameId: 'g1',
          winnerCompetitorId: 'c1',
          endTime: DateTime.now());

      final matchingStats = await statsRepo.getPlayerStats('p1',
          gameType: GameType.x01, startingScore: 501);
      final nonMatchingStats = await statsRepo.getPlayerStats('p1',
          gameType: GameType.x01, startingScore: 301);

      expect(matchingStats.totalDartsThrown, greaterThan(0));
      expect(nonMatchingStats.totalDartsThrown, 0);
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
    test('emits an initial GameStats snapshot scoped to the requested game',
        () async {
      // Positive-path contract: subscribing to watchGameStats must emit a
      // [GameStats] for [gameId] (not for some other game), and that initial
      // emission must arrive promptly without waiting on a poll tick.
      await _createPlayerAndGame(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1',
          gameId: 'g1',
          competitorId: 'c1',
          playerId: 'p1',
          score: 60);

      final stream = statsRepo.watchGameStats('g1');
      final first =
          await stream.first.timeout(const Duration(milliseconds: 1500));
      expect(first.gameId, 'g1');
      expect(first.byCompetitor, isNotEmpty);
    });

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

  // ── getPlayerLegHistory ───────────────────────────────────────────────────

  group('getPlayerLegHistory', () {
    test('returns empty list for player with no completed games', () async {
      await _createPlayer(playerRepo, 'p1');

      final history = await statsRepo.getPlayerLegHistory('p1');
      expect(history, isEmpty);
    });

    test('returns one snapshot per LegCompleted event for the player',
        () async {
      // Drive the leg-snapshot projection with a canonical X01 event stream
      // (numeric `segment` + `multiplier` payloads — see
      // `buildDartThrownEvent` in CLAUDE.md). One leg, one LegCompleted →
      // one snapshot.
      await _setupCompletedX01Game(
          playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
          playerId: 'p1', gameId: 'g1', competitorId: 'c1');

      final history =
          await statsRepo.getPlayerLegHistory('p1', gameType: GameType.x01);
      expect(history, hasLength(1));
      final snap = history.single;
      expect(snap.gameId, 'g1');
      expect(snap.legIndex, 1);
      // The fixture configures the X01 game with startingScore: 501 (see
      // `_setupCompletedX01Game`). With the cfg key fix in #154, the loader
      // now reads `cfg['startingScore']` correctly from the camelCase JSON
      // encoding on disk, so `snap.startingScore` populates as expected.
      expect(snap.startingScore, 501);
      // PPR is event-driven (not config-driven) so it remains a valid positive
      // check: 6 T20s + closing T20+T19+D12 over 9 darts → PPR ≈ 167.
      expect(snap.ppr, greaterThan(0.0));
    });

    test(
      'multi-game history loads in start_time order without cross-bleed',
      () async {
        // Regression for the N+1 → single-query refactor: load events for
        // every filtered game in one batched SELECT, then group by gameId
        // in Dart. The assembler is invoked per-game so events from
        // different games (each with their own per-game `local_sequence`
        // sequence restarting at 1) must NOT interleave or bleed.
        //
        // This test seeds two completed X01 games for the same player and
        // asserts: both snapshots are returned, in start_time ASC order,
        // with the correct gameId attribution and accumulating legIndex.
        await _setupCompletedX01Game(
            playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
            playerId: 'p1', gameId: 'g1', competitorId: 'c1');
        await _setupCompletedX01Game(
            playerRepo, gameRepo, dartThrowRepo, gameEventRepo,
            playerId: 'p1', gameId: 'g2', competitorId: 'c2');

        final history =
            await statsRepo.getPlayerLegHistory('p1', gameType: GameType.x01);
        expect(history, hasLength(2));

        // start_time ASC ordering preserved from the games query.
        expect(history[0].gameId, 'g1');
        expect(history[1].gameId, 'g2');

        // legIndex accumulates monotonically across games (1, then 2).
        expect(history[0].legIndex, 1);
        expect(history[1].legIndex, 2);

        // Both snapshots resolved their own startingScore (no cross-bleed
        // from one game's config_json into the other's snapshot).
        expect(history[0].startingScore, 501);
        expect(history[1].startingScore, 501);

        // Both completed identically (same fixture), so PPR is positive
        // and equal — proves events were grouped correctly per gameId.
        expect(history[0].ppr, greaterThan(0.0));
        expect(history[1].ppr, equals(history[0].ppr));
      },
    );
  });

  // ── getPlayerX01StartingScores ────────────────────────────────────────────

  group('getPlayerX01StartingScores', () {
    test('returns empty list for player with no completed X01 games',
        () async {
      await _createPlayer(playerRepo, 'p1');

      final scores = await statsRepo.getPlayerX01StartingScores('p1');
      expect(scores, isEmpty);
    });

    test('returns the distinct startingScores of completed X01 games',
        () async {
      // Contract: method returns the distinct `startingScore` values from
      // every completed X01 game the player participated in. The fixture
      // `_createPlayerAndGame` configures `startingScore: 501`, so the
      // returned list must contain 501.
      //
      // Pre-#154 this loader read `cfg['starting_score']` from
      // `g.config_json`, but the JSON encoding uses camelCase
      // (`startingScore`), so the method returned `[]` for every player.
      // With the fix, the assertion below is meaningful.
      await _createPlayerAndGame(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1');
      await gameRepo.completeGame(
          gameId: 'g1',
          winnerCompetitorId: 'c1',
          endTime: DateTime.now());

      final scores = await statsRepo.getPlayerX01StartingScores('p1');
      expect(scores, [501]);
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

    test(
        'returns variants for cricket games where player threw no darts '
        '(regression for #193)', () async {
      // Player registered as a competitor but never took a turn (e.g. game
      // was created and immediately abandoned/auto-completed). Pre-fix the
      // SQL joined through dart_throws which dropped the row entirely.
      await _createPlayer(playerRepo, 'p1');
      await gameRepo.createGame(
        Game(
          gameId: 'g-empty',
          gameType: GameType.cricket,
          config: const GameConfig.cricket(
            scoring: 'cut-throat',
            numbers: ['15', '16', '17', '18', '19', '20', 'bull'],
            legsToWin: 1,
          ),
          startTime: DateTime.now(),
          isComplete: false,
        ),
        [
          Competitor(
            competitorId: 'c-empty',
            gameId: 'g-empty',
            type: CompetitorType.solo,
            name: 'Player p1',
            players: [
              const CompetitorPlayer(playerId: 'p1', rotationPosition: 0),
            ],
          ),
        ],
      );
      await gameRepo.completeGame(
        gameId: 'g-empty',
        winnerCompetitorId: null,
        endTime: DateTime.now(),
      );

      final variants = await statsRepo.getPlayerCricketVariants('p1');
      expect(variants, contains('cut-throat'),
          reason:
              'variant must appear even when the player threw no darts in '
              'the cricket game');
    });
  });

  // ── getDartPositions ──────────────────────────────────────────────────────

  group('getDartPositions', () {
    test('returns located positions for a player, excluding NULL-position darts',
        () async {
      await _createPlayerAndGame(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1');
      // Two located darts + one NULL-position dart (manual entry).
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1',
          score: 60, x: 0.1, y: -0.2, segment: 'T20');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd2', gameId: 'g1', competitorId: 'c1', playerId: 'p1',
          score: 20, x: 0.5, y: 0.5, segment: '20');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd3', gameId: 'g1', competitorId: 'c1', playerId: 'p1',
          score: 5, segment: '5'); // no x/y → excluded
      await gameRepo.completeGame(
          gameId: 'g1', winnerCompetitorId: 'c1', endTime: DateTime.now());

      final positions = await statsRepo.getDartPositions(playerId: 'p1');
      expect(positions, hasLength(2));
      expect(positions.map((p) => p.segment), containsAll(['T20', '20']));
      final t20 = positions.firstWhere((p) => p.segment == 'T20');
      expect(t20.x, closeTo(0.1, 1e-9));
      expect(t20.y, closeTo(-0.2, 1e-9));
    });

    test('filters by gameId', () async {
      // Only one incomplete game may exist at a time, and competitor IDs are
      // globally unique — complete each game (with its own competitor) before
      // starting the next.
      await _createX01GameAt(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1', startTime: DateTime.now(),
          competitorId: 'c1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1',
          score: 60, x: 0.1, y: 0.1, segment: 'T20');
      await gameRepo.completeGame(
          gameId: 'g1', winnerCompetitorId: 'c1', endTime: DateTime.now());

      await _createX01GameAt(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g2', startTime: DateTime.now(),
          competitorId: 'c2');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd2', gameId: 'g2', competitorId: 'c2', playerId: 'p1',
          score: 20, x: 0.2, y: 0.2, segment: '20');
      await gameRepo.completeGame(
          gameId: 'g2', winnerCompetitorId: 'c2', endTime: DateTime.now());

      final positions =
          await statsRepo.getDartPositions(playerId: 'p1', gameId: 'g1');
      expect(positions, hasLength(1));
      expect(positions.single.segment, 'T20');
    });

    test('filters by player', () async {
      await _createPlayerAndGame(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1');
      // Opponent 'p1_opp' is seeded by the multiplayer fixture; give them a
      // located dart too and ensure it is not returned for p1.
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1',
          score: 60, x: 0.1, y: 0.1, segment: 'T20');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd2', gameId: 'g1', competitorId: 'c-opp',
          playerId: 'p1_opp', score: 20, x: 0.9, y: 0.9, segment: '20');
      await gameRepo.completeGame(
          gameId: 'g1', winnerCompetitorId: 'c1', endTime: DateTime.now());

      final positions = await statsRepo.getDartPositions(playerId: 'p1');
      expect(positions, hasLength(1));
      expect(positions.single.segment, 'T20');
    });

    test('filters by gameType', () async {
      // X01 game (via the shared fixture) + a cricket game, both for p1.
      await _createPlayerAndGame(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g-x01');
      await _createDartThrow(dartThrowRepo,
          dartId: 'dx', gameId: 'g-x01', competitorId: 'c1', playerId: 'p1',
          score: 60, x: 0.1, y: 0.1, segment: 'T20');
      await gameRepo.completeGame(
          gameId: 'g-x01', winnerCompetitorId: 'c1', endTime: DateTime.now());

      await _createCricketGameWithLocatedDart(playerRepo, gameRepo,
          dartThrowRepo,
          playerId: 'p1', gameId: 'g-cri', competitorId: 'cc1',
          dartId: 'dc', x: 0.3, y: 0.3, segment: '17');

      final x01Positions = await statsRepo.getDartPositions(
          playerId: 'p1', gameType: GameType.x01);
      expect(x01Positions, hasLength(1));
      expect(x01Positions.single.segment, 'T20');

      final cricketPositions = await statsRepo.getDartPositions(
          playerId: 'p1', gameType: GameType.cricket);
      expect(cricketPositions, hasLength(1));
      expect(cricketPositions.single.segment, '17');
    });

    test('filters by date window (from/to on game start_time)', () async {
      final old = DateTime(2020, 1, 1);
      final recent = DateTime(2024, 6, 1);
      await _createX01GameAt(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g-old', startTime: old,
          competitorId: 'c-old');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd-old', gameId: 'g-old', competitorId: 'c-old',
          playerId: 'p1', score: 60, x: 0.1, y: 0.1, segment: 'T20');
      await gameRepo.completeGame(
          gameId: 'g-old', winnerCompetitorId: 'c-old', endTime: old);

      await _createX01GameAt(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g-new', startTime: recent,
          competitorId: 'c-new');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd-new', gameId: 'g-new', competitorId: 'c-new',
          playerId: 'p1', score: 20, x: 0.2, y: 0.2, segment: '20');
      await gameRepo.completeGame(
          gameId: 'g-new', winnerCompetitorId: 'c-new', endTime: recent);

      final windowed = await statsRepo.getDartPositions(
        playerId: 'p1',
        from: DateTime(2024, 1, 1),
        to: DateTime(2024, 12, 31),
      );
      expect(windowed, hasLength(1));
      expect(windowed.single.segment, '20');
    });

    test('returns empty list for a player with no located darts', () async {
      await _createPlayerAndGame(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1',
          score: 5, segment: '5'); // no x/y
      await gameRepo.completeGame(
          gameId: 'g1', winnerCompetitorId: 'c1', endTime: DateTime.now());

      final positions = await statsRepo.getDartPositions(playerId: 'p1');
      expect(positions, isEmpty);
    });

    test('excludes located darts from incomplete (in-progress) games',
        () async {
      // Game is created but never completed — its located darts must NOT leak
      // into any result. Would FAIL if the `is_complete = 1` gate were removed.
      await _createX01GameAt(playerRepo, gameRepo,
          playerId: 'p1', gameId: 'g1', startTime: DateTime.now(),
          competitorId: 'c1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1',
          score: 60, x: 0.1, y: 0.1, segment: 'T20');
      // Intentionally NOT completing the game.

      final positions = await statsRepo.getDartPositions(playerId: 'p1');
      expect(positions, isEmpty);
    });

    test('throws PlayerNotFoundException for non-existent player', () async {
      expect(
        () => statsRepo.getDartPositions(playerId: 'nope'),
        throwsA(isA<PlayerNotFoundException>()),
      );
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
  String segment = 'T20',
  double? x,
  double? y,
}) async {
  await repo.insertDart(DartThrow(
    dartId: dartId,
    gameId: gameId,
    competitorId: competitorId,
    playerId: playerId,
    turnNumber: 1,
    dartNumber: 1,
    segment: segment,
    score: score,
    x: x,
    y: y,
  ));
}

/// Creates a player + incomplete X01 game with a chosen [startTime] and a solo
/// competitor `c1`. Caller inserts darts then calls `completeGame`.
Future<void> _createX01GameAt(
  PlayerRepository playerRepo,
  GameRepository gameRepo, {
  required String playerId,
  required String gameId,
  required DateTime startTime,
  String competitorId = 'c1',
}) async {
  await _createPlayer(playerRepo, playerId);
  await gameRepo.createGame(
    Game(
      gameId: gameId,
      gameType: GameType.x01,
      config: const GameConfig.x01(
        startingScore: 501,
        inStrategy: 'straight',
        outStrategy: 'double',
      ),
      startTime: startTime,
      isComplete: false,
    ),
    [
      Competitor(
        competitorId: competitorId,
        gameId: gameId,
        type: CompetitorType.solo,
        name: 'Player $playerId',
        players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
      ),
    ],
  );
}

/// Creates a player + completed cricket game holding a single located dart.
/// Used to verify the gameType filter of `getDartPositions`.
Future<void> _createCricketGameWithLocatedDart(
  PlayerRepository playerRepo,
  GameRepository gameRepo,
  DartThrowRepository dartThrowRepo, {
  required String playerId,
  required String gameId,
  required String competitorId,
  required String dartId,
  required double x,
  required double y,
  required String segment,
}) async {
  await _createPlayer(playerRepo, playerId);
  await gameRepo.createGame(
    Game(
      gameId: gameId,
      gameType: GameType.cricket,
      config: const GameConfig.cricket(
        scoring: 'standard',
        numbers: ['15', '16', '17', '18', '19', '20', 'bull'],
        legsToWin: 1,
      ),
      startTime: DateTime.now(),
      isComplete: false,
    ),
    [
      Competitor(
        competitorId: competitorId,
        gameId: gameId,
        type: CompetitorType.solo,
        name: 'Player $playerId',
        players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
      ),
    ],
  );
  await _createDartThrow(dartThrowRepo,
      dartId: dartId, gameId: gameId, competitorId: competitorId,
      playerId: playerId, score: 17, x: x, y: y, segment: segment);
  await gameRepo.completeGame(
      gameId: gameId, winnerCompetitorId: competitorId, endTime: DateTime.now());
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
        scoring: 'standard',
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

/// Creates a player + completed X01 game (501, straight/double) with three
/// turns of canonical-payload events. Used by leg-history positive-path tests.
///
/// Turns: 180 + 180 + 141 (T20+T19+D12) → 501 checkout in 9 darts.
Future<void> _setupCompletedX01Game(
  PlayerRepository playerRepo,
  GameRepository gameRepo,
  DartThrowRepository dartThrowRepo,
  GameEventRepository gameEventRepo, {
  required String playerId,
  required String gameId,
  required String competitorId,
}) async {
  await _createPlayer(playerRepo, playerId);

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
    [
      Competitor(
        competitorId: competitorId,
        gameId: gameId,
        type: CompetitorType.solo,
        name: 'Player $playerId',
        players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
      ),
    ],
  );

  int seq = 1;
  int dartNum = 0;
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

  Future<void> throwDart(int turnNumber, int dartNumber, String segment,
      int score, int segValue, int mult) async {
    dartNum++;
    await dartThrowRepo.insertDart(DartThrow(
      dartId: '$gameId-d$dartNum',
      gameId: gameId,
      competitorId: competitorId,
      playerId: playerId,
      turnNumber: turnNumber,
      dartNumber: dartNumber,
      segment: segment,
      score: score,
    ));
    await appendEvent('DartThrown', {
      'competitor_id': competitorId,
      'player_id': playerId,
      'segment': segValue,
      'multiplier': mult,
      'score': score,
      'input_method': 'manual',
    });
  }

  // Turn 1: T20 T20 T20 = 180 (501 → 321)
  await appendEvent('TurnStarted', {
    'competitor_id': competitorId,
    'player_id': playerId,
    'starting_score': 501,
    'turn_index': 0,
    'leg_index': 0,
  });
  await throwDart(0, 1, 'T20', 60, 20, 3);
  await throwDart(0, 2, 'T20', 60, 20, 3);
  await throwDart(0, 3, 'T20', 60, 20, 3);
  await appendEvent('TurnEnded', {
    'competitor_id': competitorId,
    'player_id': playerId,
    'reason': 'normal',
  });

  // Turn 2: T20 T20 T20 = 180 (321 → 141)
  await appendEvent('TurnStarted', {
    'competitor_id': competitorId,
    'player_id': playerId,
    'starting_score': 321,
    'turn_index': 1,
    'leg_index': 0,
  });
  await throwDart(1, 1, 'T20', 60, 20, 3);
  await throwDart(1, 2, 'T20', 60, 20, 3);
  await throwDart(1, 3, 'T20', 60, 20, 3);
  await appendEvent('TurnEnded', {
    'competitor_id': competitorId,
    'player_id': playerId,
    'reason': 'normal',
  });

  // Turn 3: T20 T19 D12 = 141 checkout
  await appendEvent('TurnStarted', {
    'competitor_id': competitorId,
    'player_id': playerId,
    'starting_score': 141,
    'turn_index': 2,
    'leg_index': 0,
  });
  await throwDart(2, 1, 'T20', 60, 20, 3);
  await throwDart(2, 2, 'T19', 57, 19, 3);
  await throwDart(2, 3, 'D12', 24, 12, 2);
  await appendEvent('TurnEnded', {
    'competitor_id': competitorId,
    'player_id': playerId,
    'reason': 'normal',
  });

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
