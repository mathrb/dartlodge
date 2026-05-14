// ProcessPracticeDartUseCase Unit Tests
//
// Primary focus: the DartThrown event payload schema matches CLAUDE.md's
// mandated keys (competitor_id, player_id, segment, multiplier, score,
// input_method). Practice was previously missing score and player_id —
// see issue #168.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_around_the_clock_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_event_repository.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/game/domain/usecases/process_practice_dart_use_case.dart';

import 'process_practice_dart_use_case_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late ProcessPracticeDartUseCase useCase;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();
    useCase = ProcessPracticeDartUseCase(
      mockGameRepo,
      mockEventRepo,
      mockDartRepo,
      StatelessAroundTheClockEngine(),
    );

    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 5);
    when(mockDartRepo.insertDart(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvents(any)).thenAnswer((_) async {});
    when(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenAnswer((_) async {});
  });

  // ATC standard variant, single competitor, target = 1.
  GameState atcInitialState() => const GameState(
        gameId: 'g1',
        gameType: GameType.aroundTheClock,
        competitors: [
          CompetitorState(
            competitorId: 'c1',
            name: 'P1',
            playerIds: ['p1'],
            score: 0,
            startingScore: 0,
            isIn: true,
            currentTarget: 1,
          ),
        ],
        currentTurnIndex: 0,
        dartsThrownInTurn: 0,
        isComplete: false,
        turnActive: true,
        startingScore: 0,
        aroundTheClockVariant: 'standard',
      );

  group('DartThrown payload schema (regression for #168)', () {
    test('emitted DartThrown carries all six mandated keys', () async {
      final captured = <GameEvent>[];
      when(mockEventRepo.appendEvents(any)).thenAnswer((inv) async {
        captured.addAll(inv.positionalArguments[0] as List<GameEvent>);
      });

      final dart = DartThrow(
        dartId: 'd1',
        gameId: 'g1',
        competitorId: 'c1',
        playerId: 'p1',
        turnNumber: 1,
        dartNumber: 1,
        segment: '1',
        score: 1,
      );

      await useCase.execute(atcInitialState(), dart);

      final dartThrown =
          captured.firstWhere((e) => e.eventType == 'DartThrown');
      final keys = dartThrown.payload.keys.toSet();

      // Exactly the six keys mandated by CLAUDE.md — no more, no less.
      expect(
        keys,
        equals(<String>{
          'competitor_id',
          'player_id',
          'segment',
          'multiplier',
          'score',
          'input_method',
        }),
      );
      expect(dartThrown.payload['competitor_id'], 'c1');
      expect(dartThrown.payload['player_id'], 'p1');
      expect(dartThrown.payload['segment'], 1);
      expect(dartThrown.payload['multiplier'], 1);
      expect(dartThrown.payload['score'], 1);
      expect(dartThrown.payload['input_method'], 'manual');
    });

    test('triple hit reports score = base × multiplier', () async {
      final captured = <GameEvent>[];
      when(mockEventRepo.appendEvents(any)).thenAnswer((inv) async {
        captured.addAll(inv.positionalArguments[0] as List<GameEvent>);
      });

      final dart = DartThrow(
        dartId: 'd1',
        gameId: 'g1',
        competitorId: 'c1',
        playerId: 'p1',
        turnNumber: 1,
        dartNumber: 1,
        segment: 'T1',
        score: 3,
      );

      await useCase.execute(atcInitialState(), dart);

      final dartThrown =
          captured.firstWhere((e) => e.eventType == 'DartThrown');
      expect(dartThrown.payload['segment'], 1);
      expect(dartThrown.payload['multiplier'], 3);
      expect(dartThrown.payload['score'], 3);
    });
  });
}
