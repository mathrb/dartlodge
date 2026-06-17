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

  Game makeCheckoutPracticeGame({int? targetSuccesses}) => Game(
        gameId: 'g1',
        gameType: GameType.checkoutPractice,
        config: GameConfig.checkoutPractice(targetSuccesses: targetSuccesses),
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

  Game makeCatch40Game() => Game(
        gameId: 'g1',
        gameType: GameType.catch40,
        config: const GameConfig.catch40(),
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

  // ── 11. Catch 40: sub-3-dart checkout via NEXT TARGET scores points ───────
  //
  // Regression for #253. Before the fix, `_fillTurnWithMisses` ran for
  // catch40 too — and the MISS dart, processed through the engine after a
  // checkout (catch40TargetRemaining == 0), was treated as a bust that
  // reset the target back to non-zero. The subsequent TurnEnded then saw
  // `checkedOut = false` and awarded 0 points. After the fix, MISS-fill is
  // skipped for catch40 and TurnEnded directly observes the zeroed target,
  // awarding +3 for the 2-dart checkout.

  test('Catch 40: 2-dart checkout via NEXT TARGET awards +3 points', () async {
    // Seed events to put the engine at: target=40 (remaining), turnActive=true,
    // dartsThrownInTurn=0. We do this with a vanilla TurnStarted; the engine's
    // initial state starts at catch40TargetRemaining=61 (target 1). To reach
    // remaining=40 from 61 quickly, we'd need to track engine state via real
    // throws — easier: just throw D20 (=40) twice on the natural target 61.
    // 61 - 40 = 21 (not bust, not 0). 21 - 40 = -19 → bust, reset to 61.
    // That doesn't model a checkout. Use D20 (40) + 21? But 21 isn't a single
    // dart. Better: just throw 1 (single 1) to bring 61 → 60, then D30 (=60)
    // to checkout. D30 doesn't exist either.
    //
    // Realistic checkout on 61: 1 (S1) → 60 → D30 invalid. Try 11 (S11) →
    // 50 → D25 invalid. Try 9 (S9) → 52 → D26 invalid. Try 11 (S11) → 50
    // → D25 invalid. Doubles only go up to D20=40 or D-Bull=50.
    //
    // Try 21 over 1 dart: not possible. Realistic 2-dart checkout on 61
    // = T7 (21) + D20 (40) → 21+40=61. Use that.
    stubBuild(
      game: makeCatch40Game(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);

    final notifier = container.read(activePracticeProvider('g1').notifier);

    // Dart 1: T7 (21). Remaining: 61 - 21 = 40.
    await notifier.processDart('T7');
    // Dart 2: D20 (40). Remaining: 40 - 40 = 0 (double) → checkout.
    await notifier.processDart('D20');

    final afterCheckout = container.read(activePracticeProvider('g1')).value!;
    expect(afterCheckout.gameState.catch40TargetRemaining, 0,
        reason: 'Engine should record the checkout (remaining = 0).');
    expect(afterCheckout.gameState.catch40DartsOnTarget, 2);
    expect(afterCheckout.gameState.turnActive, false,
        reason: 'Engine ends the turn on checkout.');

    // User taps NEXT TARGET — this drives _fillTurnWithMisses + _advanceTurn.
    // Before the fix the MISS-fill would bust the target and award 0 points.
    await notifier.startNextTurn();

    final afterAdvance = container.read(activePracticeProvider('g1')).value!;
    final comp = afterAdvance.gameState.competitors[0];
    expect(comp.score, 3,
        reason: '2-dart checkout on target 61 awards +3 points.');
    expect(comp.practiceSuccesses, 1);
    expect(comp.practiceAttempts, 1);
    expect(comp.practiceRound, 2,
        reason: 'Target should advance from 1 (=61) to 2 (=62).');
    expect(afterAdvance.gameState.catch40TargetRemaining, 62,
        reason: 'Next target is 62 (practiceRound=2).');
    expect(afterAdvance.gameState.catch40DartsOnTarget, 0);
  });

  // ── 12. Catch 40: TurnEnded payload carries reason + darts_on_target ──────
  //
  // The stats projection in `_computeCatch40Stats` reads `reason` to bucket
  // checkouts vs failed targets and `darts_on_target` to classify the
  // checkout (2-dart / 3-dart / 4–6 dart). Before #253 the producer emitted
  // only `{competitor_id}` and the projection silently zeroed out.

  test('Catch 40: TurnEnded after checkout includes reason + darts_on_target',
      () async {
    stubBuild(
      game: makeCatch40Game(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    await notifier.processDart('T7'); // 21 remaining = 40
    await notifier.processDart('D20'); // 40 remaining = 0 → checkout
    await notifier.startNextTurn();

    // Capture every appended event batch and find the TurnEnded that
    // straddled the checkout → target-advance boundary.
    final captures = verify(mockEventRepo.appendEvents(captureAny)).captured;
    final allEvents = captures.expand((c) => c as List<GameEvent>).toList();
    final checkoutTurnEnded = allEvents.firstWhere(
      (e) =>
          e.eventType == 'TurnEnded' &&
          e.payload['reason'] == 'checkout',
      orElse: () =>
          throw StateError('No TurnEnded with reason=checkout emitted'),
    );
    expect(checkoutTurnEnded.payload['player_id'], 'p1');
    expect(checkoutTurnEnded.payload['darts_on_target'], 2);
  });

  // ── 13a. Checkout Practice: ∞ checkout does NOT end the drill (#254) ─────
  //
  // Before the fix, the engine returned `gameCompleted` on every checkout,
  // so even a `targetSuccesses: null` (∞) drill ended after the very first
  // T20+T20+DB. After the fix the engine only completes via TurnEnded when
  // the configured quota is hit; ∞ mode never completes via TurnEnded.

  test('Checkout Practice: ∞ checkout does not end the drill', () async {
    stubBuild(
      game: makeCheckoutPracticeGame(targetSuccesses: null),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    // 170 → T20=60 (110) → T20=60 (50) → DB=50 (0) = perfect 3-dart checkout.
    await notifier.processDart('T20');
    await notifier.processDart('T20');
    await notifier.processDart('DB');

    final s = container.read(activePracticeProvider('g1')).value!;
    expect(s.gameState.isComplete, isFalse,
        reason: '∞ mode must keep the drill open after a checkout.');
    expect(s.pendingGameWinnerId, isNull);
    expect(s.gameState.competitors[0].practiceSuccesses, 1);
    expect(s.gameState.competitors[0].score, 0,
        reason:
            'Engine leaves score=0; the next TurnStarted resets it to 170.');
    expect(s.gameState.dartsThrownInTurn, 3,
        reason: 'Turn ends on checkout (dartsThrownInTurn forced to 3).');
  });

  // ── 13b. Checkout Practice: finite quota ends drill on Nth checkout ──────

  test('Checkout Practice: targetSuccesses=1 completes drill on first checkout',
      () async {
    stubBuild(
      game: makeCheckoutPracticeGame(targetSuccesses: 1),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    await notifier.processDart('T20');
    await notifier.processDart('T20');
    await notifier.processDart('DB');

    final s = container.read(activePracticeProvider('g1')).value!;
    expect(s.gameState.isComplete, isTrue);
    expect(s.pendingGameWinnerId, 'c1');
    expect(s.gameState.competitors[0].practiceSuccesses, 1);
    verify(mockGameRepo.appendEventsAndCompleteGame(
      events: anyNamed('events'),
      gameId: 'g1',
      winnerCompetitorId: 'c1',
      endTime: anyNamed('endTime'),
    )).called(1);
  });

  // ── 13c. Checkout Practice: TurnEnded carries reason='checkout' ─────────
  //
  // The stats projection (`_computeCheckoutStats`) counts attempts on every
  // TurnEnded and successes on those with `reason == 'checkout'`. Before
  // #254 the producer stamped `reason: 'normal'` everywhere for non-catch40,
  // so `successes` stayed at 0 even with completed checkouts.

  test('Checkout Practice: drill-ending TurnEnded includes reason=checkout',
      () async {
    stubBuild(
      game: makeCheckoutPracticeGame(targetSuccesses: 1),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    await notifier.processDart('T20');
    await notifier.processDart('T20');
    await notifier.processDart('DB');

    // The drill-ending TurnEnded is persisted atomically via
    // appendEventsAndCompleteGame.
    final captures = verify(mockGameRepo.appendEventsAndCompleteGame(
      events: captureAnyNamed('events'),
      gameId: 'g1',
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).captured;
    final committedEvents =
        captures.expand((c) => c as List<GameEvent>).toList();
    final turnEnded = committedEvents.firstWhere(
      (e) => e.eventType == 'TurnEnded',
      orElse: () =>
          throw StateError('Drill-ending TurnEnded was not persisted'),
    );
    expect(turnEnded.payload['reason'], 'checkout');
    expect(turnEnded.payload['player_id'], 'p1');
  });

  // ── 13. Catch 40: failed target via 6 darts records reason='failed' ──────

  test('Catch 40: 6-dart failed target emits TurnEnded with reason=failed',
      () async {
    stubBuild(
      game: makeCatch40Game(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    // Visit 1: 3 MISSes (auto-advance fires after dart 3).
    await notifier.processDart('MISS');
    await notifier.processDart('MISS');
    await notifier.processDart('MISS');
    // Visit 2: 3 more MISSes — target unhit at 6 darts → 'failed' on NEXT.
    await notifier.processDart('MISS');
    await notifier.processDart('MISS');
    await notifier.processDart('MISS');
    await notifier.startNextTurn();

    final captures = verify(mockEventRepo.appendEvents(captureAny)).captured;
    final allEvents = captures.expand((c) => c as List<GameEvent>).toList();

    final failedTurnEnded = allEvents.firstWhere(
      (e) =>
          e.eventType == 'TurnEnded' && e.payload['reason'] == 'failed',
      orElse: () =>
          throw StateError('No TurnEnded with reason=failed emitted'),
    );
    expect(failedTurnEnded.payload['player_id'], 'p1');
    expect(failedTurnEnded.payload['darts_on_target'], 6);

    final afterAdvance = container.read(activePracticeProvider('g1')).value!;
    expect(afterAdvance.gameState.competitors[0].practiceRound, 2);
    expect(afterAdvance.gameState.competitors[0].score, 0);
  });

  // ── 13. Catch 40 bust feedback (#325) ────────────────────────────────────
  //
  // Bust signature in Catch 40: a non-zero dart was applied but
  // `catch40TargetRemaining` did NOT decrease (engine resets to currentTarget
  // on bust). MISS darts must NOT trigger the flag — they score 0 and leave
  // remaining unchanged at the start-of-round value.

  test('Catch 40: showBust true after overshoot on the first dart', () async {
    stubBuild(
      game: makeCatch40Game(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    // Target 1 → remaining 61. T20 (60) → newRem = 1 → bust → remaining
    // reset to 61. dartValue > 0, dartsOnTarget incremented (0→1),
    // remaining stayed at 61. Detection fires.
    await notifier.processDart('T20');

    final after = container.read(activePracticeProvider('g1')).value!;
    expect(after.showBust, isTrue,
        reason: 'T20 over 1 remaining must flag showBust');
    expect(after.gameState.catch40TargetRemaining, 61,
        reason: 'engine resets remaining to currentTarget on bust');
  });

  test('Catch 40: showBust false on MISS (start of round)', () async {
    stubBuild(
      game: makeCatch40Game(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    // MISS at start of round: dartValue=0, remaining stays at 61, NOT a bust.
    await notifier.processDart('MISS');

    final after = container.read(activePracticeProvider('g1')).value!;
    expect(after.showBust, isFalse,
        reason: 'a zero-value MISS dart is not a bust');
  });

  test('Catch 40: showBust false on partial scoring throw', () async {
    stubBuild(
      game: makeCatch40Game(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    // T15 (45): remaining 61 → 16. Score progresses, not a bust.
    await notifier.processDart('T15');

    final after = container.read(activePracticeProvider('g1')).value!;
    expect(after.showBust, isFalse);
    expect(after.gameState.catch40TargetRemaining, 16);
  });

  test('Catch 40: dismissBust clears the transient flag', () async {
    stubBuild(
      game: makeCatch40Game(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    await notifier.processDart('T20');
    expect(
        container.read(activePracticeProvider('g1')).value!.showBust, isTrue);

    notifier.dismissBust();
    expect(
        container.read(activePracticeProvider('g1')).value!.showBust, isFalse);
  });

  // ── 14. Checkout Practice bust feedback (#340) ─────────────────────────
  //
  // Same mechanism as Catch 40 (#325). The engine reverts `score` to
  // turnStartScore on bust; the provider detects this by comparing
  // pre/post score and flips `showBust`. The board page listens for the
  // false→true transition and flashes a snackbar.

  test('Checkout Practice: showBust true after overshoot on third dart',
      () async {
    stubBuild(
      game: makeCheckoutPracticeGame(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    // Throw T20+T20+T20 from 170 → 170-60-60-60 = -10 → bust → score reverts.
    await notifier.processDart('T20');
    await notifier.processDart('T20');
    await notifier.processDart('T20');

    final after = container.read(activePracticeProvider('g1')).value!;
    expect(after.showBust, isTrue,
        reason: 'T20×3 from 170 must flash BUST');
    expect(after.gameState.competitors[0].score, 170,
        reason: 'engine reverts to turnStartScore on bust');
  });

  test('Checkout Practice: showBust false on a successful checkout',
      () async {
    stubBuild(
      game: makeCheckoutPracticeGame(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    // T20+T20+DB = 170 → score 0 → successful checkout, not bust.
    await notifier.processDart('T20');
    await notifier.processDart('T20');
    await notifier.processDart('DB');

    final after = container.read(activePracticeProvider('g1')).value!;
    expect(after.showBust, isFalse,
        reason: 'a checkout sets score to 0; not a bust');
  });

  test('Checkout Practice: showBust false on MISS at start of turn',
      () async {
    stubBuild(
      game: makeCheckoutPracticeGame(),
      events: [turnStartedEvent(seq: 1)],
    );
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    await notifier.processDart('MISS');

    final after = container.read(activePracticeProvider('g1')).value!;
    expect(after.showBust, isFalse,
        reason: 'a zero-value MISS dart is not a bust');
  });

  // ── Regression #538: stray camera dart on a full/ended turn is a no-op ────
  //
  // After a manual entry + later camera re-detection the game's turn can be
  // ahead of the camera tracker: the turn ends (turnActive=false) while the
  // tracker still emits one more dart. Unlike X01/cricket (whose use cases
  // throw InvalidGameStateException → AsyncError), ProcessPracticeDartUseCase
  // does not validate turnActive — so without the guard the stray dart would
  // silently apply, over-counting dartsThrownInTurn past 3 and corrupting the
  // turn. The camera-scoped guard must drop it as a no-op instead.

  test('processDart(camera) is a silent no-op on a full/ended turn (#538)',
      () async {
    stubBuild(game: makeAtcGame(), events: [turnStartedEvent()]);
    await container.read(activePracticeProvider('g1').future);
    final notifier = container.read(activePracticeProvider('g1').notifier);

    // 3 darts → turn ends (turnActive == false) awaiting NEXT.
    await notifier.processDart('MISS');
    await notifier.processDart('MISS');
    await notifier.processDart('MISS');
    final full = container.read(activePracticeProvider('g1')).value!;
    expect(full.gameState.turnActive, false);
    expect(full.gameState.dartsThrownInTurn, 3);

    // Stray camera dart on the ended turn → dropped, no error, no change.
    await notifier.processDart('1', inputMethod: 'camera');

    final after = container.read(activePracticeProvider('g1'));
    expect(after.hasError, isFalse);
    expect(after.value!.gameState, full.gameState);
  });
}
