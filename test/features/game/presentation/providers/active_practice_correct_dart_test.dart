// Notifier-level coverage for manual practice correction (#799): drives the
// real ActivePracticeNotifier against in-memory drift repos.
//
// `targetBeforeTurnDart` is what lets the manual Around the Clock correction
// bar offer the target a dart was thrown at: a hit advances the target
// mid-turn, so the live target is already the next one.

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_practice_provider.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../../../../drift_test_base.dart';

void main() {
  late DriftTestBase base;
  late ProviderContainer container;

  setUp(() async {
    base = DriftTestBase();
    await base.setUp();
  });

  tearDown(() async {
    container.dispose();
    await base.tearDown();
  });

  // Seeds a solo Around the Clock game + an opening TurnStarted, routes the
  // notifier through in-memory drift, and returns the loaded notifier.
  Future<ActivePracticeNotifier> seedAndLoad(
      {String variant = 'standard'}) async {
    final playerRepo = await base.createPlayerRepository();
    final gameRepo = await base.createGameRepository();
    final dartRepo = await base.createDartThrowRepository();
    final eventRepo = await base.createGameEventRepository();

    await playerRepo.createPlayer(Player(
        playerId: 'p1',
        name: 'P1',
        createdAt: DateTime.now(),
        lastActive: DateTime.now()));

    await gameRepo.createGame(
      Game(
        gameId: 'g1',
        gameType: GameType.aroundTheClock,
        config: GameConfig.aroundTheClock(variant: variant),
        startTime: DateTime.now(),
        isComplete: false,
      ),
      const [
        Competitor(
          competitorId: 'c1',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'P1',
          players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
      ],
    );
    await eventRepo.appendEvent(GameEvent(
      eventId: 'g1-ts0',
      gameId: 'g1',
      eventType: 'TurnStarted',
      localSequence: 1,
      occurredAt: DateTime.now(),
      payload: {
        'competitor_id': 'c1',
        'player_id': 'p1',
        'turn_index': 0,
        'leg_index': 0,
      },
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    ));

    container = ProviderContainer(overrides: [
      gameRepositoryProvider.overrideWithValue(gameRepo),
      gameEventRepositoryProvider.overrideWithValue(eventRepo),
      dartThrowRepositoryProvider.overrideWithValue(dartRepo),
    ]);
    await container.read(activePracticeProvider('g1').future);
    return container.read(activePracticeProvider('g1').notifier);
  }

  GameState gameState() =>
      container.read(activePracticeProvider('g1')).value!.gameState;

  test('targetBeforeTurnDart returns the target each dart was thrown at',
      () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('1'); // hit 1 → target 2
    await notifier.processDart('MISS');
    await notifier.processDart('2'); // hit 2 → target 3
    expect(gameState().competitors[0].currentTarget, 3);

    expect(await notifier.targetBeforeTurnDart(0), 1);
    expect(await notifier.targetBeforeTurnDart(1), 2);
    expect(await notifier.targetBeforeTurnDart(2), 2);
  });

  test('targetBeforeTurnDart resolves a miss the turn alone cannot place',
      () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('1');
    await notifier.processDart('2');
    await notifier.processDart('3'); // target 4
    await notifier.startNextTurn();
    // [4, MISS] alone fits a turn start of either 4 or 5; the log says 4.
    await notifier.processDart('5'); // miss at 4
    await notifier.processDart('MISS');
    expect(gameState().competitors[0].currentTarget, 4);

    expect(await notifier.targetBeforeTurnDart(0), 4);
    expect(await notifier.targetBeforeTurnDart(1), 4);
  });

  test('targetBeforeTurnDart follows the reverse variant', () async {
    final notifier = await seedAndLoad(variant: 'reverse');

    await notifier.processDart('20'); // hit 20 → target 19
    expect(gameState().competitors[0].currentTarget, 19);

    expect(await notifier.targetBeforeTurnDart(0), 20);
  });

  test('targetBeforeTurnDart sees through an earlier correction', () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('1'); // → target 2
    await notifier.processDart('2'); // → target 3
    await notifier.correctTurnDart(0, 'MISS'); // dart 1 never hit: target 1
    expect(gameState().competitors[0].currentTarget, 1);

    expect(await notifier.targetBeforeTurnDart(0), 1);
    expect(await notifier.targetBeforeTurnDart(1), 1);
  });

  test('correctTurnDart rolls back the advance a corrected hit made', () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('1'); // → target 2
    await notifier.processDart('MISS');
    await notifier.processDart('2'); // → target 3

    // Dart 1 was really a miss: 1 is never hit, so the later '2' doesn't count.
    await notifier.correctTurnDart(0, 'MISS');

    final gs = gameState();
    expect(gs.competitors[0].currentTarget, 1);
    expect(gs.dartsThrownInTurn, 3);
    final darts = gs.competitors[0].dartThrows;
    expect(darts.sublist(darts.length - 3), ['MISS', 'MISS', '2']);
  });
}
