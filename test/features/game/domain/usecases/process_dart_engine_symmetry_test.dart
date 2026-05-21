// Engine symmetry test: ProcessDartUseCase (X01) and ProcessCricketDartUseCase
// must emit the same event-log shape on a normal 3-dart turn end:
// `[DartThrown, DartThrown, DartThrown, TurnEnded]`. Codifies Decision 2 of
// issue #132 — TurnEnded is emitted eagerly by the use case on every
// `!turnActive` boundary, not deferred to the presentation layer.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/usecases/process_dart_use_case.dart';
import 'package:dart_lodge/features/game/domain/usecases/process_cricket_dart_use_case.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_cricket_engine.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:mockito/mockito.dart';

import 'process_dart_use_case_test.mocks.dart';

void main() {
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();

    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 0);
    when(mockDartRepo.insertDart(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvents(any)).thenAnswer((_) async {});
    when(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenAnswer((_) async {});
  });

  GameState makeX01State({
    required int score,
    required int dartsThrownInTurn,
    int legsToWin = 2,
  }) {
    return GameState(
      gameId: 'g1',
      gameType: GameType.x01,
      competitors: const [
        CompetitorState(
          competitorId: 'c1',
          name: 'P1',
          playerIds: ['p1'],
          score: 501,
          startingScore: 501,
          isIn: true,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'P2',
          playerIds: ['p2'],
          score: 501,
          startingScore: 501,
          isIn: true,
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: false,
      status: GameEngineStatus.inProgress,
      turnActive: true,
      inStrategy: 'straight',
      outStrategy: 'double',
      legsToWin: legsToWin,
      startingScore: 501,
    ).copyWith(
      competitors: [
        CompetitorState(
          competitorId: 'c1',
          name: 'P1',
          playerIds: const ['p1'],
          score: score,
          startingScore: 501,
          isIn: true,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'P2',
          playerIds: ['p2'],
          score: 501,
          startingScore: 501,
          isIn: true,
        ),
      ],
    );
  }

  GameState makeCricketState({
    required int dartsThrownInTurn,
    int legsToWin = 2,
  }) {
    return GameState(
      gameId: 'g1',
      gameType: GameType.cricket,
      competitors: const [
        CompetitorState(
          competitorId: 'c1',
          name: 'P1',
          playerIds: ['p1'],
          score: 0,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'P2',
          playerIds: ['p2'],
          score: 0,
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: false,
      status: GameEngineStatus.inProgress,
      turnActive: true,
      legsToWin: legsToWin,
      currentLegIndex: 0,
      cricketScoring: 'standard',
    );
  }

  DartThrow makeDart({
    String dartId = 'd1',
    String segment = '20',
    int score = 20,
  }) {
    return DartThrow(
      dartId: dartId,
      gameId: 'g1',
      competitorId: 'c1',
      playerId: 'p1',
      turnNumber: 0,
      dartNumber: 1,
      segment: segment,
      score: score,
    );
  }

  List<GameEvent> captureEvents() {
    final captured = verify(mockEventRepo.appendEvents(captureAny)).captured;
    return captured.first as List<GameEvent>;
  }

  group('engine symmetry — normal 3-dart turn end emits [DartThrown..., TurnEnded]', () {
    test('X01 emits DartThrown + TurnEnded on the 3rd dart', () async {
      final useCase = ProcessDartUseCase(
        mockGameRepo,
        mockEventRepo,
        mockDartRepo,
        StatelessX01Engine(),
      );
      // 3rd dart in the turn: 2 darts already thrown.
      final state = makeX01State(score: 481, dartsThrownInTurn: 2);
      final dart = makeDart(dartId: 'd3', segment: '20', score: 20);

      final newState = await useCase.execute(state, dart);

      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 3);

      final events = captureEvents();
      expect(events.map((e) => e.eventType).toList(),
          ['DartThrown', 'TurnEnded']);
    });

    test('Cricket emits DartThrown + TurnEnded on the 3rd dart', () async {
      final useCase = ProcessCricketDartUseCase(
        mockGameRepo,
        mockEventRepo,
        mockDartRepo,
        StatelessCricketEngine(),
      );
      // 3rd dart in the turn: 2 darts already thrown.
      final state = makeCricketState(dartsThrownInTurn: 2);
      // Hit a cricket segment so the dart is valid; a miss also works
      // but a real segment exercises the typical path.
      final dart = makeDart(dartId: 'd3', segment: '20', score: 20);

      final newState = await useCase.execute(state, dart);

      expect(newState.turnActive, false);
      expect(newState.dartsThrownInTurn, 3);

      final events = captureEvents();
      expect(events.map((e) => e.eventType).toList(),
          ['DartThrown', 'TurnEnded']);
    });

    test('X01 and Cricket emit identical event-type sequences on a full 3-dart turn', () async {
      // Drive both use cases through three darts and assert the cumulative
      // emitted-event-type sequences match.
      Future<List<String>> runFullTurn({
        required Future<GameState> Function(GameState, DartThrow) execute,
        required GameState Function(int score, int darts) makeState,
      }) async {
        final captured = <String>[];
        when(mockEventRepo.appendEvents(any)).thenAnswer((inv) async {
          final list = inv.positionalArguments[0] as List<GameEvent>;
          captured.addAll(list.map((e) => e.eventType));
        });

        var state = makeState(481, 0);
        state = await execute(
            state, makeDart(dartId: 'da1', segment: '20', score: 20));
        state = await execute(
            state, makeDart(dartId: 'da2', segment: '20', score: 20));
        state = await execute(
            state, makeDart(dartId: 'da3', segment: '20', score: 20));
        return captured;
      }

      final x01 = ProcessDartUseCase(
        mockGameRepo,
        mockEventRepo,
        mockDartRepo,
        StatelessX01Engine(),
      );
      final x01Sequence = await runFullTurn(
        execute: x01.execute,
        makeState: (s, d) => makeX01State(score: s, dartsThrownInTurn: d),
      );

      // Reset captures by re-stubbing.
      when(mockEventRepo.appendEvents(any)).thenAnswer((_) async {});

      final cricket = ProcessCricketDartUseCase(
        mockGameRepo,
        mockEventRepo,
        mockDartRepo,
        StatelessCricketEngine(),
      );
      final cricketSequence = await runFullTurn(
        execute: cricket.execute,
        makeState: (s, d) => makeCricketState(dartsThrownInTurn: d),
      );

      expect(x01Sequence,
          ['DartThrown', 'DartThrown', 'DartThrown', 'TurnEnded']);
      expect(cricketSequence,
          ['DartThrown', 'DartThrown', 'DartThrown', 'TurnEnded']);
      expect(x01Sequence, equals(cricketSequence));
    });
  });
}
