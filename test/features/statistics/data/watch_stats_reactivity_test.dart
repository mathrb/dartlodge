// Verifies the sqflite watchPlayerStats / watchGameStats reactivity chain:
// a write through DartThrowRepositoryImpl publishes to DataChangeNotifier
// which the StatisticsRepositoryImpl subscribes to and re-emits.
//
// Drift has its own per-query reactivity via .watch() and is covered by
// the existing hybrid contract suite — this test is sqflite-only.

import 'package:dart_lodge/core/persistence/data_change_notifier.dart';
import 'package:dart_lodge/core/persistence/database_migrations.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/data/repositories/dart_throw_repository_impl.dart';
import 'package:dart_lodge/features/game/data/repositories/game_event_repository_impl.dart';
import 'package:dart_lodge/features/game/data/repositories/game_repository_impl.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/players/data/repositories/player_repository_impl.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DataChangeNotifier notifier;
  late PlayerRepositoryImpl playerRepo;
  late GameRepositoryImpl gameRepo;
  late DartThrowRepositoryImpl dartRepo;
  late GameEventRepositoryImpl eventRepo;
  late StatisticsRepositoryImpl statsRepo;

  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON;');
    await DatabaseMigrations.createSchema(db);

    notifier = DataChangeNotifier();
    playerRepo = PlayerRepositoryImpl(db);
    gameRepo = GameRepositoryImpl(db, changeNotifier: notifier);
    dartRepo = DartThrowRepositoryImpl(db, changeNotifier: notifier);
    eventRepo = GameEventRepositoryImpl(db, changeNotifier: notifier);
    statsRepo = StatisticsRepositoryImpl(db, changeNotifier: notifier);
  });

  tearDown(() async {
    notifier.dispose();
    await db.close();
  });

  Future<void> seedPlayerAndGame({
    String playerId = 'p1',
    String gameId = 'g1',
    String competitorId = 'c1',
  }) async {
    await playerRepo.createPlayer(Player(
      playerId: playerId,
      name: 'P',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    ));
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
          name: 'P',
          players: [
            CompetitorPlayer(playerId: playerId, rotationPosition: 0),
          ],
        ),
      ],
    );
  }

  DartThrow _dart({
    String dartId = 'd1',
    String gameId = 'g1',
    String competitorId = 'c1',
    String playerId = 'p1',
  }) =>
      DartThrow(
        dartId: dartId,
        gameId: gameId,
        competitorId: competitorId,
        playerId: playerId,
        turnNumber: 1,
        dartNumber: 1,
        segment: 'T20',
        score: 60,
      );

  test('watchGameStats re-emits when a dart_throw is inserted', () async {
    await seedPlayerAndGame();

    final emissions = <int>[];
    final sub = statsRepo.watchGameStats('g1').listen((stats) {
      emissions.add(stats.byCompetitor.length);
    });

    // Wait for the initial emission.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions, [0]);

    // Insert a dart — should publish a change → re-query → new emission.
    await dartRepo.insertDart(_dart());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // After the insert there's now 1 competitor with throws.
    expect(emissions.length, 2);
    expect(emissions.last, 1);

    await sub.cancel();
  });

  test('watchGameStats does NOT re-emit on writes without notifier hookup',
      () async {
    // Re-build a stats repo with no notifier — confirms that without the
    // wiring there are no post-initial emissions (regression guard).
    final isolatedStats = StatisticsRepositoryImpl(db);
    await seedPlayerAndGame();

    final emissions = <int>[];
    final sub = isolatedStats.watchGameStats('g1').listen((stats) {
      emissions.add(stats.byCompetitor.length);
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.length, 1); // initial only

    // Insert via the wired-up dartRepo — its notifier ticks, but the
    // isolated stats repo isn't subscribed to it.
    await dartRepo.insertDart(_dart());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.length, 1); // still no further emission

    await sub.cancel();
  });

  test('watchPlayerStats re-emits when an event is appended', () async {
    await seedPlayerAndGame();

    final emissions = <PlayerStats>[];
    final sub = statsRepo
        .watchPlayerStats('p1', gameType: GameType.x01)
        .listen(emissions.add);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.length, 1);

    // Use the dart repo (any registered write triggers the notifier).
    await dartRepo.insertDart(_dart());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.length, greaterThanOrEqualTo(2));
    await sub.cancel();
  });

  test('watchGameStats re-emits on appendEvent (covers GameEvent publisher)',
      () async {
    await seedPlayerAndGame();

    final emissions = <int>[];
    final sub = statsRepo.watchGameStats('g1').listen((stats) {
      emissions.add(stats.byCompetitor.length);
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.length, 1);

    // Append an event — should publish a change.
    await eventRepo.appendEvent(GameEvent(
      eventId: 'e1',
      gameId: 'g1',
      eventType: 'TurnStarted',
      localSequence: 1,
      occurredAt: DateTime.now(),
      payload: const {'player_id': 'p1'},
      synced: false,
      actorId: 'p1',
      source: EventSource.client,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions.length, greaterThanOrEqualTo(2));
    await sub.cancel();
  });
}
