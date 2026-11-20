// Undo across a won leg (X01 + Cricket): the leg-winning dart must be
// undoable, both straight away (from the leg-complete modal) and after the
// next leg has started. Drives the real Process*DartUseCase and
// UndoLastDartUseCase against an in-memory event log, so the events persisted
// at the leg boundary (TurnEnded, LegCompleted, the next leg's TurnStarted) are
// exactly what production writes.

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/event_replay.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_cricket_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/models/undo_availability.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:dart_lodge/features/game/domain/usecases/process_cricket_dart_use_case.dart';
import 'package:dart_lodge/features/game/domain/usecases/process_dart_use_case.dart';
import 'package:dart_lodge/features/game/domain/usecases/undo_last_dart_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'process_dart_use_case_test.mocks.dart';

void main() {
  late MockGameRepository gameRepo;
  late MockGameEventRepository eventRepo;
  late MockDartThrowRepository dartRepo;
  late List<GameEvent> log;
  var dartCounter = 0;

  setUp(() {
    gameRepo = MockGameRepository();
    eventRepo = MockGameEventRepository();
    dartRepo = MockDartThrowRepository();
    log = <GameEvent>[];
    dartCounter = 0;

    when(
      eventRepo.getLatestSequence(any),
    ).thenAnswer((_) async => log.isEmpty ? 0 : log.last.localSequence);
    when(
      eventRepo.getEventsForGame(any),
    ).thenAnswer((_) async => List<GameEvent>.of(log));
    when(eventRepo.appendEvents(any)).thenAnswer((inv) async {
      log.addAll(inv.positionalArguments.first as List<GameEvent>);
    });
    when(eventRepo.appendEvent(any)).thenAnswer((inv) async {
      log.add(inv.positionalArguments.first as GameEvent);
    });
    when(dartRepo.insertDart(any)).thenAnswer((_) async {});
    when(dartRepo.deleteDart(any)).thenAnswer((_) async {});
  });

  const competitors = [
    CompetitorState(
      competitorId: 'c1',
      name: 'P1',
      playerIds: ['p1'],
      score: 40,
      startingScore: 40,
      isIn: true,
    ),
    CompetitorState(
      competitorId: 'c2',
      name: 'P2',
      playerIds: ['p2'],
      score: 40,
      startingScore: 40,
      isIn: true,
    ),
  ];

  DartThrow dart(GameState gs, String segment) {
    final c = gs.competitors[gs.currentTurnIndex];
    return DartThrow(
      dartId: 'dart-${dartCounter++}',
      gameId: gs.gameId,
      competitorId: c.competitorId,
      playerId: c.playerIds.first,
      turnNumber: 0,
      dartNumber: gs.dartsThrownInTurn + 1,
      segment: segment,
      score: 0,
    );
  }

  /// What the notifier's NEXT does after a normal 3-dart turn end.
  GameState startNextTurn(GameState gs, GameEngine engine) {
    final next = (gs.currentTurnIndex + 1) % gs.competitors.length;
    final c = gs.competitors[next];
    final event = buildTurnStartedEvent(
      gameId: gs.gameId,
      competitorId: c.competitorId,
      playerId: c.playerIds.first,
      localSequence: log.last.localSequence + 1,
      turnIndex: next,
      legIndex: gs.currentLegIndex,
      startingScore: c.score,
    );
    log.add(event);
    return engine.apply(gs, event).state;
  }

  GameState seed(GameState gs, GameEngine engine) {
    final c = gs.competitors.first;
    final event = buildTurnStartedEvent(
      gameId: gs.gameId,
      competitorId: c.competitorId,
      playerId: c.playerIds.first,
      localSequence: 1,
      turnIndex: 0,
      legIndex: 0,
      startingScore: c.score,
    );
    log.add(event);
    return engine.apply(gs, event).state;
  }

  group('X01 — undo the leg-winning dart', () {
    final engine = StatelessX01Engine();
    late ProcessDartUseCase process;
    late UndoLastDartUseCase undo;
    late GameState initial;
    late GameState start;

    setUp(() {
      process = ProcessDartUseCase(gameRepo, eventRepo, dartRepo, engine);
      undo = UndoLastDartUseCase(eventRepo, dartRepo, engine);
      initial = const GameState(
        gameId: 'g-x01',
        gameType: GameType.x01,
        competitors: competitors,
        currentTurnIndex: 0,
        dartsThrownInTurn: 0,
        isComplete: false,
        status: GameEngineStatus.inProgress,
        turnActive: false,
        inStrategy: 'straight',
        outStrategy: 'double',
        legsToWin: 2,
        startingScore: 40,
      );
      start = seed(initial, engine);
    });

    test('undo is available at the start of the next leg', () async {
      var gs = await process.execute(start, dart(start, '20'));
      gs = await process.execute(gs, dart(gs, 'D10'));
      expect(gs.currentLegIndex, 1, reason: 'D10 on 20 wins leg 1');
      expect(gs.competitors.every((c) => c.dartThrows.isEmpty), isTrue);
      expect(gs.dartsThrownInTurn, 0);

      expect(canUndoLastDart(gs), isTrue);
    });

    test('restores the winner mid-turn, before the winning dart', () async {
      var gs = await process.execute(start, dart(start, '20'));
      gs = await process.execute(gs, dart(gs, 'D10'));

      final undone = await undo.execute(gs);

      expect(undone.currentLegIndex, 0);
      expect(undone.currentTurnIndex, 0);
      expect(undone.dartsThrownInTurn, 1);
      expect(undone.turnActive, isTrue);
      expect(undone.competitors[0].score, 20);
      expect(undone.competitors[0].legsWon, 0);
      expect(undone.competitors[1].score, 40);
      expect(undone.isComplete, isFalse);

      // The leg can then be finished again, and a reload agrees.
      final rewon = await process.execute(undone, dart(undone, 'D10'));
      expect(rewon.currentLegIndex, 1);
      expect(rewon.competitors[0].legsWon, 1);
      final reloaded = replayEvents(
        initial: initial,
        events: log,
        engine: engine,
      );
      expect(reloaded.currentLegIndex, 1);
      expect(reloaded.competitors[0].legsWon, 1);
    });

    test(
      'after a dart in the next leg, two undos reach the winning dart',
      () async {
        var gs = await process.execute(start, dart(start, '20'));
        gs = await process.execute(gs, dart(gs, 'D10'));
        gs = await process.execute(gs, dart(gs, '5'));
        expect(gs.currentLegIndex, 1);

        gs = await undo.execute(gs);
        expect(gs.currentLegIndex, 1);
        expect(canUndoLastDart(gs), isTrue);

        gs = await undo.execute(gs);
        expect(gs.currentLegIndex, 0);
        expect(gs.competitors[0].score, 20);
        expect(gs.competitors[0].legsWon, 0);
      },
    );
  });

  group('Cricket — undo the leg-winning dart', () {
    final engine = StatelessCricketEngine();
    late ProcessCricketDartUseCase process;
    late UndoLastDartUseCase undo;
    late GameState start;

    setUp(() {
      process = ProcessCricketDartUseCase(
        gameRepo,
        eventRepo,
        dartRepo,
        engine,
      );
      undo = UndoLastDartUseCase(eventRepo, dartRepo, engine);
      start = seed(
        GameState(
          gameId: 'g-cr',
          gameType: GameType.cricket,
          competitors: competitors
              .map((c) => c.copyWith(score: 0, startingScore: 0))
              .toList(),
          currentTurnIndex: 0,
          dartsThrownInTurn: 0,
          isComplete: false,
          status: GameEngineStatus.inProgress,
          turnActive: false,
          legsToWin: 2,
          cricketScoring: 'standard',
        ),
        engine,
      );
    });

    Future<GameState> throwTurn(GameState gs, List<String> segments) async {
      for (final s in segments) {
        gs = await process.execute(gs, dart(gs, s));
      }
      return gs;
    }

    /// c1 closes 15–20 over two visits (c2 misses), then hits DB + SB to
    /// close the Bull and win leg 1 on the second dart of the third visit.
    Future<GameState> winLegOne() async {
      var gs = await throwTurn(start, ['T20', 'T19', 'T18']);
      gs = startNextTurn(gs, engine);
      gs = await throwTurn(gs, ['MISS', 'MISS', 'MISS']);
      gs = startNextTurn(gs, engine);
      gs = await throwTurn(gs, ['T17', 'T16', 'T15']);
      gs = startNextTurn(gs, engine);
      gs = await throwTurn(gs, ['MISS', 'MISS', 'MISS']);
      gs = startNextTurn(gs, engine);
      gs = await throwTurn(gs, ['DB', 'SB']);
      expect(gs.currentLegIndex, 1, reason: 'SB closes the last target');
      expect(gs.competitors[0].legsWon, 1);
      return gs;
    }

    test('undo is available at the start of the next leg', () async {
      final gs = await winLegOne();
      expect(gs.competitors.every((c) => c.dartThrows.isEmpty), isTrue);
      expect(canUndoLastDart(gs), isTrue);
    });

    test('restores the winner mid-turn with the Bull one mark short', () async {
      final gs = await winLegOne();

      final undone = await undo.execute(gs);

      expect(undone.currentLegIndex, 0);
      expect(undone.currentTurnIndex, 0);
      expect(undone.dartsThrownInTurn, 1);
      expect(undone.turnActive, isTrue);
      expect(undone.competitors[0].legsWon, 0);
      expect(undone.competitors[0].dartThrows, hasLength(7));

      final rewon = await process.execute(undone, dart(undone, 'SB'));
      expect(rewon.currentLegIndex, 1);
      expect(rewon.competitors[0].legsWon, 1);
    });
  });

  group('canUndoLastDart', () {
    const base = GameState(
      gameId: 'g',
      gameType: GameType.x01,
      competitors: competitors,
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      status: GameEngineStatus.inProgress,
      turnActive: true,
    );

    test('false before the first dart of the game', () {
      expect(canUndoLastDart(base), isFalse);
    });

    test('true mid-turn', () {
      expect(canUndoLastDart(base.copyWith(dartsThrownInTurn: 1)), isTrue);
    });

    test('false once the game is complete', () {
      expect(
        canUndoLastDart(
          base.copyWith(
            dartsThrownInTurn: 1,
            currentLegIndex: 1,
            isComplete: true,
          ),
        ),
        isFalse,
      );
    });
  });
}
