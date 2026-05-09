// Undo Last Dart Use Case Unit Tests
// Verifies guard conditions, event sequencing, and state replay correctness

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_cricket_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/usecases/undo_last_dart_use_case.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'undo_last_dart_use_case_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late UndoLastDartUseCase useCase;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;
  late StatelessX01Engine engine;

  // ── helpers ───────────────────────────────────────────────────────────────

  GameEvent _event({
    required String eventId,
    required String eventType,
    required int localSequence,
    Map<String, dynamic> payload = const {},
  }) {
    return GameEvent(
      eventId: eventId,
      gameId: 'g1',
      eventType: eventType,
      localSequence: localSequence,
      occurredAt: DateTime(2024),
      payload: payload,
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );
  }

  GameState _makeState({
    bool isComplete = false,
    int dartsThrownInTurn = 1,
    int score1 = 481,
    bool turnActive = true,
    String inStrategy = 'straight',
    String outStrategy = 'double',
    int legsToWin = 1,
    int startingScore = 501,
  }) {
    return GameState(
      gameId: 'g1',
      gameType: GameType.x01,
      competitors: [
        CompetitorState(
          competitorId: 'c1',
          name: 'P1',
          playerIds: const ['p1'],
          score: score1,
          isIn: true,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'P2',
          playerIds: const ['p2'],
          score: 501,
          isIn: true,
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: isComplete,
      status: GameEngineStatus.inProgress,
      turnActive: turnActive,
      inStrategy: inStrategy,
      outStrategy: outStrategy,
      legsToWin: legsToWin,
      startingScore: startingScore,
    );
  }

  /// Minimal event log: GameCreated + TurnStarted + N DartThrown events
  List<GameEvent> _eventLog({required List<String> dartEventIds}) {
    final events = <GameEvent>[
      _event(
        eventId: 'e-created',
        eventType: 'GameCreated',
        localSequence: 1,
        payload: {
          'ruleset': 'X01',
          'rules_payload': {},
          'competitors': ['c1', 'c2'],
        },
      ),
      _event(
        eventId: 'e-turn',
        eventType: 'TurnStarted',
        localSequence: 2,
        payload: {'competitor_id': 'c1', 'turn_index': 0, 'leg_index': 0},
      ),
    ];
    for (var i = 0; i < dartEventIds.length; i++) {
      events.add(_event(
        eventId: dartEventIds[i],
        eventType: 'DartThrown',
        localSequence: 3 + i,
        payload: {
          'competitor_id': 'c1',
          'segment': 20,
          'multiplier': 1,
          'input_method': 'manual',
        },
      ));
    }
    return events;
  }

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();
    engine = StatelessX01Engine();
    useCase = UndoLastDartUseCase(
        mockEventRepo, mockDartRepo, engine);

    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 10);
    when(mockEventRepo.appendEvent(any)).thenAnswer((_) async {});
    when(mockDartRepo.deleteDart(any)).thenAnswer((_) async {});
  });

  // ── guard conditions ──────────────────────────────────────────────────────

  group('GameAlreadyCompleteException', () {
    test('throws when game is complete and makes no repo calls', () async {
      final state = _makeState(isComplete: true);

      expect(
        () => useCase.execute(state),
        throwsA(isA<GameAlreadyCompleteException>()),
      );

      verifyZeroInteractions(mockEventRepo);
      verifyZeroInteractions(mockDartRepo);
      verifyZeroInteractions(mockGameRepo);
    });
  });

  group('NoDartsToUndoException', () {
    test('throws when no DartThrown events exist in the game', () async {
      final state = _makeState(dartsThrownInTurn: 0, turnActive: true);
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => []);

      expect(
        () => useCase.execute(state),
        throwsA(isA<NoDartsToUndoException>()),
      );

      verifyNever(mockDartRepo.deleteDart(any));
    });

    test('throws when all darts in event log are already corrected', () async {
      // dartsThrownInTurn=1 but the only DartThrown is already corrected
      final state = _makeState(dartsThrownInTurn: 1);
      final events = [
        _event(
          eventId: 'e-created',
          eventType: 'GameCreated',
          localSequence: 1,
          payload: {'ruleset': 'X01', 'rules_payload': {}, 'competitors': []},
        ),
        _event(
          eventId: 'e-turn',
          eventType: 'TurnStarted',
          localSequence: 2,
          payload: {'competitor_id': 'c1', 'turn_index': 0, 'leg_index': 0},
        ),
        _event(
          eventId: 'dt1',
          eventType: 'DartThrown',
          localSequence: 3,
          payload: {
            'competitor_id': 'c1',
            'segment': 20,
            'multiplier': 1,
            'input_method': 'manual',
          },
        ),
        _event(
          eventId: 'corr1',
          eventType: 'DartCorrected',
          localSequence: 4,
          payload: {'original_event_id': 'dt1', 'corrected_dart_id': 'dt1'},
        ),
      ];
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => events);

      expect(
        () => useCase.execute(state),
        throwsA(isA<NoDartsToUndoException>()),
      );
    });
  });

  // ── single dart undo ──────────────────────────────────────────────────────

  group('Single dart undo', () {
    test('score reverts to pre-dart value (501 → 481 → 501)', () async {
      final state = _makeState(score1: 481, dartsThrownInTurn: 1);
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => _eventLog(dartEventIds: ['dt1']));

      final newState = await useCase.execute(state);

      expect(newState.competitors[0].score, 501);
      expect(newState.dartsThrownInTurn, 0);
      expect(newState.turnActive, true);
    });

    test('dartsThrownInTurn decreases by 1 after undo', () async {
      final state = _makeState(score1: 481, dartsThrownInTurn: 1);
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => _eventLog(dartEventIds: ['dt1']));

      final newState = await useCase.execute(state);

      expect(newState.dartsThrownInTurn, 0);
    });
  });

  // ── second dart undo ──────────────────────────────────────────────────────

  group('Second dart undo', () {
    test('reverts to first-dart state (501 → 481 → 461 → 481)', () async {
      // Two singles of 20 scored: 501-20-20=461
      final state = _makeState(score1: 461, dartsThrownInTurn: 2);
      when(mockEventRepo.getEventsForGame('g1')).thenAnswer(
          (_) async => _eventLog(dartEventIds: ['dt1', 'dt2']));

      final newState = await useCase.execute(state);

      expect(newState.competitors[0].score, 481);
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.turnActive, true);
      expect(newState.currentTurnIndex, 0); // still c1's turn
    });
  });

  // ── event sequencing ──────────────────────────────────────────────────────

  group('Event sequencing', () {
    test('DartCorrected is appended before deleteDart is called', () async {
      final state = _makeState(score1: 481, dartsThrownInTurn: 1);
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => _eventLog(dartEventIds: ['dt1']));

      await useCase.execute(state);

      verifyInOrder([
        mockEventRepo.appendEvent(any),
        mockDartRepo.deleteDart(any),
      ]);
    });

    test('DartCorrected payload references the corrected event ID', () async {
      final state = _makeState(score1: 481, dartsThrownInTurn: 1);
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => _eventLog(dartEventIds: ['dt1']));

      await useCase.execute(state);

      final captured =
          verify(mockEventRepo.appendEvent(captureAny)).captured;
      final correctionEvent = captured.first as GameEvent;

      expect(correctionEvent.eventType, 'DartCorrected');
      expect(correctionEvent.payload['original_event_id'], 'dt1');
      expect(correctionEvent.payload['corrected_dart_id'], 'dt1');
      expect(correctionEvent.payload['superseded_event_ids'], isEmpty);
    });

    test('deleteDart is called with the correct dartId', () async {
      final state = _makeState(score1: 481, dartsThrownInTurn: 1);
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => _eventLog(dartEventIds: ['dt1']));

      await useCase.execute(state);

      verify(mockDartRepo.deleteDart('dt1')).called(1);
    });

    test('DartCorrected localSequence is latest + 1', () async {
      when(mockEventRepo.getLatestSequence('g1')).thenAnswer((_) async => 7);

      final state = _makeState(score1: 481, dartsThrownInTurn: 1);
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => _eventLog(dartEventIds: ['dt1']));

      await useCase.execute(state);

      final captured =
          verify(mockEventRepo.appendEvent(captureAny)).captured;
      final correctionEvent = captured.first as GameEvent;
      expect(correctionEvent.localSequence, 8);
    });
  });

  // ── replay correctness ────────────────────────────────────────────────────

  group('Replay correctness', () {
    test('game-level metadata (gameId, gameType, strategies) is preserved',
        () async {
      final state = _makeState(
        score1: 481,
        dartsThrownInTurn: 1,
        inStrategy: 'double',
        outStrategy: 'double',
        legsToWin: 3,
      );
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => _eventLog(dartEventIds: ['dt1']));

      final newState = await useCase.execute(state);

      expect(newState.gameId, 'g1');
      expect(newState.gameType, GameType.x01);
      expect(newState.inStrategy, 'double');
      expect(newState.outStrategy, 'double');
      expect(newState.legsToWin, 3);
    });

    test('second undo leaves state at zero darts and original score', () async {
      // Two darts thrown; undo twice
      var state = _makeState(score1: 461, dartsThrownInTurn: 2);
      final events = _eventLog(dartEventIds: ['dt1', 'dt2']);
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => List.of(events));

      // First undo: removes dt2
      final stateAfterFirst = await useCase.execute(state);
      expect(stateAfterFirst.competitors[0].score, 481);
      expect(stateAfterFirst.dartsThrownInTurn, 1);

      // Simulate the DartCorrected for dt2 being in the log now
      final eventsWithCorr2 = [
        ...events,
        _event(
          eventId: 'corr-dt2',
          eventType: 'DartCorrected',
          localSequence: 10,
          payload: {
            'original_event_id': 'dt2',
            'corrected_dart_id': 'dt2',
          },
        ),
      ];
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => eventsWithCorr2);

      state = stateAfterFirst;
      // Second undo: removes dt1
      final stateAfterSecond = await useCase.execute(state);
      expect(stateAfterSecond.competitors[0].score, 501);
      expect(stateAfterSecond.dartsThrownInTurn, 0);
    });
  });

  // ── regression: issue #108 ────────────────────────────────────────────────

  group('Issue #108 — undo across turn boundary does not transfer marks',
      () {
    // Cricket no-score, 2 players, legsToWin=1.
    //
    // Scenario from the bug report:
    //   1) Player A throws 20, 20, 20.
    //   2) Press next player.
    //   3) Player B hits 19.
    //   4) Undo (removes B's 19).
    //   5) Undo (removes A's third 20).
    //   6) Player A throws 20.
    //   7) Press next player.
    //   8) Player B hits 19.
    //   9) Undo.
    //
    // Expected: A has 3 marks on 20, B has 0 marks on 20.
    // Pre-fix: A had 2 marks on 20, B had 1 mark on 20 — the third 20 thrown
    // in step 6 was attributed to B because the stale TurnStarted from
    // step 2 (now superseded by the step-5 undo) was being re-applied
    // during the step-9 replay, shifting currentTurnIndex to B.

    GameState _cricketState() {
      return GameState(
        gameId: 'cg',
        gameType: GameType.cricket,
        competitors: [
          CompetitorState(
            competitorId: 'cA',
            name: 'A',
            playerIds: const ['pA'],
            score: 0,
            isIn: true,
          ),
          CompetitorState(
            competitorId: 'cB',
            name: 'B',
            playerIds: const ['pB'],
            score: 0,
            isIn: true,
          ),
        ],
        currentTurnIndex: 0,
        dartsThrownInTurn: 0,
        isComplete: false,
        status: GameEngineStatus.inProgress,
        turnActive: true,
        legsToWin: 1,
        startingScore: 0,
        cricketVariant: 'no-score',
      );
    }

    GameEvent _ev(
      String id,
      String type,
      int seq, [
      Map<String, dynamic> payload = const {},
    ]) =>
        GameEvent(
          eventId: id,
          gameId: 'cg',
          eventType: type,
          localSequence: seq,
          occurredAt: DateTime(2024),
          payload: payload,
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        );

    GameEvent _dart(String id, int seq, String competitorId, int segment) =>
        _ev(id, 'DartThrown', seq, {
          'competitor_id': competitorId,
          'segment': segment,
          'multiplier': 1,
          'input_method': 'manual',
        });

    test(
        'third undo (after re-throw) attributes new mark to A, not B',
        () async {
      final cricketEngine = StatelessCricketEngine();
      final cricketUseCase =
          UndoLastDartUseCase(mockEventRepo, mockDartRepo, cricketEngine);

      // Mutable event log the mock returns; each undo appends to it via
      // [appendEvent]'s side effect so the next undo sees prior corrections.
      final events = <GameEvent>[
        _ev('gc', 'GameCreated', 1, {
          'ruleset': 'cricket',
          'rules_payload': {},
          'competitors': ['cA', 'cB'],
        }),
        _ev('tsA1', 'TurnStarted', 2,
            {'competitor_id': 'cA', 'turn_index': 0, 'leg_index': 0}),
        _dart('dA1', 3, 'cA', 20),
        _dart('dA2', 4, 'cA', 20),
        _dart('dA3', 5, 'cA', 20),
        _ev('teA1', 'TurnEnded', 6, {'competitor_id': 'cA'}),
        _ev('tsB1', 'TurnStarted', 7,
            {'competitor_id': 'cB', 'turn_index': 1, 'leg_index': 0}),
        _dart('dB1', 8, 'cB', 19),
      ];

      when(mockEventRepo.getEventsForGame('cg'))
          .thenAnswer((_) async => List.of(events));
      when(mockEventRepo.getLatestSequence('cg'))
          .thenAnswer((_) async => events.last.localSequence);
      when(mockEventRepo.appendEvent(any))
          .thenAnswer((invocation) async {
        events.add(invocation.positionalArguments[0] as GameEvent);
      });
      when(mockDartRepo.deleteDart(any)).thenAnswer((_) async {});

      // Step 4: First undo — removes B's 19.
      var state = await cricketUseCase.execute(_cricketState());
      final corr1 = events.last;
      expect(corr1.eventType, 'DartCorrected');
      expect(corr1.payload['original_event_id'], 'dB1');
      expect(corr1.payload['superseded_event_ids'], isEmpty);
      expect(state.competitors[0].marksPerNumber['20'], 3);
      expect(state.competitors[1].marksPerNumber['19'] ?? 0, 0);

      // Step 5: Second undo — removes A's third 20. The TurnEnded(A) and
      // TurnStarted(B) bracketing the now-empty B turn must be persisted as
      // superseded so future replays don't shift currentTurnIndex back to B.
      state = await cricketUseCase.execute(state);
      final corr2 = events.last;
      expect(corr2.payload['original_event_id'], 'dA3');
      expect(
        (corr2.payload['superseded_event_ids'] as List).cast<String>(),
        containsAll(<String>['teA1', 'tsB1']),
      );
      expect(state.competitors[0].marksPerNumber['20'], 2);
      expect(state.currentTurnIndex, 0);
      expect(state.dartsThrownInTurn, 2);

      // Steps 6–8: A throws 20 (third mark), next player, B throws 19.
      events.addAll(<GameEvent>[
        _dart('dA4', 11, 'cA', 20),
        _ev('teA2', 'TurnEnded', 12, {'competitor_id': 'cA'}),
        _ev('tsB2', 'TurnStarted', 13,
            {'competitor_id': 'cB', 'turn_index': 1, 'leg_index': 0}),
        _dart('dB2', 14, 'cB', 19),
      ]);

      // Step 9: Third undo — removes B's 19. The regression: replay must
      // honour the persisted superseded ids so DA4 is attributed to A and
      // does NOT bleed onto B's marks.
      // State passed to undo only matters for guards; replay rebuilds it.
      final stateBeforeUndo = state.copyWith(
        currentTurnIndex: 1,
        dartsThrownInTurn: 1,
      );
      state = await cricketUseCase.execute(stateBeforeUndo);

      expect(state.competitors[0].marksPerNumber['20'], 3,
          reason: 'A keeps all 3 marks on 20');
      expect(state.competitors[1].marksPerNumber['20'] ?? 0, 0,
          reason: 'B never hit 20 — must not inherit a mark from A');
      expect(state.competitors[1].marksPerNumber['19'] ?? 0, 0,
          reason: "B's 19 was undone");
    });
  });
}
