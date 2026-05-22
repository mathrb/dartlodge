// Asserts that the Cricket tab's stats / leg-history providers forward the
// page state's `selectedCricketTargetMode` to the repository — closing
// the loop on #260 where the loader accepted the cohort filter but the
// page had no plumbing to drive it.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:dart_lodge/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/player_stats_page_provider.dart';

import 'player_stats_page_provider_test.mocks.dart';

@GenerateMocks([StatisticsRepository])
void main() {
  late ProviderContainer container;
  late MockStatisticsRepository repo;

  PlayerStats _emptyStats() => const PlayerStats(
        playerId: 'p1',
        gameType: GameType.cricket,
        totalGames: 0,
        gamesWon: 0,
        winRate: 0.0,
        threeDartAverage: 0.0,
        highestTurnScore: 0,
        totalDartsThrown: 0,
        dartsPerLeg: 0.0,
        bustRate: 0.0,
      );

  setUp(() {
    repo = MockStatisticsRepository();
    when(repo.getPlayerStats(
      any,
      gameType: anyNamed('gameType'),
      from: anyNamed('from'),
      to: anyNamed('to'),
      startingScore: anyNamed('startingScore'),
      variant: anyNamed('variant'),
      legLimit: anyNamed('legLimit'),
      cricketTargetMode: anyNamed('cricketTargetMode'),
    )).thenAnswer((_) async => _emptyStats());
    when(repo.getPlayerLegHistory(
      any,
      gameType: anyNamed('gameType'),
      startingScore: anyNamed('startingScore'),
      variant: anyNamed('variant'),
      limit: anyNamed('limit'),
      cricketTargetMode: anyNamed('cricketTargetMode'),
    )).thenAnswer((_) async => const <PlayerLegSnapshot>[]);

    container = ProviderContainer(
      overrides: [
        statisticsRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('filteredCricketStats defaults cohort to fixed', () async {
    await container.read(filteredCricketStatsProvider('p1').future);

    verify(repo.getPlayerStats(
      'p1',
      gameType: GameType.cricket,
      variant: anyNamed('variant'),
      legLimit: anyNamed('legLimit'),
      cricketTargetMode: 'fixed',
    )).called(1);
  });

  test('setCricketTargetMode("random") flows through to the loader', () async {
    container
        .read(playerStatsPageProvider('p1').notifier)
        .setCricketTargetMode('random');

    await container.read(filteredCricketStatsProvider('p1').future);

    verify(repo.getPlayerStats(
      'p1',
      gameType: GameType.cricket,
      variant: anyNamed('variant'),
      legLimit: anyNamed('legLimit'),
      cricketTargetMode: 'random',
    )).called(1);
  });

  test('setCricketTargetMode("crazy") flows through to leg history',
      () async {
    container
        .read(playerStatsPageProvider('p1').notifier)
        .setCricketTargetMode('crazy');

    await container.read(cricketLegHistoryProvider('p1').future);

    verify(repo.getPlayerLegHistory(
      'p1',
      gameType: GameType.cricket,
      variant: anyNamed('variant'),
      limit: anyNamed('limit'),
      cricketTargetMode: 'crazy',
    )).called(1);
  });
}
