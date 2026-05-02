import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_cricket_game_provider.dart';
import 'package:riverpod/riverpod.dart';

import 'active_cricket_game_notifier_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late ProviderContainer container;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  // ── helpers ──────────────────────────────────────────────────────────────

  Game makeGame() => Game(
        gameId: 'g1',
        gameType: GameType.cricket,
        config: GameConfig.cricket(
          variant: 'standard',
          numbers: ['15', '16', '17', '18', '19', '20', 'bull'],
          legsToWin: 1,
        ),
        startTime: DateTime(2025),
      );

  List<Competitor> makeCompetitors() => [
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
          players: [CompetitorPlayer(playerId: 'p2', rotationPosition: 0)],
        ),
      ];

  GameEvent turnStartedEvent({
    String competitorId = 'c1',
    int turnIndex = 0,
    int seq = 1,
  }) =>
      GameEvent(
        eventId: 'e-turn-$seq',
        gameId: 'g1',
        eventType: 'TurnStarted',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': competitorId,
          'turn_index': turnIndex,
          'leg_index': 0,
        },
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

  GameEvent dartThrownEvent({
    required String competitorId,
    required int segment,
    required int multiplier,
    required int seq,
  }) =>
      GameEvent(
        eventId: 'e-dart-$seq',
        gameId: 'g1',
        eventType: 'DartThrown',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': competitorId,
          'segment': segment,
          'multiplier': multiplier,
          'input_method': 'manual',
        },
        synced: false,
        actorId: competitorId == 'c1' ? 'p1' : 'p2',
        source: EventSource.client,
      );

  // Builds 18 events that leave c1 with all 6 numbers closed and 2 Bull marks.
  // After replaying these, processDart('SB') → 3rd Bull mark → c1 wins.
  //
  // Turn 1 (c1): T20, T19, T18         → closes 20, 19, 18
  // Turn 2 (c2): MISS, MISS, MISS
  // Turn 3 (c1): T17, T16, T15         → closes 17, 16, 15
  // Turn 4 (c2): MISS, MISS, MISS
  // Turn 5 (c1): DB (2 Bull marks, turn still active at dart 1)
  List<GameEvent> makeNearCompleteEvents() {
    int seq = 0;
    return [
      // Turn 1 — c1
      turnStartedEvent(competitorId: 'c1', turnIndex: 0, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 20, multiplier: 3, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 19, multiplier: 3, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 18, multiplier: 3, seq: ++seq),
      // Turn 2 — c2
      turnStartedEvent(competitorId: 'c2', turnIndex: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
      // Turn 3 — c1
      turnStartedEvent(competitorId: 'c1', turnIndex: 0, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 17, multiplier: 3, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 16, multiplier: 3, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 15, multiplier: 3, seq: ++seq),
      // Turn 4 — c2
      turnStartedEvent(competitorId: 'c2', turnIndex: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
      // Turn 5 — c1 (DB = 2 Bull marks; turn still active after 1 dart)
      turnStartedEvent(competitorId: 'c1', turnIndex: 0, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 25, multiplier: 2, seq: ++seq),
    ];
  }

  void stubBuild({List<GameEvent> events = const []}) {
    when(mockGameRepo.getGame('g1')).thenAnswer((_) async => makeGame());
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => makeCompetitors());
    when(mockEventRepo.getEventsForGame('g1'))
        .thenAnswer((_) async => events);
  }

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();

    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 1);
    when(mockDartRepo.insertDart(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvents(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvent(any)).thenAnswer((_) async {});
    when(mockDartRepo.deleteDart(any)).thenAnswer((_) async {});
    when(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(mockGameRepo),
        gameEventRepositoryProvider.overrideWithValue(mockEventRepo),
        dartThrowRepositoryProvider.overrideWithValue(mockDartRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  // ── 1. build returns null when game not found ─────────────────────────────

  test('build returns null when getGame returns null', () async {
    when(mockGameRepo.getGame('g1')).thenAnswer((_) async => null);

    final result =
        await container.read(activeCricketGameProvider('g1').future);

    expect(result, isNull);
  });

  // ── 2. build replays TurnStarted and returns ActiveCricketGameState ───────

  test('build replays TurnStarted event and returns ActiveCricketGameState',
      () async {
    stubBuild(events: [turnStartedEvent()]);

    final result =
        await container.read(activeCricketGameProvider('g1').future);

    expect(result, isNotNull);
    expect(result!.gameState.turnActive, true);
    expect(result.gameState.currentTurnIndex, 0);
    expect(result.gameState.competitors[0].marksPerNumber, isEmpty);
    expect(result.pendingLegWinnerId, null);
    expect(result.pendingGameWinnerId, null);
  });

  // ── 3. processDart updates marks (T20 → 3 marks on 20) ───────────────────

  test('processDart adds 3 marks on 20 when T20 is thrown', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeCricketGameProvider('g1').future);

    await container
        .read(activeCricketGameProvider('g1').notifier)
        .processDart('T20');

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.gameState.competitors[0].marksPerNumber['20'], 3);
    expect(s.gameState.dartsThrownInTurn, 1);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 4. processDart sets pendingGameWinnerId on game completion ───────────

  test('processDart sets pendingGameWinnerId when game completes', () async {
    stubBuild(events: makeNearCompleteEvents());
    await container.read(activeCricketGameProvider('g1').future);

    // SB is the 3rd Bull mark → closes all numbers → c1 wins
    await container
        .read(activeCricketGameProvider('g1').notifier)
        .processDart('SB');

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.pendingGameWinnerId, 'c1');
    expect(s.gameState.isComplete, true);
  });

  // ── 5. pendingLegWinnerId is null when game completes ────────────────────
  //
  // Cricket has legsToWin=1, so a leg win always coincides with game
  // completion. The legCompleted check (legIndex increased AND !isComplete)
  // is never true, so pendingLegWinnerId stays null.

  test('pendingLegWinnerId is null when game completes (legsToWin=1)', () async {
    stubBuild(events: makeNearCompleteEvents());
    await container.read(activeCricketGameProvider('g1').future);

    await container
        .read(activeCricketGameProvider('g1').notifier)
        .processDart('SB');

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, 'c1');
  });

  // ── 6. undoDart reverts gameState and clears pending IDs ─────────────────

  test('undoDart reverts gameState and resets all pending fields', () async {
    final events = [
      turnStartedEvent(),
      dartThrownEvent(
          competitorId: 'c1', segment: 20, multiplier: 3, seq: 2),
    ];
    stubBuild(events: events);
    await container.read(activeCricketGameProvider('g1').future);

    final before = container.read(activeCricketGameProvider('g1')).value!;
    expect(before.gameState.competitors[0].marksPerNumber['20'], 3);
    expect(before.gameState.dartsThrownInTurn, 1);

    await container
        .read(activeCricketGameProvider('g1').notifier)
        .undoDart();

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.gameState.competitors[0].marksPerNumber['20'], null);
    expect(s.gameState.dartsThrownInTurn, 0);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 7. dismissLegModal clears pendingLegWinnerId ─────────────────────────

  test('dismissLegModal sets pendingLegWinnerId to null, other fields unchanged',
      () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeCricketGameProvider('g1').future);

    final before = container.read(activeCricketGameProvider('g1')).value!;

    container
        .read(activeCricketGameProvider('g1').notifier)
        .dismissLegModal();

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
    expect(s.gameState, before.gameState);
  });

  // ── 8a. undoDart is a no-op when no darts have been thrown ──────────────

  test('undoDart is a no-op when no darts have been thrown in the game',
      () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeCricketGameProvider('g1').future);

    final before = container.read(activeCricketGameProvider('g1')).value!;
    expect(before.gameState.dartsThrownInTurn, 0);

    await container
        .read(activeCricketGameProvider('g1').notifier)
        .undoDart();

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s, before);
  });

  // ── 8b. undoDart at turn boundary rolls back into previous turn ──────────

  test('undoDart at turn boundary restores last dart of previous turn',
      () async {
    // Turn 1 (c1): T20 (closes 20), T19 (closes 19), T18 (closes 18) → turn ends
    // Turn 2 (c2): starts — dartsThrownInTurn == 0
    final events = [
      turnStartedEvent(competitorId: 'c1', turnIndex: 0, seq: 1),
      dartThrownEvent(competitorId: 'c1', segment: 20, multiplier: 3, seq: 2),
      dartThrownEvent(competitorId: 'c1', segment: 19, multiplier: 3, seq: 3),
      dartThrownEvent(competitorId: 'c1', segment: 18, multiplier: 3, seq: 4),
      turnStartedEvent(competitorId: 'c2', turnIndex: 1, seq: 5),
    ];
    stubBuild(events: events);
    await container.read(activeCricketGameProvider('g1').future);

    final before = container.read(activeCricketGameProvider('g1')).value!;
    expect(before.gameState.currentTurnIndex, 1); // c2's turn
    expect(before.gameState.dartsThrownInTurn, 0);

    await container
        .read(activeCricketGameProvider('g1').notifier)
        .undoDart();

    final s = container.read(activeCricketGameProvider('g1')).value!;
    // After undoing T18, c1 should be active with 2 darts thrown
    expect(s.gameState.dartsThrownInTurn, 2);
    expect(s.gameState.competitors[0].marksPerNumber['20'], 3); // 20 still closed
    expect(s.gameState.competitors[0].marksPerNumber['19'], 3); // 19 still closed
    expect(s.gameState.competitors[0].marksPerNumber['18'], isNull); // 18 undone
  });

  // ── 8. dismissGameModal clears pendingGameWinnerId ───────────────────────

  test(
      'dismissGameModal sets pendingGameWinnerId to null, other fields unchanged',
      () async {
    stubBuild(events: makeNearCompleteEvents());
    await container.read(activeCricketGameProvider('g1').future);
    await container
        .read(activeCricketGameProvider('g1').notifier)
        .processDart('SB');
    final afterGame =
        container.read(activeCricketGameProvider('g1')).value!;
    expect(afterGame.pendingGameWinnerId, 'c1');

    container
        .read(activeCricketGameProvider('g1').notifier)
        .dismissGameModal();

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.pendingGameWinnerId, null);
    expect(s.pendingLegWinnerId, null);
    expect(s.gameState, afterGame.gameState);
  });

  // ── Round cap tests ──────────────────────────────────────────────────────

  // Reconfigures the mock to return a cricket game with totalRounds set.
  Game makeGameWithCap({
    String variant = 'standard',
    int totalRounds = 1,
    int legsToWin = 1,
  }) =>
      Game(
        gameId: 'g1',
        gameType: GameType.cricket,
        config: GameConfig.cricket(
          variant: variant,
          numbers: const ['15', '16', '17', '18', '19', '20', 'bull'],
          legsToWin: legsToWin,
          totalRounds: totalRounds,
        ),
        startTime: DateTime(2025),
      );

  GameEvent turnEndedEvent({
    required String competitorId,
    required int seq,
  }) =>
      GameEvent(
        eventId: 'e-te-$seq',
        gameId: 'g1',
        eventType: 'TurnEnded',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {'competitor_id': competitorId, 'player_id': 'p1'},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

  // Events that drive state to: round 1 complete for both players, c2's
  // turn is done (3 misses), ready for cap-triggering TurnEnded via
  // nextPlayer().
  List<GameEvent> makeCapBoundaryEvents() {
    int seq = 0;
    return [
      turnStartedEvent(competitorId: 'c1', turnIndex: 0, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 0, multiplier: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 0, multiplier: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c1', segment: 0, multiplier: 1, seq: ++seq),
      turnEndedEvent(competitorId: 'c1', seq: ++seq),
      turnStartedEvent(competitorId: 'c2', turnIndex: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
      dartThrownEvent(competitorId: 'c2', segment: 0, multiplier: 1, seq: ++seq),
    ];
  }

  test(
      'nextPlayer at round cap with tied scores → pendingCapSelection (ambiguous)',
      () async {
    when(mockGameRepo.getGame('g1'))
        .thenAnswer((_) async => makeGameWithCap(totalRounds: 1));
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => makeCompetitors());
    when(mockEventRepo.getEventsForGame('g1'))
        .thenAnswer((_) async => makeCapBoundaryEvents());
    await container.read(activeCricketGameProvider('g1').future);

    await container
        .read(activeCricketGameProvider('g1').notifier)
        .nextPlayer();

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.pendingCapSelection, true);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
    expect(s.gameState.isComplete, false);
    // Competitors' legsWon unchanged until user picks
    expect(s.gameState.competitors[0].legsWon, 0);
    expect(s.gameState.competitors[1].legsWon, 0);
  });

  test(
      'selectCapWinner finalizes leg, emits LegCompleted + GameCompleted, '
      'marks game complete', () async {
    when(mockGameRepo.getGame('g1'))
        .thenAnswer((_) async => makeGameWithCap(totalRounds: 1));
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => makeCompetitors());
    when(mockEventRepo.getEventsForGame('g1'))
        .thenAnswer((_) async => makeCapBoundaryEvents());
    await container.read(activeCricketGameProvider('g1').future);
    await container
        .read(activeCricketGameProvider('g1').notifier)
        .nextPlayer();

    // User picks c2 as the winner
    await container
        .read(activeCricketGameProvider('g1').notifier)
        .selectCapWinner('c2');

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.pendingCapSelection, false);
    expect(s.pendingGameWinnerId, 'c2');
    expect(s.gameState.isComplete, true);
    expect(s.gameState.winnerCompetitorId, 'c2');
    verify(mockGameRepo.completeGame(
      gameId: 'g1',
      winnerCompetitorId: 'c2',
      endTime: anyNamed('endTime'),
    )).called(1);
  });

  test(
      'selectCapWinner is a no-op when pendingCapSelection is false',
      () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeCricketGameProvider('g1').future);

    await container
        .read(activeCricketGameProvider('g1').notifier)
        .selectCapWinner('c1');

    final s = container.read(activeCricketGameProvider('g1')).value!;
    expect(s.gameState.isComplete, false);
    expect(s.pendingGameWinnerId, null);
    verifyNever(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    ));
  });
}
