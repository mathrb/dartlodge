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
import 'package:dart_lodge/features/game/presentation/providers/active_practice_provider.dart';
import 'package:riverpod/riverpod.dart';

import 'active_practice_notifier_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late ProviderContainer container;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  // ── helpers ──────────────────────────────────────────────────────────────

  Game makeCheckoutPracticeGame() => Game(
        gameId: 'g1',
        gameType: GameType.checkoutPractice,
        config: const GameConfig.checkoutPractice(),
        startTime: DateTime(2025),
      );

  Game makeAtcGame() => Game(
        gameId: 'g1',
        gameType: GameType.aroundTheClock,
        config: const GameConfig.aroundTheClock(),
        startTime: DateTime(2025),
      );

  Game makeBobs27Game() => Game(
        gameId: 'g1',
        gameType: GameType.bobs27,
        config: const GameConfig.bobs27(),
        startTime: DateTime(2025),
      );

  Game makeShanghaiGame() => Game(
        gameId: 'g1',
        gameType: GameType.shanghai,
        config: const GameConfig.shanghai(),
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
      ];

  GameEvent turnStartedEvent({int seq = 1}) => GameEvent(
        eventId: 'e-turn-$seq',
        gameId: 'g1',
        eventType: 'TurnStarted',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': 'c1',
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
    required int seq,
  }) =>
      GameEvent(
        eventId: 'e-dart-$seq',
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

  // Builds events that leave the ATC player at target=20, turnActive=true.
  // Turn 1-6: advance targets 1–18 (3 hits per turn).
  // Turn 7: hit 19 (target→20), then 2 misses → turnActive=false.
  // Turn 8: TurnStarted → target=20, turnActive=true.
  // Then processDart('20') completes the game.
  List<GameEvent> makeNearCompleteAtcEvents() {
    int seq = 0;
    final events = <GameEvent>[];

    // Turns 1–6: 3 consecutive hits per turn advancing targets 1–18
    for (int t = 0; t < 6; t++) {
      final base = t * 3 + 1; // 1, 4, 7, 10, 13, 16
      events.add(turnStartedEvent(seq: ++seq));
      events.add(dartThrownEvent(segment: base, multiplier: 1, seq: ++seq));
      events.add(dartThrownEvent(segment: base + 1, multiplier: 1, seq: ++seq));
      events.add(dartThrownEvent(segment: base + 2, multiplier: 1, seq: ++seq));
    }
    // After turn 6: target=19, turnActive=false (3 darts auto-ended turn)

    // Turn 7: hit 19 → target=20; 2 misses to exhaust darts → turnActive=false
    events.add(turnStartedEvent(seq: ++seq));
    events.add(dartThrownEvent(segment: 19, multiplier: 1, seq: ++seq));
    events.add(dartThrownEvent(segment: 0, multiplier: 1, seq: ++seq));
    events.add(dartThrownEvent(segment: 0, multiplier: 1, seq: ++seq));

    // Turn 8: TurnStarted → target=20, turnActive=true, darts=0
    events.add(turnStartedEvent(seq: ++seq));

    return events;
  }

  void stubBuild({
    required Game game,
    List<GameEvent> events = const [],
  }) {
    when(mockGameRepo.getGame('g1')).thenAnswer((_) async => game);
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

    final result = await container.read(activePracticeProvider('g1').future);

    expect(result, isNull);
  });

  // ── 2. build replays TurnStarted and returns correct ActivePracticeState ──

  test('build replays TurnStarted event and returns ActivePracticeState',
      () async {
    stubBuild(game: makeCheckoutPracticeGame(), events: [turnStartedEvent()]);

    final result = await container.read(activePracticeProvider('g1').future);

    expect(result, isNotNull);
    expect(result!.gameState.turnActive, true);
    expect(result.gameState.currentTurnIndex, 0);
    expect(result.pendingGameWinnerId, null);
  });

  // ── 3. processDart updates gameState ─────────────────────────────────────

  test('processDart updates gameState in returned state', () async {
    stubBuild(game: makeCheckoutPracticeGame(), events: [turnStartedEvent()]);
    await container.read(activePracticeProvider('g1').future);

    await container
        .read(activePracticeProvider('g1').notifier)
        .processDart('T20');

    final s = container.read(activePracticeProvider('g1')).value!;
    expect(s.gameState.dartsThrownInTurn, 1);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 4. processDart sets pendingGameWinnerId when game completes ───────────
  //
  // Uses ATC with a near-complete state (target=20, turnActive=true).
  // processDart('20') hits the final target → LegOutcome.gameCompleted.

  test('processDart sets pendingGameWinnerId when game is complete', () async {
    stubBuild(game: makeAtcGame(), events: makeNearCompleteAtcEvents());
    await container.read(activePracticeProvider('g1').future);

    await container
        .read(activePracticeProvider('g1').notifier)
        .processDart('20');

    final s = container.read(activePracticeProvider('g1')).value!;
    expect(s.pendingGameWinnerId, 'c1');
    expect(s.gameState.isComplete, true);
  });

  // ── 5. undoDart updates gameState and clears pendingGameWinnerId ──────────

  test('undoDart updates gameState and clears pendingGameWinnerId', () async {
    final events = [
      turnStartedEvent(seq: 1),
      dartThrownEvent(segment: 0, multiplier: 1, seq: 2),
    ];
    stubBuild(game: makeCheckoutPracticeGame(), events: events);
    await container.read(activePracticeProvider('g1').future);

    final before = container.read(activePracticeProvider('g1')).value!;
    expect(before.gameState.dartsThrownInTurn, 1);

    await container
        .read(activePracticeProvider('g1').notifier)
        .undoDart();

    final s = container.read(activePracticeProvider('g1')).value!;
    expect(s.gameState.dartsThrownInTurn, 0);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 6. dismissGameModal clears pendingGameWinnerId ────────────────────────

  test('dismissGameModal sets pendingGameWinnerId to null', () async {
    stubBuild(game: makeAtcGame(), events: makeNearCompleteAtcEvents());
    await container.read(activePracticeProvider('g1').future);
    await container
        .read(activePracticeProvider('g1').notifier)
        .processDart('20');
    final afterGame = container.read(activePracticeProvider('g1')).value!;
    expect(afterGame.pendingGameWinnerId, 'c1');

    container
        .read(activePracticeProvider('g1').notifier)
        .dismissGameModal();

    final s = container.read(activePracticeProvider('g1')).value!;
    expect(s.pendingGameWinnerId, null);
    expect(s.gameState, afterGame.gameState);
  });

  // ── 7. bobs27 engine is selected when gameType == GameType.bobs27 ─────────

  test('selecting bobs27 engine when gameType == GameType.bobs27', () async {
    stubBuild(game: makeBobs27Game());

    final result = await container.read(activePracticeProvider('g1').future);

    expect(result, isNotNull);
    expect(result!.gameState.gameType, GameType.bobs27);
  });

  // ── 8. shanghai engine is selected when gameType == GameType.shanghai ─────

  test('selecting shanghai engine when gameType == GameType.shanghai', () async {
    stubBuild(game: makeShanghaiGame());

    final result = await container.read(activePracticeProvider('g1').future);

    expect(result, isNotNull);
    expect(result!.gameState.gameType, GameType.shanghai);
  });

  // ── 9. endDrill completes checkout practice game ──────────────────────────

  test('endDrill completes checkout practice game', () async {
    stubBuild(game: makeCheckoutPracticeGame(), events: [turnStartedEvent()]);
    await container.read(activePracticeProvider('g1').future);

    await container
        .read(activePracticeProvider('g1').notifier)
        .endDrill();

    final s = container.read(activePracticeProvider('g1')).value!;
    expect(s.gameState.isComplete, true);
    // EndPracticeUseCase completes with no winner
    expect(s.pendingGameWinnerId, null);
  });

  // ── 10. endDrill completes a non-checkout drill (regression for #224) ──────
  //
  // Before #224, _endDrillImpl early-returned for any gameType other than
  // checkoutPractice, leaving the game is_complete=0 and bricking new starts.

  test('endDrill completes a non-checkout (ATC) drill with no winner',
      () async {
    stubBuild(game: makeAtcGame(), events: [turnStartedEvent()]);
    await container.read(activePracticeProvider('g1').future);

    await container
        .read(activePracticeProvider('g1').notifier)
        .endDrill();

    final s = container.read(activePracticeProvider('g1')).value!;
    expect(s.gameState.isComplete, true);
    expect(s.pendingGameWinnerId, null);
    verify(mockGameRepo.appendEventsAndCompleteGame(
      events: anyNamed('events'),
      gameId: 'g1',
      winnerCompetitorId: null,
      endTime: anyNamed('endTime'),
    )).called(1);
  });
}
