import 'dart:async';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/achievement_watcher_provider.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:dart_lodge/features/achievements/domain/repositories/achievement_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'achievement_watcher_provider_test.mocks.dart';

@GenerateMocks([GameRepository, StatisticsRepository, AchievementRepository])
void main() {
  late MockGameRepository game;
  late MockStatisticsRepository stats;
  late MockAchievementRepository achievements;
  late StreamController<List<Game>> completed;
  late ProviderContainer container;
  late List<List<dynamic>> recorded;

  Game gameWith(String id) => Game(
        gameId: id,
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
        ),
        startTime: DateTime(2024),
      );

  void stubCompetitors(String gameId, List<String> playerIds) {
    when(game.getCompetitors(gameId)).thenAnswer((_) async => [
          Competitor(
            competitorId: 'c-$gameId',
            gameId: gameId,
            type: CompetitorType.solo,
            name: 'Comp',
            players: [
              for (var i = 0; i < playerIds.length; i++)
                CompetitorPlayer(playerId: playerIds[i], rotationPosition: i),
            ],
          ),
        ]);
  }

  // total180s:1 → unlocks the binary 'first_180' (threshold null ⇒ 1).
  const oneEighty = (
    total180s: 1,
    highestCheckout: 0,
    totalWins: 0,
    totalDartsThrown: 3,
    games501Played: 0,
    hasNineDarter: false,
  );

  List<List<dynamic>> emissionsFor(ProviderContainer c) {
    final out = <List<dynamic>>[];
    c.listen(achievementWatcherProvider, (prev, next) {
      final v = next.value;
      if (next.hasValue && v != null) out.add(v);
    }, fireImmediately: true);
    return out;
  }

  setUp(() {
    game = MockGameRepository();
    stats = MockStatisticsRepository();
    achievements = MockAchievementRepository();
    completed = StreamController<List<Game>>();
    recorded = [];

    when(game.watchCompletedGames()).thenAnswer((_) => completed.stream);
    when(stats.achievementMetricsForPlayer(any))
        .thenAnswer((_) async => oneEighty);
    when(achievements.getUnlocked(any)).thenAnswer((_) async => <String>{});
    when(achievements.recordUnlock(any, any, any, gameId: anyNamed('gameId')))
        .thenAnswer((inv) async {
      recorded.add([
        inv.positionalArguments[0],
        inv.positionalArguments[1],
        inv.namedArguments[#gameId],
      ]);
    });

    container = ProviderContainer(overrides: [
      gameRepositoryProvider.overrideWithValue(game),
      statisticsRepositoryProvider.overrideWithValue(stats),
      achievementRepositoryProvider.overrideWithValue(achievements),
    ]);
    addTearDown(container.dispose);
    addTearDown(completed.close);
  });

  test('a new threshold-crossing completion emits the unlock + records it',
      () async {
    final emissions = emissionsFor(container);
    stubCompetitors('g1', ['p1']);

    completed.add(const []); // initial snapshot (skipped)
    await pumpEventQueue();
    completed.add([gameWith('g1')]); // new completion
    await pumpEventQueue();

    expect(emissions, hasLength(1));
    expect(emissions.single, hasLength(1));
    final unlocked = emissions.single.single;
    expect(unlocked.achievement.id, 'first_180');
    expect(unlocked.playerId, 'p1');
    expect(unlocked.gameId, 'g1');
    expect(recorded, [
      ['p1', 'first_180', 'g1']
    ]);
  });

  test('an already-unlocked game emits nothing and records nothing', () async {
    when(achievements.getUnlocked(any))
        .thenAnswer((_) async => {'first_180'}); // already earned
    final emissions = emissionsFor(container);
    stubCompetitors('g1', ['p1']);

    completed.add(const []);
    await pumpEventQueue();
    completed.add([gameWith('g1')]);
    await pumpEventQueue();

    expect(emissions, isEmpty);
    expect(recorded, isEmpty);
    // Prove the diff path actually consulted getUnlocked (not short-circuited).
    verify(achievements.getUnlocked('p1')).called(1);
  });

  test('re-emitting the same completed game is not reprocessed', () async {
    final emissions = emissionsFor(container);
    stubCompetitors('g1', ['p1']);

    completed.add(const []);
    await pumpEventQueue();
    completed.add([gameWith('g1')]);
    await pumpEventQueue();
    completed.add([gameWith('g1')]); // same id again (e.g. another table write)
    await pumpEventQueue();

    expect(emissions, hasLength(1)); // processed once
    expect(recorded, hasLength(1));
    verify(game.getCompetitors('g1')).called(1);
  });

  test('the initial snapshot is skipped (no backfill)', () async {
    final emissions = emissionsFor(container);
    stubCompetitors('g1', ['p1']);

    // The very first emission carries a game that WOULD cross a threshold.
    completed.add([gameWith('g1')]);
    await pumpEventQueue();

    expect(emissions, isEmpty);
    expect(recorded, isEmpty);
    verifyNever(game.getCompetitors(any));
  });
}
