// Process Dart Use Case Unit Tests
// Verifies the coordination between repositories and the engine

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/domain/entities/dart_throw.dart';
import 'package:my_darts/features/game/domain/models/game_state.dart';
import 'package:my_darts/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_event_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:my_darts/features/game/domain/usecases/process_dart_use_case.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/engines/base_game_engine.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'process_dart_use_case_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late ProcessDartUseCase useCase;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  setUp(() {
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();
    useCase = ProcessDartUseCase(mockEventRepo, mockDartRepo);
  });

  test('should process a valid dart throw', () async {
    // Start with turn not active
    var initialState = GameState(
      gameId: 'g1',
      gameType: GameType.x01,
      competitors: [
        const CompetitorState(competitorId: 'c1', name: 'P1', playerIds: ['p1'], score: 501, isIn: true),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      status: GameEngineStatus.inProgress,
      turnActive: false, // Turn not active initially
      inStrategy: 'straight',
      outStrategy: 'double',
    );
    
    // Start the turn first
    initialState = initialState.copyWith(turnActive: true);

    final dartThrow = DartThrow(
      dartId: 'd1',
      gameId: 'g1',
      competitorId: 'c1',
      playerId: 'p1',
      turnNumber: 0,
      dartNumber: 1,
      segment: '20',
      score: 20,
    );

    when(mockEventRepo.getLatestSequence('g1')).thenAnswer((_) async => 0);
    when(mockDartRepo.insertDart(any)).thenAnswer((_) async => {});
    when(mockEventRepo.appendEvent(any)).thenAnswer((_) async => {});

    final newState = await useCase.execute(initialState, dartThrow);

    expect(newState.competitors[0].score, 481);
    expect(newState.dartsThrownInTurn, 1);

    verify(mockDartRepo.insertDart(dartThrow)).called(1);
    verify(mockEventRepo.appendEvents(any)).called(1);
  });
}
