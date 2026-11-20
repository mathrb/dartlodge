// The X01 notifier exposes undo at the start of a new leg, and undoing there
// reopens the won leg (the leg-winning dart was previously undoable only
// before the leg ended). Drives the real notifier against a captured event
// log, so the undo replays exactly what the dart action persisted.
//
// The mocks are reused from `active_game_notifier_test.mocks.dart`
// (`GameRepository`/`GameEventRepository`/`DartThrowRepository` are generic).

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_game_provider.dart';

import 'active_game_notifier_test.mocks.dart';

void main() {
  late ProviderContainer container;
  late List<GameEvent> log;

  setUp(() {
    log = [
      GameEvent(
        eventId: 'e-turn-1',
        gameId: 'g1',
        eventType: 'TurnStarted',
        localSequence: 1,
        occurredAt: DateTime(2025),
        payload: const {'competitor_id': 'c1', 'turn_index': 0, 'leg_index': 0},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      ),
    ];

    final gameRepo = MockGameRepository();
    final eventRepo = MockGameEventRepository();
    final dartRepo = MockDartThrowRepository();

    when(gameRepo.getGame('g1')).thenAnswer(
      (_) async => Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 40,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: 2,
        ),
        startTime: DateTime(2025),
        isComplete: false,
      ),
    );
    when(gameRepo.getCompetitors('g1')).thenAnswer(
      (_) async => [
        Competitor(
          competitorId: 'c1',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'Player 1',
          players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
        Competitor(
          competitorId: 'c2',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'Player 2',
          players: [CompetitorPlayer(playerId: 'p2', rotationPosition: 1)],
        ),
      ],
    );
    when(
      eventRepo.getEventsForGame('g1'),
    ).thenAnswer((_) async => List<GameEvent>.of(log));
    when(
      eventRepo.getLatestSequence(any),
    ).thenAnswer((_) async => log.last.localSequence);
    when(eventRepo.appendEvent(any)).thenAnswer((inv) async {
      log.add(inv.positionalArguments[0] as GameEvent);
    });
    when(eventRepo.appendEvents(any)).thenAnswer((inv) async {
      log.addAll((inv.positionalArguments[0] as List).cast<GameEvent>());
    });
    when(dartRepo.insertDart(any)).thenAnswer((_) async {});
    when(dartRepo.deleteDart(any)).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(gameRepo),
        gameEventRepositoryProvider.overrideWithValue(eventRepo),
        dartThrowRepositoryProvider.overrideWithValue(dartRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('undo after a won leg reopens it and clears the leg modal', () async {
    await container.read(activeGameProvider('g1').future);
    final notifier = container.read(activeGameProvider('g1').notifier);

    await notifier.processDart('20');
    await notifier.processDart('D10');

    final won = container.read(activeGameProvider('g1')).value!;
    expect(won.pendingLegWinnerId, 'c1');
    expect(won.gameState.currentLegIndex, 1);
    expect(
      notifier.canUndo,
      isTrue,
      reason: 'the leg-winning dart is still undoable in the new leg',
    );

    await notifier.undoDart();

    final undone = container.read(activeGameProvider('g1')).value!;
    expect(undone.pendingLegWinnerId, isNull);
    expect(undone.gameState.currentLegIndex, 0);
    expect(undone.gameState.currentTurnIndex, 0);
    expect(undone.gameState.dartsThrownInTurn, 1);
    expect(undone.gameState.competitors[0].score, 20);
    expect(undone.gameState.competitors[0].legsWon, 0);
  });
}
