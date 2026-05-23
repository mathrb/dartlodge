import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_game_provider.dart';
import 'package:riverpod/riverpod.dart';

import 'active_game_notifier_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late ProviderContainer container;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  // ── helpers ──────────────────────────────────────────────────────────────

  Game makeGame({int legsToWin = 1}) => Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: GameConfig.x01(
          startingScore: 40,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: legsToWin,
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

  GameEvent turnStartedEvent({String competitorId = 'c1', int seq = 1}) =>
      GameEvent(
        eventId: 'e-turn-$seq',
        gameId: 'g1',
        eventType: 'TurnStarted',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': competitorId,
          'turn_index': 0,
          'leg_index': 0,
        },
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

  GameEvent dartThrownEvent({
    required int segment,
    required int multiplier,
    int seq = 2,
    String eventId = 'e-dart',
  }) =>
      GameEvent(
        eventId: eventId,
        gameId: 'g1',
        eventType: 'DartThrown',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': 'c1',
          'segment': segment,
          'multiplier': multiplier,
          'input_method': 'manual',
        },
        synced: false,
        actorId: 'p1',
        source: EventSource.client,
      );

  void stubBuild({
    int legsToWin = 1,
    List<GameEvent> events = const [],
  }) {
    when(mockGameRepo.getGame('g1'))
        .thenAnswer((_) async => makeGame(legsToWin: legsToWin));
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => makeCompetitors());
    when(mockEventRepo.getEventsForGame('g1'))
        .thenAnswer((_) async => events);
  }

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();

    // Common stubs shared across tests
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

    final result = await container.read(activeGameProvider('g1').future);

    expect(result, isNull);
  });

  // ── 2. build replays TurnStarted and returns ActiveGameState ──────────────

  test('build replays TurnStarted event and returns ActiveGameState', () async {
    stubBuild(events: [turnStartedEvent()]);

    final result = await container.read(activeGameProvider('g1').future);

    expect(result, isNotNull);
    expect(result!.gameState.turnActive, true);
    expect(result.gameState.currentTurnIndex, 0);
    expect(result.gameState.competitors[0].score, 40);
    expect(result.showBust, false);
    expect(result.pendingLegWinnerId, null);
    expect(result.pendingGameWinnerId, null);
  });

  // ── 3. processDart updates score ─────────────────────────────────────────

  test('processDart updates score when dart scores', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    await container.read(activeGameProvider('g1').notifier).processDart('20');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.gameState.competitors[0].score, 20);
    expect(s.showBust, false);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 4. processDart sets showBust on bust ──────────────────────────────────

  test('processDart sets showBust when dart busts (T20 from 40)', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    // T20 = 60 > 40 → bust; score restored to turnStartScore = 40
    await container.read(activeGameProvider('g1').notifier).processDart('T20');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.showBust, true);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 5. processDart sets pendingLegWinnerId on leg completion ─────────────

  test('processDart sets pendingLegWinnerId when leg completes (not game)',
      () async {
    stubBuild(legsToWin: 2, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    // D20 = 40 = exact checkout; legsToWin:2 so only leg ends
    await container.read(activeGameProvider('g1').notifier).processDart('D20');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingLegWinnerId, 'c1');
    expect(s.pendingGameWinnerId, null);
    expect(s.showBust, false);
  });

  // ── 6. processDart sets pendingGameWinnerId on game completion ───────────

  test('processDart sets pendingGameWinnerId when game completes', () async {
    stubBuild(legsToWin: 1, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    // D20 = 40 = exact checkout; legsToWin:1 → game complete
    await container.read(activeGameProvider('g1').notifier).processDart('D20');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingGameWinnerId, 'c1');
    expect(s.pendingLegWinnerId, null);
    expect(s.showBust, false);
  });

  // ── 7. undoDart reverts gameState and clears overlays ────────────────────

  test('undoDart reverts gameState and resets all overlays', () async {
    final events = [
      turnStartedEvent(),
      dartThrownEvent(segment: 20, multiplier: 1), // score: 40-20=20
    ];
    stubBuild(events: events);
    await container.read(activeGameProvider('g1').future);

    // Verify dart was replayed
    final before = container.read(activeGameProvider('g1')).value!;
    expect(before.gameState.competitors[0].score, 20);
    expect(before.gameState.dartsThrownInTurn, 1);

    await container.read(activeGameProvider('g1').notifier).undoDart();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.gameState.competitors[0].score, 40);
    expect(s.gameState.dartsThrownInTurn, 0);
    expect(s.showBust, false);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 8. dismissBust clears showBust ───────────────────────────────────────

  test('dismissBust sets showBust to false, other fields unchanged', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);
    // Trigger bust
    await container.read(activeGameProvider('g1').notifier).processDart('T20');
    final afterBust = container.read(activeGameProvider('g1')).value!;
    expect(afterBust.showBust, true);

    container.read(activeGameProvider('g1').notifier).dismissBust();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.showBust, false);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
    // gameState unchanged
    expect(s.gameState, afterBust.gameState);
  });

  // ── 9. dismissLegModal clears pendingLegWinnerId ──────────────────────────

  test('dismissLegModal sets pendingLegWinnerId to null, other fields unchanged',
      () async {
    stubBuild(legsToWin: 2, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);
    await container.read(activeGameProvider('g1').notifier).processDart('D20');
    final afterLeg = container.read(activeGameProvider('g1')).value!;
    expect(afterLeg.pendingLegWinnerId, 'c1');

    container.read(activeGameProvider('g1').notifier).dismissLegModal();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingLegWinnerId, null);
    expect(s.showBust, false);
    expect(s.pendingGameWinnerId, null);
    expect(s.gameState, afterLeg.gameState);
  });

  // ── 10. dismissGameModal clears pendingGameWinnerId ───────────────────────

  test(
      'dismissGameModal sets pendingGameWinnerId to null, other fields unchanged',
      () async {
    stubBuild(legsToWin: 1, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);
    await container.read(activeGameProvider('g1').notifier).processDart('D20');
    final afterGame = container.read(activeGameProvider('g1')).value!;
    expect(afterGame.pendingGameWinnerId, 'c1');

    container.read(activeGameProvider('g1').notifier).dismissGameModal();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingGameWinnerId, null);
    expect(s.showBust, false);
    expect(s.pendingLegWinnerId, null);
    expect(s.gameState, afterGame.gameState);
  });

  // ── 11. build replays DartThrown correctly ───────────────────────────────

  test('build replays DartThrown event and reduces score', () async {
    stubBuild(events: [
      turnStartedEvent(),
      dartThrownEvent(segment: 20, multiplier: 1), // 40-20=20
    ]);

    final result = await container.read(activeGameProvider('g1').future);

    expect(result, isNotNull);
    expect(result!.gameState.competitors[0].score, 20);
    expect(result.gameState.dartsThrownInTurn, 1);
    expect(result.gameState.turnActive, true);
  });

  // ── 12. undoDart is a no-op when no darts have been thrown ───────────────

  test('undoDart is a no-op when no darts have been thrown in the game',
      () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    final before = container.read(activeGameProvider('g1')).value!;
    expect(before.gameState.dartsThrownInTurn, 0);

    // Should not throw or crash
    await container.read(activeGameProvider('g1').notifier).undoDart();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.gameState.competitors[0].score, 40);
    expect(s.gameState.dartsThrownInTurn, 0);
    expect(s, before);
  });

  // ── 13. undoDart at turn boundary rolls back to previous turn ────────────

  test('undoDart at turn boundary restores last dart of previous turn',
      () async {
    // Turn 1 (c1): throws 20, ends turn (3 darts forced via bust)
    // Then TurnStarted for c2 is replayed, dartsThrownInTurn == 0
    // Calling undoDart() should roll back to after the first dart of c1's turn
    final events = [
      turnStartedEvent(competitorId: 'c1'),
      dartThrownEvent(
          segment: 20, multiplier: 1, seq: 2, eventId: 'e-dart-1'),
      // T20 busts (60 > 40), turn ends, score restores to 40
      dartThrownEvent(
          segment: 20, multiplier: 3, seq: 3, eventId: 'e-dart-2'),
      // Now c2's turn starts — dartsThrownInTurn resets to 0
      turnStartedEvent(competitorId: 'c2', seq: 4),
    ];
    stubBuild(events: events);
    await container.read(activeGameProvider('g1').future);

    final before = container.read(activeGameProvider('g1')).value!;
    // c2's turn is active, 0 darts thrown in current turn
    expect(before.gameState.currentTurnIndex, 1);
    expect(before.gameState.dartsThrownInTurn, 0);

    // undoDart should undo T20 (bust dart) from c1's previous turn
    await container.read(activeGameProvider('g1').notifier).undoDart();

    final s = container.read(activeGameProvider('g1')).value!;
    // After undo of T20 (bust), c1's turn should be active with 1 dart thrown
    expect(s.gameState.dartsThrownInTurn, 1);
    expect(s.gameState.competitors[0].score, 20); // after 20 single
  });

  // ── Round cap tests ──────────────────────────────────────────────────────

  Game makeGameWithCap({
    int startingScore = 501,
    int totalRounds = 1,
    int legsToWin = 1,
  }) =>
      Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: GameConfig.x01(
          startingScore: startingScore,
          inStrategy: 'straight',
          outStrategy: 'double',
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

  GameEvent dartThrownC2({
    required int segment,
    required int multiplier,
    required int seq,
  }) =>
      GameEvent(
        eventId: 'e-dart-c2-$seq',
        gameId: 'g1',
        eventType: 'DartThrown',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': 'c2',
          'segment': segment,
          'multiplier': multiplier,
          'input_method': 'manual',
        },
        synced: false,
        actorId: 'p2',
        source: EventSource.client,
      );

  // Event trail: round 1 of a totalRounds=1 x01 game. c1 scores 20, c2
  // scores 20 — tied when the cap fires. Ends with c2's turn done
  // (3 darts thrown), ready for a cap-triggering nextPlayer() / advanceTurn().
  List<GameEvent> makeCapBoundaryEventsTied({int startingScore = 501}) {
    return [
      turnStartedEvent(competitorId: 'c1', seq: 1),
      dartThrownEvent(segment: 20, multiplier: 1, seq: 2, eventId: 'e-c1-1'),
      dartThrownEvent(segment: 0, multiplier: 1, seq: 3, eventId: 'e-c1-2'),
      dartThrownEvent(segment: 0, multiplier: 1, seq: 4, eventId: 'e-c1-3'),
      turnEndedEvent(competitorId: 'c1', seq: 5),
      turnStartedEvent(competitorId: 'c2', seq: 6),
      dartThrownC2(segment: 20, multiplier: 1, seq: 7),
      dartThrownC2(segment: 0, multiplier: 1, seq: 8),
      dartThrownC2(segment: 0, multiplier: 1, seq: 9),
    ];
  }

  test(
      'advanceTurn at round cap with tied scores → pendingCapSelection (ambiguous)',
      () async {
    when(mockGameRepo.getGame('g1'))
        .thenAnswer((_) async => makeGameWithCap(totalRounds: 1));
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => makeCompetitors());
    when(mockEventRepo.getEventsForGame('g1'))
        .thenAnswer((_) async => makeCapBoundaryEventsTied());
    await container.read(activeGameProvider('g1').future);

    await container.read(activeGameProvider('g1').notifier).advanceTurn();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingCapSelection, true);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
    expect(s.gameState.isComplete, false);
    expect(s.gameState.competitors[0].legsWon, 0);
    expect(s.gameState.competitors[1].legsWon, 0);
  });

  test(
      'advanceTurn at round cap with clear lowest score → gameCompleted auto-winner',
      () async {
    when(mockGameRepo.getGame('g1'))
        .thenAnswer((_) async => makeGameWithCap(totalRounds: 1));
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => makeCompetitors());
    // c1 scores 60 (T20), c2 scores 20 — c2 is clear higher → c1 has lower
    // score → c1 wins by "least remaining" (actually in X01 lower score =
    // closer to 0 = winner).
    final events = [
      turnStartedEvent(competitorId: 'c1', seq: 1),
      dartThrownEvent(segment: 20, multiplier: 3, seq: 2, eventId: 'e-c1-1'),
      dartThrownEvent(segment: 0, multiplier: 1, seq: 3, eventId: 'e-c1-2'),
      dartThrownEvent(segment: 0, multiplier: 1, seq: 4, eventId: 'e-c1-3'),
      turnEndedEvent(competitorId: 'c1', seq: 5),
      turnStartedEvent(competitorId: 'c2', seq: 6),
      dartThrownC2(segment: 20, multiplier: 1, seq: 7),
      dartThrownC2(segment: 0, multiplier: 1, seq: 8),
      dartThrownC2(segment: 0, multiplier: 1, seq: 9),
    ];
    when(mockEventRepo.getEventsForGame('g1')).thenAnswer((_) async => events);
    await container.read(activeGameProvider('g1').future);

    await container.read(activeGameProvider('g1').notifier).advanceTurn();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingCapSelection, false);
    expect(s.pendingGameWinnerId, 'c1');
    expect(s.gameState.isComplete, true);
    expect(s.gameState.winnerCompetitorId, 'c1');
    verify(mockGameRepo.completeGame(
      gameId: 'g1',
      winnerCompetitorId: 'c1',
      endTime: anyNamed('endTime'),
    )).called(1);
  });

  test('selectCapWinner finalizes ambiguous cap leg', () async {
    when(mockGameRepo.getGame('g1'))
        .thenAnswer((_) async => makeGameWithCap(totalRounds: 1));
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => makeCompetitors());
    when(mockEventRepo.getEventsForGame('g1'))
        .thenAnswer((_) async => makeCapBoundaryEventsTied());
    await container.read(activeGameProvider('g1').future);
    await container.read(activeGameProvider('g1').notifier).advanceTurn();

    await container
        .read(activeGameProvider('g1').notifier)
        .selectCapWinner('c2');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingCapSelection, false);
    expect(s.pendingGameWinnerId, 'c2');
    expect(s.gameState.isComplete, true);
    verify(mockGameRepo.completeGame(
      gameId: 'g1',
      winnerCompetitorId: 'c2',
      endTime: anyNamed('endTime'),
    )).called(1);
  });

  test('selectCapWinner is a no-op when pendingCapSelection is false', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    await container
        .read(activeGameProvider('g1').notifier)
        .selectCapWinner('c1');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.gameState.isComplete, false);
    expect(s.pendingGameWinnerId, null);
    verifyNever(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    ));
  });

  // ── Regression: rapid concurrent processDart calls do not collide on
  //    local_sequence (issue #98). The mock simulates the
  //    (game_id, local_sequence) unique constraint — without serialization,
  //    two concurrent calls both read getLatestSequence=N and both try to
  //    write N+1, raising SequenceConflictException.
  // ── endGame (#280, mirroring cricket #252) ─────────────────────────────

  test(
      'endGame appends GameCompleted(winner=null) and completes the game '
      'atomically so the abandoned game appears in history and the projection '
      'runner gets a clean reset at the game boundary (#280)', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);
    when(mockGameRepo.appendEventsAndCompleteGame(
      events: anyNamed('events'),
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenAnswer((_) async {});

    await container.read(activeGameProvider('g1').notifier).endGame();

    final captured = verify(mockGameRepo.appendEventsAndCompleteGame(
      events: captureAnyNamed('events'),
      gameId: 'g1',
      winnerCompetitorId: null,
      endTime: anyNamed('endTime'),
    )).captured.single as List<GameEvent>;
    expect(captured, hasLength(1));
    expect(captured.first.eventType, 'GameCompleted');
    expect(captured.first.payload['winner_competitor_id'], isNull);
    // Atomicity goes through appendEventsAndCompleteGame, not bare completeGame.
    verifyNever(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    ));
  });

  test('endGame is a no-op when the game already completed naturally',
      () async {
    // After D20 = 40 = exact checkout, ProcessDartUseCase has already run
    // appendEventsAndCompleteGame via the natural-completion path. endGame()
    // must NOT issue a second completion call.
    when(mockGameRepo.appendEventsAndCompleteGame(
      events: anyNamed('events'),
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenAnswer((_) async {});
    stubBuild(legsToWin: 1, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);
    await container.read(activeGameProvider('g1').notifier).processDart('D20');
    clearInteractions(mockGameRepo);

    await container.read(activeGameProvider('g1').notifier).endGame();

    verifyNever(mockGameRepo.appendEventsAndCompleteGame(
      events: anyNamed('events'),
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    ));
    verifyNever(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    ));
  });

  test('endGame swallows GameAlreadyCompleteException (idempotent)',
      () async {
    when(mockGameRepo.appendEventsAndCompleteGame(
      events: anyNamed('events'),
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenThrow(const GameAlreadyCompleteException('g1'));
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    // Must not propagate as an AsyncError on the provider.
    await container.read(activeGameProvider('g1').notifier).endGame();

    final s = container.read(activeGameProvider('g1'));
    expect(s.hasError, isFalse);
  });

  test('concurrent processDart calls do not collide on local_sequence',
      () async {
    final accepted = <int>{1}; // TurnStarted at seq=1 from build
    int currentMax = 1;

    when(mockEventRepo.getLatestSequence('g1'))
        .thenAnswer((_) async => currentMax);
    when(mockEventRepo.appendEvents(any)).thenAnswer((inv) async {
      final events = inv.positionalArguments[0] as List<GameEvent>;
      for (final e in events) {
        if (accepted.contains(e.localSequence)) {
          throw SequenceConflictException(e.gameId, e.localSequence);
        }
        accepted.add(e.localSequence);
        if (e.localSequence > currentMax) currentMax = e.localSequence;
      }
    });

    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    final notifier = container.read(activeGameProvider('g1').notifier);
    final futures = [
      notifier.processDart('1'),
      notifier.processDart('1'),
      notifier.processDart('1'),
    ];

    await Future.wait(futures);

    // Sequences 2..4 are the three DartThrown events. Seq 5 is the eager
    // TurnEnded emitted by ProcessDartUseCase on the !turnActive boundary
    // (the 3rd dart ends the turn).
    expect(accepted.containsAll({2, 3, 4, 5}), isTrue,
        reason: 'expected sequences 2, 3, 4, 5 — got $accepted');
    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.gameState.competitors[0].score, 37); // 40 - 1 - 1 - 1
    expect(s.gameState.dartsThrownInTurn, 3);
  });
}
