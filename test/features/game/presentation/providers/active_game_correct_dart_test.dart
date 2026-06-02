// Notifier-level coverage for per-dart correction (#376): drives the real
// ActiveGameNotifier.correctTurnDart against in-memory drift repos (overriding
// the repository providers), exercising the on-demand index→eventId resolver,
// the full wired use-case path, and the bust-banner recomputation.

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_game_provider.dart';
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

  // Seeds a solo X01 game with [startingScore] + an opening TurnStarted, builds
  // a container that routes the notifier through in-memory drift, and returns
  // the loaded notifier.
  Future<ActiveGameNotifier> seedAndLoad({int startingScore = 501}) async {
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
        gameType: GameType.x01,
        config: GameConfig.x01(
            startingScore: startingScore,
            inStrategy: 'straight',
            outStrategy: 'double'),
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
        'starting_score': startingScore,
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
    await container.read(activeGameProvider('g1').future);
    return container.read(activeGameProvider('g1').notifier);
  }

  test('correctTurnDart replaces the resolved dart and recomputes the score',
      () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('20'); // dart 1
    await notifier.processDart('20'); // dart 2 → score 461
    expect(container.read(activeGameProvider('g1')).value!.gameState
        .competitors[0].score, 461);

    await notifier.correctTurnDart(0, '5'); // 20 → 5

    final gs = container.read(activeGameProvider('g1')).value!.gameState;
    expect(gs.competitors[0].score, 501 - 5 - 20); // 476
    expect(gs.dartsThrownInTurn, 2);
    final darts = gs.competitors[0].dartThrows;
    expect(darts.sublist(darts.length - 2), ['5', '20']);
  });

  test('correctTurnDart is a no-op for an out-of-range dart index', () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('20'); // only 1 dart this turn
    await notifier.correctTurnDart(2, '5'); // index 2 doesn't exist

    final gs = container.read(activeGameProvider('g1')).value!.gameState;
    expect(gs.competitors[0].score, 481); // unchanged
    expect(gs.dartsThrownInTurn, 1);
  });

  test('a downward correction in a completed turn does NOT flash a bust banner',
      () async {
    final notifier = await seedAndLoad();

    await notifier.processDart('T20'); // 441
    await notifier.processDart('T20'); // 381
    await notifier.processDart('T15'); // 336 — normal 3-dart turn, no bust

    await notifier.correctTurnDart(0, '1'); // T20 → single 1

    final state = container.read(activeGameProvider('g1')).value!;
    expect(state.gameState.competitors[0].score, 501 - 1 - 60 - 45); // 395
    expect(state.showBust, isFalse); // regression guard: was true before #383 fix
  });

  test('a correction that introduces a bust flashes the bust banner', () async {
    final notifier = await seedAndLoad(startingScore: 100);

    await notifier.processDart('20'); // 80
    await notifier.processDart('20'); // 60
    await notifier.processDart('20'); // 40 — no bust

    // Correct dart 1 to T20: 100-60-20-20 = 0 reached on a single → bust,
    // score restored to 100.
    await notifier.correctTurnDart(0, 'T20');

    final state = container.read(activeGameProvider('g1')).value!;
    expect(state.gameState.competitors[0].score, 100);
    expect(state.showBust, isTrue);
  });
}
