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
import 'package:dart_lodge/features/statistics/presentation/state/player_stats_page_state.dart';

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

  test(
      'setCricketTargetMode clears selectedCricketVariant so a stale '
      'scoring filter does not silently narrow the cohort query', () async {
    final notifier =
        container.read(playerStatsPageProvider('p1').notifier);
    // Start on fixed mode with a scoring variant selected.
    notifier.setCricketVariant('standard');
    expect(
      container.read(playerStatsPageProvider('p1')).selectedCricketVariant,
      'standard',
    );

    // Switching cohort must reset the variant filter — the variant chip
    // row is fixed-only, so a persisted 'standard' selection on Random
    // would invisibly drop all results to zero.
    notifier.setCricketTargetMode('random');

    final s = container.read(playerStatsPageProvider('p1'));
    expect(s.selectedCricketTargetMode, 'random');
    expect(s.selectedCricketVariant, isNull);

    await container.read(filteredCricketStatsProvider('p1').future);
    verify(repo.getPlayerStats(
      'p1',
      gameType: GameType.cricket,
      variant: null,
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

  group('time range forwards the leg window to the repository', () {
    test('All passes no leg limit', () async {
      await container.read(filteredPlayerStatsProvider('p1').future);

      verify(repo.getPlayerStats(
        'p1',
        gameType: GameType.x01,
        startingScore: anyNamed('startingScore'),
        legLimit: null,
      )).called(1);
    });

    test('Last 10 limits X01 stats and leg history to 10 legs', () async {
      container
          .read(playerStatsPageProvider('p1').notifier)
          .setTimeRange(StatsTimeRange.last10);

      await container.read(filteredPlayerStatsProvider('p1').future);
      await container.read(playerLegHistoryProvider('p1').future);

      verify(repo.getPlayerStats(
        'p1',
        gameType: GameType.x01,
        startingScore: anyNamed('startingScore'),
        legLimit: 10,
      )).called(1);
      verify(repo.getPlayerLegHistory(
        'p1',
        gameType: GameType.x01,
        startingScore: anyNamed('startingScore'),
        limit: 10,
      )).called(1);
    });

    test('Last 100 limits Cricket and Practice stats to 100 legs', () async {
      container
          .read(playerStatsPageProvider('p1').notifier)
          .setTimeRange(StatsTimeRange.last100);

      await container.read(filteredCricketStatsProvider('p1').future);
      await container.read(filteredPracticeStatsProvider('p1').future);

      verify(repo.getPlayerStats(
        'p1',
        gameType: GameType.cricket,
        variant: anyNamed('variant'),
        legLimit: 100,
        cricketTargetMode: anyNamed('cricketTargetMode'),
      )).called(1);
      verify(repo.getPlayerStats(
        'p1',
        gameType: argThat(isNot(GameType.cricket), named: 'gameType'),
        legLimit: 100,
      )).called(1);
    });
  });
}
