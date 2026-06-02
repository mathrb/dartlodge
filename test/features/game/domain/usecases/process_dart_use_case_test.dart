// Process Dart Use Case Unit Tests
// Verifies the coordination between repositories and the engine

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/usecases/process_dart_use_case.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'process_dart_use_case_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late ProcessDartUseCase useCase;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;
  late StatelessX01Engine engine;

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();
    engine = StatelessX01Engine();
    useCase = ProcessDartUseCase(mockGameRepo, mockEventRepo, mockDartRepo, engine);

    // Common stubs
    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 5);
    when(mockDartRepo.insertDart(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvents(any)).thenAnswer((_) async {});
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
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  GameState _makeState({
    String gameId = 'g1',
    int score1 = 501,
    int score2 = 501,
    bool isComplete = false,
    bool turnActive = true,
    int dartsThrownInTurn = 0,
    String outStrategy = 'double',
    String inStrategy = 'straight',
    int legsToWin = 1,
    int legsWon1 = 0,
    bool isIn1 = true,
    int? turnStartScore1,
    int startingScore = 501,
  }) {
    return GameState(
      gameId: gameId,
      gameType: GameType.x01,
      competitors: [
        CompetitorState(
          competitorId: 'c1',
          name: 'P1',
          playerIds: const ['p1'],
          score: score1,
          startingScore: startingScore,
          isIn: isIn1,
          legsWon: legsWon1,
          turnStartScore: turnStartScore1,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'P2',
          playerIds: const ['p2'],
          score: score2,
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

  DartThrow _makeDart({
    String dartId = 'd1',
    String segment = '20',
    int score = 20,
  }) {
    return DartThrow(
      dartId: dartId,
      gameId: 'g1',
      competitorId: 'c1',
      playerId: 'p1',
      turnNumber: 1,
      dartNumber: 1,
      segment: segment,
      score: score,
    );
  }

  List<GameEvent> _captureEvents() {
    final captured = verify(mockEventRepo.appendEvents(captureAny)).captured;
    return captured.first as List<GameEvent>;
  }

  // ── tests ─────────────────────────────────────────────────────────────────

  group('GameAlreadyCompleteException', () {
    test('throws when game is already complete and makes no repo calls', () async {
      final state = _makeState(isComplete: true);
      final dart = _makeDart();

      expect(
        () => useCase.execute(state, dart),
        throwsA(isA<GameAlreadyCompleteException>()),
      );

      verifyZeroInteractions(mockEventRepo);
      verifyZeroInteractions(mockDartRepo);
      verifyZeroInteractions(mockGameRepo);
    });
  });

  group('InvalidGameStateException', () {
    test('throws when isValid returns false and nothing is persisted', () async {
      // Turn not active → DartThrown fails isValid
      final state = _makeState(turnActive: false);
      final dart = _makeDart();

      expect(
        () => useCase.execute(state, dart),
        throwsA(isA<InvalidGameStateException>()),
      );

      verifyNever(mockDartRepo.insertDart(any));
      verifyNever(mockEventRepo.appendEvents(any));
    });
  });

  group('Single dart — no turn end', () {
    test('only DartThrown appended, score updated', () async {
      final state = _makeState(score1: 501, dartsThrownInTurn: 0);
      final dart = _makeDart(segment: '20', score: 20);

      final newState = await useCase.execute(state, dart);

      // Score updated
      expect(newState.competitors[0].score, 481);
      expect(newState.dartsThrownInTurn, 1);
      expect(newState.turnActive, true);

      // Exactly one event persisted
      final events = _captureEvents();
      expect(events.length, 1);
      expect(events[0].eventType, 'DartThrown');
    });

    test('input_method defaults to manual', () async {
      await useCase.execute(
          _makeState(score1: 501, dartsThrownInTurn: 0),
          _makeDart(segment: '20', score: 20));
      expect(_captureEvents()[0].payload['input_method'], 'manual');
    });

    test('input_method is "camera" when threaded from the auto-scorer (#382)',
        () async {
      await useCase.execute(
          _makeState(score1: 501, dartsThrownInTurn: 0),
          _makeDart(segment: '20', score: 20),
          inputMethod: 'camera');
      expect(_captureEvents()[0].payload['input_method'], 'camera');
    });
  });

  group('3rd dart — turn ends normally', () {
    test('DartThrown + TurnEnded appended; turnActive=false, dartsThrownInTurn=3', () async {
      final state = _makeState(score1: 501, dartsThrownInTurn: 2);
      final dart = _makeDart(segment: '20', score: 20);

      final newState = await useCase.execute(state, dart);

      // Score updated; turn rotation deferred to startNextTurn() — finalState
      // still reflects the pre-rotation engine result (currentTurnIndex
      // unchanged, dartsThrownInTurn=3).
      expect(newState.competitors[0].score, 481);
      expect(newState.currentTurnIndex, 0);
      expect(newState.dartsThrownInTurn, 3);
      expect(newState.turnActive, false);

      // DartThrown + TurnEnded persisted — TurnEnded is eager on every
      // !turnActive boundary so the event log is coherent without needing
      // the UI to tap NEXT ROUND. TurnStarted is appended by startNextTurn().
      final events = _captureEvents();
      expect(events.length, 2);
      expect(events[0].eventType, 'DartThrown');
      expect(events[1].eventType, 'TurnEnded');
      // Normal scoring turn must carry turn_score = score-delta per spec
      // §5.2 so the PPR projection counts the right amount (#318). 3-dart
      // turn starting at 501 with last dart scoring 20 → final score 481,
      // dartsThrownInTurn pre-throw = 2 means turnStartScore = 501.
      expect(events[1].payload['turn_score'], 20);
    });
  });

  group('Bust dart', () {
    test('DartThrown(bust=true) + TurnEnded appended; turnActive=false, dartsThrownInTurn=3', () async {
      // score=2, throw single 1 → score becomes 1 → bust
      final state = _makeState(score1: 2, dartsThrownInTurn: 0);
      final dart = _makeDart(segment: '1', score: 1);

      final newState = await useCase.execute(state, dart);

      // Score restored (bust recovery); turn rotation deferred to
      // startNextTurn().
      expect(newState.competitors[0].score, 2);
      expect(newState.currentTurnIndex, 0);
      expect(newState.dartsThrownInTurn, 3);
      expect(newState.turnActive, false);

      // DartThrown(bust) + TurnEnded persisted — eager emission of TurnEnded
      // on every !turnActive boundary (including bust).
      final events = _captureEvents();
      expect(events.length, 2);
      expect(events[0].eventType, 'DartThrown');
      expect(events[0].payload['bust'], true);
      expect(events[1].eventType, 'TurnEnded');
      // The TurnEnded payload must tag the turn as 'bust' so the high-score
      // bucket projection's `reason != 'bust'` guard skips it (#317).
      expect(events[1].payload['reason'], 'bust');
    });
  });

  group('Leg-completing checkout (multi-leg game)', () {
    test('DartThrown → TurnEnded → LegCompleted → TurnStarted', () async {
      // legsToWin=2, c1 has 0 legs won → checkout completes leg, not game
      final state = _makeState(
        score1: 32,
        legsToWin: 2,
        legsWon1: 0,
        outStrategy: 'double',
        startingScore: 501,
      );
      // D16 = double 16 = 32 points
      final dart = _makeDart(segment: 'D16', score: 32);

      final newState = await useCase.execute(state, dart);

      // Leg reset: scores back to 501, new leg started, c1 goes first
      expect(newState.competitors[0].score, 501);
      expect(newState.turnActive, true);
      expect(newState.currentLegIndex, 1);

      final events = _captureEvents();
      expect(events.length, 4);
      expect(events[0].eventType, 'DartThrown');
      expect(events[1].eventType, 'TurnEnded');
      expect(events[1].payload['reason'], 'normal');
      // Leg-completing dart: the engine resets `score` to startingScore
      // for the new leg before the use case computes turn_score. Use the
      // pre-dart score as the full deduction (#318). Player scored 32 to
      // checkout.
      expect(events[1].payload['turn_score'], 32);
      expect(events[2].eventType, 'LegCompleted');
      expect(events[2].payload['winner_competitor_id'], 'c1');
      expect(events[3].eventType, 'TurnStarted');

      // completeGame must NOT be called
      verifyNever(mockGameRepo.completeGame(
        gameId: anyNamed('gameId'),
        winnerCompetitorId: anyNamed('winnerCompetitorId'),
        endTime: anyNamed('endTime'),
      ));
    });
  });

  group('Game-completing checkout', () {
    test('DartThrown → TurnEnded → LegCompleted → GameCompleted; completeGame called', () async {
      // legsToWin=1 → checkout completes the game
      final state = _makeState(
        score1: 32,
        legsToWin: 1,
        outStrategy: 'double',
      );
      final dart = _makeDart(segment: 'D16', score: 32);

      final newState = await useCase.execute(state, dart);

      expect(newState.isComplete, true);
      expect(newState.winnerCompetitorId, 'c1');

      // Game-end persistence goes through the atomic
      // appendEventsAndCompleteGame method (#188), NOT appendEvents +
      // completeGame separately.
      verifyNever(mockEventRepo.appendEvents(any));
      verifyNever(mockGameRepo.completeGame(
        gameId: anyNamed('gameId'),
        winnerCompetitorId: anyNamed('winnerCompetitorId'),
        endTime: anyNamed('endTime'),
      ));

      // Capture and assert the atomic call's args in one verify so the
      // call isn't consumed twice (each `verify(...)` consumes the call).
      final call = verify(mockGameRepo.appendEventsAndCompleteGame(
        events: captureAnyNamed('events'),
        gameId: captureAnyNamed('gameId'),
        winnerCompetitorId: captureAnyNamed('winnerCompetitorId'),
        endTime: anyNamed('endTime'),
      ))..called(1);
      final captured = call.captured;
      final events = captured[0] as List<GameEvent>;
      expect(captured[1], 'g1');
      expect(captured[2], 'c1');

      expect(events.length, 4);
      expect(events[0].eventType, 'DartThrown');
      expect(events[1].eventType, 'TurnEnded');
      expect(events[1].payload['reason'], 'normal');
      expect(events[2].eventType, 'LegCompleted');
      expect(events[3].eventType, 'GameCompleted');
      expect(events[3].payload['winner_competitor_id'], 'c1');
    });
  });

  group('Persistence ordering', () {
    test('dart is persisted before events', () async {
      final state = _makeState(score1: 501, dartsThrownInTurn: 0);
      final dart = _makeDart();

      await useCase.execute(state, dart);

      verifyInOrder([
        mockDartRepo.insertDart(dart),
        mockEventRepo.appendEvents(any),
      ]);
    });
  });

  group('Event localSequence', () {
    test('events have strictly ascending localSequence starting after latest', () async {
      // getLatestSequence returns 5, so first event should be 6
      when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 5);

      // Use a leg-completing scenario (4 events: DartThrown, TurnEnded, LegCompleted, TurnStarted)
      final state = _makeState(
        score1: 32,
        legsToWin: 2,
        legsWon1: 0,
        outStrategy: 'double',
        startingScore: 501,
      );
      final dart = _makeDart(segment: 'D16', score: 32);

      await useCase.execute(state, dart);

      final events = _captureEvents();
      expect(events.length, 4);
      expect(events[0].localSequence, 6);
      expect(events[1].localSequence, 7);
      expect(events[2].localSequence, 8);
      expect(events[3].localSequence, 9);
    });
  });

  group('DartThrown eventId', () {
    test('DartThrown eventId equals dart.dartId', () async {
      final state = _makeState(score1: 501, dartsThrownInTurn: 0);
      final dart = _makeDart(dartId: 'my-dart-uuid');

      await useCase.execute(state, dart);

      final events = _captureEvents();
      expect(events[0].eventType, 'DartThrown');
      expect(events[0].eventId, 'my-dart-uuid');
    });
  });
}
