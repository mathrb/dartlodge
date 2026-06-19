// Undo Last Dart Use Case Unit Tests
// Verifies guard conditions, event sequencing, and state replay correctness

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_around_the_clock_engine.dart';
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
          // Mirror GameState.initial: per-competitor startingScore is what
          // engine._resetLeg reads when starting a fresh leg.
          startingScore: startingScore,
          isIn: true,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'P2',
          playerIds: const ['p2'],
          score: startingScore,
          startingScore: startingScore,
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

    test(
        'correction deletes the dart and never re-inserts it — no position is '
        're-inherited (#571)', () async {
      // The corrected dart carries a recorded impact position. Undo must NOT
      // re-emit it: the physical DartThrow row is deleted and the original
      // DartThrown is skipped on replay, so the position can never resurface.
      // A re-thrown dart is a fresh manual entry → x/y null by design.
      final state = _makeState(score1: 481, dartsThrownInTurn: 1);
      final events = _eventLog(dartEventIds: ['dt1']);
      // Give the corrected DartThrown an x/y in its payload to prove the value
      // is discarded by the delete-and-skip flow, not threaded forward.
      final withPos = [
        for (final e in events)
          if (e.eventId == 'dt1')
            e.copyWith(payload: {...e.payload, 'x': 0.2, 'y': -0.4})
          else
            e,
      ];
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => withPos);

      await useCase.execute(state);

      // The dart row is deleted; no DartThrow is ever inserted by undo, so the
      // old position has nowhere to land.
      verify(mockDartRepo.deleteDart('dt1')).called(1);
      verifyNever(mockDartRepo.insertDart(any));

      // The appended DartCorrected itself carries no position.
      final correctionEvent =
          verify(mockEventRepo.appendEvent(captureAny)).captured.first
              as GameEvent;
      expect(correctionEvent.payload.containsKey('x'), isFalse);
      expect(correctionEvent.payload.containsKey('y'), isFalse);
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

  // ── regression: issue #165 ────────────────────────────────────────────────

  group('Issue #165 — undo across leg boundary restores per-competitor '
      'startingScore', () {
    // X01, double-out, startingScore = 40 (chosen so D20 wins outright),
    // legsToWin = 2.
    //
    // Sequence:
    //   1) c1 throws D20 → leg 1 win, engine internally resets the leg.
    //   2) c1 throws S1 in leg 2 → score 40 - 1 = 39.
    //   3) Undo S1.
    //
    // Expected: c1.score == 40 (per-competitor startingScore preserved).
    // Pre-fix: c1.score == 0 — _buildInitialState omitted CompetitorState.
    // startingScore (defaulted to 0), and engine._resetLeg, which reads
    // competitor.startingScore, restarted every leg at zero.

    GameState _legBoundaryState() {
      return GameState(
        gameId: 'g1',
        gameType: GameType.x01,
        competitors: [
          const CompetitorState(
            competitorId: 'c1',
            name: 'P1',
            playerIds: ['p1'],
            score: 39,
            startingScore: 40,
            legsWon: 1,
            isIn: true,
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'P2',
            playerIds: ['p2'],
            score: 40,
            startingScore: 40,
            isIn: true,
          ),
        ],
        currentTurnIndex: 0,
        dartsThrownInTurn: 1,
        currentLegIndex: 1,
        isComplete: false,
        status: GameEngineStatus.inProgress,
        turnActive: true,
        inStrategy: 'straight',
        outStrategy: 'double',
        legsToWin: 2,
        startingScore: 40,
      );
    }

    List<GameEvent> _legBoundaryEvents() => [
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
            eventId: 'e-turn-0',
            eventType: 'TurnStarted',
            localSequence: 2,
            payload: {
              'competitor_id': 'c1',
              'turn_index': 0,
              'leg_index': 0,
            },
          ),
          _event(
            eventId: 'dt-d20',
            eventType: 'DartThrown',
            localSequence: 3,
            payload: {
              'competitor_id': 'c1',
              'segment': 20,
              'multiplier': 2,
              'input_method': 'manual',
            },
          ),
          _event(
            eventId: 'e-turn-1',
            eventType: 'TurnStarted',
            localSequence: 4,
            payload: {
              'competitor_id': 'c1',
              'turn_index': 0,
              'leg_index': 1,
            },
          ),
          _event(
            eventId: 'dt-s1',
            eventType: 'DartThrown',
            localSequence: 5,
            payload: {
              'competitor_id': 'c1',
              'segment': 1,
              'multiplier': 1,
              'input_method': 'manual',
            },
          ),
        ];

    test('undo of the only dart in leg 2 restores c1.score to 40, not 0',
        () async {
      final state = _legBoundaryState();
      when(mockEventRepo.getEventsForGame('g1'))
          .thenAnswer((_) async => _legBoundaryEvents());

      final newState = await useCase.execute(state);

      expect(newState.competitors[0].score, 40,
          reason: 'leg 2 must restart at startingScore, not 0');
      expect(newState.competitors[0].startingScore, 40);
      expect(newState.competitors[1].score, 40);
      expect(newState.competitors[1].startingScore, 40);
      expect(newState.competitors[0].legsWon, 1,
          reason: 'leg 1 was already won; the undone dart was in leg 2');
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
        cricketScoring: 'no-score',
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

  // ── regression: issue #116 ────────────────────────────────────────────────

  group('Issue #116 — Around the Clock undo restores currentTarget', () {
    GameEvent _atcEvent(
      String id,
      String type,
      int seq, [
      Map<String, dynamic> payload = const {},
    ]) =>
        GameEvent(
          eventId: id,
          gameId: 'atc',
          eventType: type,
          localSequence: seq,
          occurredAt: DateTime(2024),
          payload: payload,
          synced: false,
          actorId: 'system',
          source: EventSource.client,
        );

    GameEvent _atcDart(String id, int seq, int segment, int multiplier) =>
        _atcEvent(id, 'DartThrown', seq, {
          'competitor_id': 'cA',
          'segment': segment,
          'multiplier': multiplier,
          'input_method': 'manual',
        });

    GameState _atcState({
      required String variant,
      required int currentTarget,
      required int dartsThrownInTurn,
    }) {
      return GameState(
        gameId: 'atc',
        gameType: GameType.aroundTheClock,
        competitors: [
          CompetitorState(
            competitorId: 'cA',
            name: 'A',
            playerIds: const ['pA'],
            score: 0,
            isIn: true,
            currentTarget: currentTarget,
          ),
        ],
        currentTurnIndex: 0,
        dartsThrownInTurn: dartsThrownInTurn,
        isComplete: false,
        status: GameEngineStatus.inProgress,
        turnActive: true,
        legsToWin: 1,
        startingScore: 0,
        aroundTheClockVariant: variant,
      );
    }

    test('undoing the first hit restores currentTarget = 1 (standard)',
        () async {
      final atcEngine = StatelessAroundTheClockEngine();
      final atcUseCase =
          UndoLastDartUseCase(mockEventRepo, mockDartRepo, atcEngine);

      // Player hit target 1 once; engine advanced currentTarget to 2.
      final state = _atcState(
        variant: 'standard',
        currentTarget: 2,
        dartsThrownInTurn: 1,
      );

      final events = <GameEvent>[
        _atcEvent('gc', 'GameCreated', 1, {
          'ruleset': 'aroundTheClock',
          'rules_payload': {'variant': 'standard'},
          'competitors': ['cA'],
        }),
        _atcEvent('tsA', 'TurnStarted', 2,
            {'competitor_id': 'cA', 'turn_index': 0, 'leg_index': 0}),
        _atcDart('d1', 3, 1, 1), // S1 — hits target 1
      ];
      when(mockEventRepo.getEventsForGame('atc'))
          .thenAnswer((_) async => events);
      when(mockEventRepo.getLatestSequence('atc')).thenAnswer((_) async => 3);

      final newState = await atcUseCase.execute(state);

      expect(newState.competitors[0].currentTarget, 1,
          reason: 'After undo, target reverts to the variant start (1)');
      expect(newState.dartsThrownInTurn, 0);
      expect(newState.aroundTheClockVariant, 'standard');
    });

    test('subsequent hit after undo registers (currentTarget advances)',
        () async {
      final atcEngine = StatelessAroundTheClockEngine();
      final atcUseCase =
          UndoLastDartUseCase(mockEventRepo, mockDartRepo, atcEngine);

      final state = _atcState(
        variant: 'standard',
        currentTarget: 2,
        dartsThrownInTurn: 1,
      );

      final events = <GameEvent>[
        _atcEvent('gc', 'GameCreated', 1, {
          'ruleset': 'aroundTheClock',
          'rules_payload': {'variant': 'standard'},
          'competitors': ['cA'],
        }),
        _atcEvent('tsA', 'TurnStarted', 2,
            {'competitor_id': 'cA', 'turn_index': 0, 'leg_index': 0}),
        _atcDart('d1', 3, 1, 1),
      ];
      when(mockEventRepo.getEventsForGame('atc'))
          .thenAnswer((_) async => List.of(events));
      when(mockEventRepo.getLatestSequence('atc')).thenAnswer((_) async => 3);

      final afterUndo = await atcUseCase.execute(state);

      // Pre-fix, currentTarget was null here — re-throwing S1 would not
      // register. Verify the engine still treats segment 1 as a hit.
      final hitAgain = atcEngine
          .apply(
            afterUndo,
            _atcDart('d2', 5, 1, 1),
          )
          .state;

      expect(hitAgain.competitors[0].currentTarget, 2,
          reason: 'Replayed hit on target 1 advances target to 2');
      expect(hitAgain.dartsThrownInTurn, 1);
    });

    test('reverse variant restores currentTarget = 20', () async {
      final atcEngine = StatelessAroundTheClockEngine();
      final atcUseCase =
          UndoLastDartUseCase(mockEventRepo, mockDartRepo, atcEngine);

      // Reverse variant starts at 20, descends. After hitting 20, target=19.
      final state = _atcState(
        variant: 'reverse',
        currentTarget: 19,
        dartsThrownInTurn: 1,
      );

      final events = <GameEvent>[
        _atcEvent('gc', 'GameCreated', 1, {
          'ruleset': 'aroundTheClock',
          'rules_payload': {'variant': 'reverse'},
          'competitors': ['cA'],
        }),
        _atcEvent('tsA', 'TurnStarted', 2,
            {'competitor_id': 'cA', 'turn_index': 0, 'leg_index': 0}),
        _atcDart('d1', 3, 20, 1),
      ];
      when(mockEventRepo.getEventsForGame('atc'))
          .thenAnswer((_) async => events);
      when(mockEventRepo.getLatestSequence('atc')).thenAnswer((_) async => 3);

      final newState = await atcUseCase.execute(state);

      expect(newState.competitors[0].currentTarget, 20);
      expect(newState.aroundTheClockVariant, 'reverse');
    });
  });

  group('Crazy Cricket — undo at turn boundary supersedes CrazyTargetsRolled',
      () {
    // After undoing the dart that triggered a turn change in Crazy
    // Cricket, the TurnStarted for the new (now-cancelled) turn is
    // superseded. The CrazyTargetsRolled emitted immediately after it
    // must also be superseded, otherwise replay overwrites
    // cricketTargets with the cancelled turn's rolled set.

    GameState _crazyState() {
      return GameState(
        gameId: 'cg',
        gameType: GameType.cricket,
        competitors: [
          const CompetitorState(
            competitorId: 'cA',
            name: 'A',
            playerIds: ['pA'],
            score: 0,
            isIn: true,
          ),
          const CompetitorState(
            competitorId: 'cB',
            name: 'B',
            playerIds: ['pB'],
            score: 0,
            isIn: true,
          ),
        ],
        currentTurnIndex: 0,
        dartsThrownInTurn: 3,
        isComplete: false,
        status: GameEngineStatus.inProgress,
        turnActive: true,
        legsToWin: 1,
        startingScore: 0,
        cricketScoring: 'standard',
        cricketTargetMode: 'crazy',
        cricketTargets: const [3, 7, 11, 14, 18, 20],
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

    test('replay does NOT apply the cancelled turn\'s CrazyTargetsRolled',
        () async {
      final engine = StatelessCricketEngine();
      final useCase =
          UndoLastDartUseCase(mockEventRepo, mockDartRepo, engine);

      final events = <GameEvent>[
        _ev('gc', 'GameCreated', 1, {
          'ruleset': 'CRICKET',
          'rules_payload': {
            'scoring': 'standard',
            'targetMode': 'crazy',
            'numbers': ['15', '16', '17', '18', '19', '20', 'bull'],
          },
          'competitors': ['cA', 'cB'],
        }),
        _ev('tsA', 'TurnStarted', 2,
            {'competitor_id': 'cA', 'turn_index': 0, 'leg_index': 0}),
        _ev('rA', 'CrazyTargetsRolled', 3, {
          'competitor_id': 'cA',
          'round': 1,
          'open_targets': [3, 7, 11, 14, 18, 20],
        }),
        _ev('d1', 'DartThrown', 4, {
          'competitor_id': 'cA',
          'segment': 3,
          'multiplier': 1,
          'input_method': 'manual',
        }),
        _ev('d2', 'DartThrown', 5, {
          'competitor_id': 'cA',
          'segment': 7,
          'multiplier': 1,
          'input_method': 'manual',
        }),
        _ev('d3', 'DartThrown', 6, {
          'competitor_id': 'cA',
          'segment': 11,
          'multiplier': 1,
          'input_method': 'manual',
        }),
        _ev('teA', 'TurnEnded', 7, {'competitor_id': 'cA'}),
        _ev('tsB', 'TurnStarted', 8,
            {'competitor_id': 'cB', 'turn_index': 1, 'leg_index': 0}),
        // Critical: B's turn has a DIFFERENT rolled set. If undo of d3
        // doesn't supersede this CrazyTargetsRolled, the replay state
        // will end up with cricketTargets = [2,5,8,17,18,20].
        _ev('rB', 'CrazyTargetsRolled', 9, {
          'competitor_id': 'cB',
          'round': 1,
          'open_targets': [2, 5, 8, 17, 18, 20],
        }),
      ];
      when(mockEventRepo.getEventsForGame('cg'))
          .thenAnswer((_) async => events);
      when(mockEventRepo.getLatestSequence('cg'))
          .thenAnswer((_) async => 9);

      // Capture the superseded ids from the appended DartCorrected.
      final correctionPayloads = <Map<String, dynamic>>[];
      when(mockEventRepo.appendEvent(any)).thenAnswer((inv) async {
        final e = inv.positionalArguments[0] as GameEvent;
        if (e.eventType == 'DartCorrected') correctionPayloads.add(e.payload);
      });

      final newState = await useCase.execute(_crazyState());

      // Both A's TurnEnded, B's TurnStarted, and B's CrazyTargetsRolled
      // are superseded (they all describe the now-cancelled turn change).
      expect(correctionPayloads, isNotEmpty);
      final superseded =
          (correctionPayloads.first['superseded_event_ids'] as List).cast<String>();
      expect(superseded, containsAll(['teA', 'tsB', 'rB']));

      // Post-undo, cricketTargets must be A's set, not B's.
      expect(newState.cricketTargets, [3, 7, 11, 14, 18, 20]);
    });
  });
}
