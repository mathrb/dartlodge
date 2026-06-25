// ActiveCountUpNotifier unit tests.
//
// Covers the orchestration on top of StatelessCountUpEngine:
// - build replays events and returns ActiveCountUpState
// - processDart routes through the X01-shaped ProcessDartUseCase wired to
//   the count-up engine
// - advanceTurn rotates currentTurnIndex / advances currentRoundInLeg
// - advanceTurn on the last competitor of the last round persists
//   LegCompleted + GameCompleted and sets pendingGameWinnerId
// - tie at game end produces pendingGameWinnerId = null

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
import 'package:dart_lodge/features/game/presentation/providers/active_count_up_provider.dart';
import 'package:riverpod/riverpod.dart';

import 'active_count_up_notifier_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late ProviderContainer container;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  // ── helpers ──────────────────────────────────────────────────────────────

  Game makeGame({int totalRounds = 8}) => Game(
        gameId: 'g1',
        gameType: GameType.countUp,
        config: GameConfig.countUp(totalRounds: totalRounds),
        startTime: DateTime(2025),
      );

  List<Competitor> makeCompetitors({int n = 2}) => [
        for (var i = 1; i <= n; i++)
          Competitor(
            competitorId: 'c$i',
            gameId: 'g1',
            type: CompetitorType.solo,
            name: 'Player $i',
            players: [
              CompetitorPlayer(playerId: 'p$i', rotationPosition: i - 1),
            ],
          ),
      ];

  GameEvent turnStarted(String competitorId, {required int seq}) => GameEvent(
        eventId: 'e-ts-$seq',
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

  GameEvent dartThrown(
    String competitorId, {
    required int segment,
    required int multiplier,
    required int seq,
  }) =>
      GameEvent(
        eventId: 'e-dt-$seq',
        gameId: 'g1',
        eventType: 'DartThrown',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': competitorId,
          'player_id': competitorId.replaceFirst('c', 'p'),
          'segment': segment,
          'multiplier': multiplier,
          'input_method': 'manual',
        },
        synced: false,
        actorId: competitorId.replaceFirst('c', 'p'),
        source: EventSource.client,
      );

  GameEvent turnEnded(String competitorId, {required int seq}) => GameEvent(
        eventId: 'e-te-$seq',
        gameId: 'g1',
        eventType: 'TurnEnded',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {'competitor_id': competitorId, 'reason': 'normal'},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

  /// Builds a 3-dart turn (TurnStarted + DartThrown × 3 + TurnEnded).
  /// Returns the events plus the next free seq number.
  ({List<GameEvent> events, int nextSeq}) fullTurn(
    String competitorId, {
    required int startSeq,
    int segment = 0,
    int multiplier = 1,
  }) {
    var s = startSeq;
    final events = <GameEvent>[
      turnStarted(competitorId, seq: s++),
      dartThrown(competitorId, segment: segment, multiplier: multiplier, seq: s++),
      dartThrown(competitorId, segment: segment, multiplier: multiplier, seq: s++),
      dartThrown(competitorId, segment: segment, multiplier: multiplier, seq: s++),
      turnEnded(competitorId, seq: s++),
    ];
    return (events: events, nextSeq: s);
  }

  /// 3 darts without the trailing TurnEnded — leaves the engine with
  /// turnActive=false, dartsThrownInTurn=3, ready for advanceTurn() to
  /// emit TurnEnded itself.
  ({List<GameEvent> events, int nextSeq}) turnPendingEnd(
    String competitorId, {
    required int startSeq,
    int segment = 0,
    int multiplier = 1,
  }) {
    var s = startSeq;
    final events = <GameEvent>[
      turnStarted(competitorId, seq: s++),
      dartThrown(competitorId, segment: segment, multiplier: multiplier, seq: s++),
      dartThrown(competitorId, segment: segment, multiplier: multiplier, seq: s++),
      dartThrown(competitorId, segment: segment, multiplier: multiplier, seq: s++),
    ];
    return (events: events, nextSeq: s);
  }

  void stubBuild({
    required Game game,
    required List<Competitor> competitors,
    List<GameEvent> events = const [],
  }) {
    when(mockGameRepo.getGame('g1')).thenAnswer((_) async => game);
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => competitors);
    when(mockEventRepo.getEventsForGame('g1')).thenAnswer((_) async => events);
  }

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();

    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 0);
    when(mockDartRepo.insertDart(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvents(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvent(any)).thenAnswer((_) async {});
    when(mockDartRepo.deleteDart(any)).thenAnswer((_) async {});
    when(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenAnswer((_) async {});
    when(mockGameRepo.appendEventsAndCompleteGame(
      events: anyNamed('events'),
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

  // ── 1. build returns null when game not found ────────────────────────────

  test('build returns null when getGame returns null', () async {
    when(mockGameRepo.getGame('g1')).thenAnswer((_) async => null);
    final result = await container.read(activeCountUpProvider('g1').future);
    expect(result, isNull);
  });

  // ── 2. build replays TurnStarted and returns ActiveCountUpState ───────────

  test('build replays TurnStarted and returns ActiveCountUpState', () async {
    stubBuild(
      game: makeGame(),
      competitors: makeCompetitors(),
      events: [turnStarted('c1', seq: 1)],
    );
    final result = await container.read(activeCountUpProvider('g1').future);
    expect(result, isNotNull);
    expect(result!.gameState.turnActive, true);
    expect(result.gameState.currentTurnIndex, 0);
    expect(result.pendingGameWinnerId, null);
  });

  // ── 3. processDart adds score and advances dart count ─────────────────────

  test('processDart adds score for the active competitor', () async {
    stubBuild(
      game: makeGame(),
      competitors: makeCompetitors(),
      events: [turnStarted('c1', seq: 1)],
    );
    await container.read(activeCountUpProvider('g1').future);

    await container
        .read(activeCountUpProvider('g1').notifier)
        .processDart('T20');

    final s = container.read(activeCountUpProvider('g1')).value!;
    expect(s.gameState.dartsThrownInTurn, 1);
    expect(s.gameState.competitors[0].score, 60); // T20
    expect(s.pendingGameWinnerId, null);
  });

  // ── 4. advanceTurn rotates currentTurnIndex mid-round ─────────────────────

  test('advanceTurn rotates to the next competitor mid-round', () async {
    // c1 has thrown 3 darts (T20×3) but no TurnEnded yet — advanceTurn
    // emits TurnEnded; engine rotates to c2 and emits TurnStarted for c2.
    final t1 =
        turnPendingEnd('c1', startSeq: 1, segment: 20, multiplier: 3);
    stubBuild(
      game: makeGame(),
      competitors: makeCompetitors(),
      events: t1.events,
    );
    await container.read(activeCountUpProvider('g1').future);
    when(mockEventRepo.getLatestSequence(any))
        .thenAnswer((_) async => t1.events.length);

    await container
        .read(activeCountUpProvider('g1').notifier)
        .advanceTurn();

    final s = container.read(activeCountUpProvider('g1')).value!;
    expect(s.gameState.currentTurnIndex, 1);
    expect(s.gameState.currentRoundInLeg, 1);
    expect(s.gameState.turnActive, true);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 5. game-end: clear winner ─────────────────────────────────────────────

  test('advanceTurn on last competitor of last round → game completed with winner',
      () async {
    // 1-round, 2 players. c1's full turn (T20×3 = 180) is in events. c2 has
    // thrown 3 misses but no TurnEnded yet — advanceTurn is what triggers it.
    final r1c1 = fullTurn('c1', startSeq: 1, segment: 20, multiplier: 3);
    final r1c2 = turnPendingEnd('c2', startSeq: r1c1.nextSeq);
    final events = [...r1c1.events, ...r1c2.events];

    stubBuild(
      game: makeGame(totalRounds: 1),
      competitors: makeCompetitors(),
      events: events,
    );
    await container.read(activeCountUpProvider('g1').future);
    when(mockEventRepo.getLatestSequence(any))
        .thenAnswer((_) async => events.length);

    await container
        .read(activeCountUpProvider('g1').notifier)
        .advanceTurn();

    final s = container.read(activeCountUpProvider('g1')).value!;
    expect(s.gameState.isComplete, true);
    expect(s.pendingGameWinnerId, 'c1');
    expect(s.gameState.winnerCompetitorId, 'c1');

    verify(mockGameRepo.completeGame(
      gameId: 'g1',
      winnerCompetitorId: 'c1',
      endTime: anyNamed('endTime'),
    )).called(1);
  });

  // ── 6. game-end: tie → null winner ────────────────────────────────────────

  test('advanceTurn on tie at game end → pendingGameWinnerId is null',
      () async {
    // 1-round, 2 players. c1 scored T20+MISS+MISS = 60 (full turn including
    // TurnEnded in events). c2 has thrown T20+MISS+MISS = 60 but no TurnEnded
    // yet — advanceTurn emits it and engine sees the tie.
    final c1Events = <GameEvent>[
      turnStarted('c1', seq: 1),
      dartThrown('c1', segment: 20, multiplier: 3, seq: 2),
      dartThrown('c1', segment: 0, multiplier: 1, seq: 3),
      dartThrown('c1', segment: 0, multiplier: 1, seq: 4),
      turnEnded('c1', seq: 5),
    ];
    final c2Events = <GameEvent>[
      turnStarted('c2', seq: 6),
      dartThrown('c2', segment: 20, multiplier: 3, seq: 7),
      dartThrown('c2', segment: 0, multiplier: 1, seq: 8),
      dartThrown('c2', segment: 0, multiplier: 1, seq: 9),
      // No TurnEnded — advanceTurn emits it.
    ];
    final events = [...c1Events, ...c2Events];

    stubBuild(
      game: makeGame(totalRounds: 1),
      competitors: makeCompetitors(),
      events: events,
    );
    await container.read(activeCountUpProvider('g1').future);
    when(mockEventRepo.getLatestSequence(any))
        .thenAnswer((_) async => events.length);

    await container
        .read(activeCountUpProvider('g1').notifier)
        .advanceTurn();

    final s = container.read(activeCountUpProvider('g1')).value!;
    expect(s.gameState.isComplete, true);
    expect(s.pendingGameWinnerId, isNull);
    expect(s.gameState.winnerCompetitorId, isNull);
  });

  // ── 7. undoDart rolls back the last dart ─────────────────────────────────

  test('undoDart rolls back last dart and clears pendingGameWinnerId',
      () async {
    final events = [
      turnStarted('c1', seq: 1),
      dartThrown('c1', segment: 20, multiplier: 3, seq: 2),
    ];
    stubBuild(
      game: makeGame(),
      competitors: makeCompetitors(),
      events: events,
    );
    await container.read(activeCountUpProvider('g1').future);

    final before = container.read(activeCountUpProvider('g1')).value!;
    expect(before.gameState.dartsThrownInTurn, 1);
    expect(before.gameState.competitors[0].score, 60);

    await container
        .read(activeCountUpProvider('g1').notifier)
        .undoDart();

    final s = container.read(activeCountUpProvider('g1')).value!;
    expect(s.gameState.dartsThrownInTurn, 0);
    expect(s.gameState.competitors[0].score, 0);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 8. dismissGameModal clears pendingGameWinnerId ───────────────────────

  test('dismissGameModal clears pendingGameWinnerId', () async {
    // 1-round, 2-player; advance to game-end first.
    final r1c1 = fullTurn('c1', startSeq: 1, segment: 20, multiplier: 3);
    final r1c2 = turnPendingEnd('c2', startSeq: r1c1.nextSeq);
    final events = [...r1c1.events, ...r1c2.events];

    stubBuild(
      game: makeGame(totalRounds: 1),
      competitors: makeCompetitors(),
      events: events,
    );
    await container.read(activeCountUpProvider('g1').future);
    when(mockEventRepo.getLatestSequence(any))
        .thenAnswer((_) async => events.length);

    await container
        .read(activeCountUpProvider('g1').notifier)
        .advanceTurn();
    expect(container.read(activeCountUpProvider('g1')).value!.pendingGameWinnerId,
        'c1');

    container
        .read(activeCountUpProvider('g1').notifier)
        .dismissGameModal();

    expect(container.read(activeCountUpProvider('g1')).value!.pendingGameWinnerId,
        isNull);
  });

  // ── 9. endGame abandons the game (winner=null) without mutating state ──────

  test('endGame persists GameCompleted(winner=null) and completes the game',
      () async {
    stubBuild(
      game: makeGame(),
      competitors: makeCompetitors(),
      events: [turnStarted('c1', seq: 1)],
    );
    await container.read(activeCountUpProvider('g1').future);

    await container.read(activeCountUpProvider('g1').notifier).endGame();

    final captured = verify(mockGameRepo.appendEventsAndCompleteGame(
      events: captureAnyNamed('events'),
      gameId: 'g1',
      winnerCompetitorId: null,
      endTime: anyNamed('endTime'),
    )).captured;
    final events = captured.single as List<GameEvent>;
    expect(events, hasLength(1));
    expect(events.single.eventType, 'GameCompleted');
    expect(events.single.payload['winner_competitor_id'], isNull);

    // Deliberately does NOT mutate notifier state — the post-game-navigation
    // listener watches isComplete and would otherwise hijack the exit (#706).
    expect(
        container.read(activeCountUpProvider('g1')).value!.gameState.isComplete,
        isFalse);
  });

  test('endGame is a no-op when the game is already complete', () async {
    // 1-round game already at completion via advanceTurn.
    final r1c1 = fullTurn('c1', startSeq: 1, segment: 20, multiplier: 3);
    final r1c2 = turnPendingEnd('c2', startSeq: r1c1.nextSeq);
    final events = [...r1c1.events, ...r1c2.events];
    stubBuild(
      game: makeGame(totalRounds: 1),
      competitors: makeCompetitors(),
      events: events,
    );
    await container.read(activeCountUpProvider('g1').future);
    when(mockEventRepo.getLatestSequence(any))
        .thenAnswer((_) async => events.length);
    await container.read(activeCountUpProvider('g1').notifier).advanceTurn();
    expect(container.read(activeCountUpProvider('g1')).value!.gameState.isComplete,
        isTrue);

    await container.read(activeCountUpProvider('g1').notifier).endGame();

    // Already complete → endGame short-circuits, no abandon write.
    verifyNever(mockGameRepo.appendEventsAndCompleteGame(
      events: anyNamed('events'),
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    ));
  });
}
