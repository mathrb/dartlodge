// Statistics Repository Contract Tests
// Shared test suite that verifies every StatisticsRepository implementation
// honours the contracts defined in REPOSITORY_INTERFACES.md §5.

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:my_darts/features/players/domain/repositories/player_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:my_darts/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/entities/dart_throw.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/utils/constants.dart';
import '../database_test_base.dart';

void runStatisticsRepositoryContractTests(DatabaseTestBase base) {
  late StatisticsRepository statsRepo;
  late PlayerRepository playerRepo;
  late GameRepository gameRepo;
  late DartThrowRepository dartThrowRepo;

  setUp(() async {
    statsRepo = await base.createStatisticsRepository();
    playerRepo = await base.createPlayerRepository();
    gameRepo = await base.createGameRepository();
    dartThrowRepo = await base.createDartThrowRepository();
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
  });

  // ── getPlayerStats ────────────────────────────────────────────────────────

  group('getPlayerStats', () {
    test('throws PlayerNotFoundException for non-existent player', () async {
      await expectLater(
        statsRepo.getPlayerStats('non-existent-player'),
        throwsA(isA<PlayerNotFoundException>()),
      );
    });

    test('returns zero stats for player with no dart throws', () async {
      await _createPlayer(playerRepo, 'p1');

      final stats = await statsRepo.getPlayerStats('p1');
      expect(stats.playerId, 'p1');
      expect(stats.totalDartsThrown, 0);
      expect(stats.threeDartAverage, 0.0);
    });

    test('filters out darts from games of a different gameType', () async {
      await _createPlayerAndGame(playerRepo, gameRepo, playerId: 'p1', gameId: 'g1');
      await _createDartThrow(dartThrowRepo,
          dartId: 'd1', gameId: 'g1', competitorId: 'c1', playerId: 'p1', score: 60);

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

      final stats = await statsRepo.getPlayerStatsForGame('p1', 'g1');
      expect(stats.playerId, 'p1');
      expect(stats.totalDartsThrown, greaterThan(0));
    });
  });

  // ── getLeaderboard ────────────────────────────────────────────────────────

  group('getLeaderboard', () {
    test('returns empty list when no players meet minGames requirement', () async {
      final leaderboard = await statsRepo.getLeaderboard(
        gameType: GameType.x01,
        minGames: 100,
      );
      expect(leaderboard, isEmpty);
    });

    test('respects the limit parameter', () async {
      final leaderboard = await statsRepo.getLeaderboard(
        gameType: GameType.x01,
        minGames: 1,
        limit: 5,
      );
      expect(leaderboard.length, lessThanOrEqualTo(5));
    });
  });

  // ── watchPlayerStats ──────────────────────────────────────────────────────

  group('watchPlayerStats', () {
    test('returns a Stream<PlayerStats>', () {
      final stream = statsRepo.watchPlayerStats('p1');
      expect(stream, isA<Stream>());
    });

    test('returns a Stream<PlayerStats> when gameType filter is provided', () {
      final stream = statsRepo.watchPlayerStats('p1', gameType: GameType.x01);
      expect(stream, isA<Stream>());
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<void> _createPlayer(PlayerRepository repo, String playerId) async {
  await repo.createPlayer(Player(
    playerId: playerId,
    name: 'Player $playerId',
    createdAt: DateTime.now(),
    lastActive: DateTime.now(),
  ));
}

/// Creates a player, a complete game, and a solo competitor linking the two.
Future<void> _createPlayerAndGame(
  PlayerRepository playerRepo,
  GameRepository gameRepo, {
  required String playerId,
  required String gameId,
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
        competitorId: 'c1',
        gameId: gameId,
        type: CompetitorType.solo,
        name: 'Player $playerId',
        players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
      ),
    ],
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
