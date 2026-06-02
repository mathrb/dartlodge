// CorrectDartUseCase (issue #376) — per-dart correction.
//
// Integration-style tests against real in-memory drift + real engines + the
// real undo / ProcessDart use cases, because CorrectDartUseCase orchestrates a
// multi-step sequence of those mutators (Approach D). Verifying the rebuilt
// state — and that a cold replay of the resulting log agrees — exercises the
// actual correctness path far better than mocking the repo dance would.

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/event_replay.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_cricket_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/usecases/correct_dart_use_case.dart';
import 'package:dart_lodge/features/game/domain/usecases/process_cricket_dart_use_case.dart';
import 'package:dart_lodge/features/game/domain/usecases/process_dart_use_case.dart';
import 'package:dart_lodge/features/game/domain/usecases/undo_last_dart_use_case.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../../../../hybrid_test_runner.dart';

/// Bundles the wired use cases + the live `GameState` for a test game.
class _Harness {
  _Harness(this.game, this.competitors, this.process, this.correct, this.engine,
      this.eventRepo, this.state);

  final Game game;
  final List<Competitor> competitors;
  final ProcessDartFn process;
  final CorrectDartUseCase correct;
  final dynamic engine;
  final dynamic eventRepo;
  GameState state;

  /// Throws [segment] for the active competitor through the real ProcessDart
  /// path, returning the new state (also stored on [state]).
  Future<GameState> throwDart(String segment) async {
    final comp = state.competitors[state.currentTurnIndex];
    final dart = DartThrow(
      dartId: const Uuid().v4(),
      gameId: state.gameId,
      competitorId: comp.competitorId,
      playerId: comp.playerIds.isNotEmpty ? comp.playerIds.first : 'sentinel',
      turnNumber: state.currentLegIndex,
      dartNumber: state.dartsThrownInTurn + 1,
      segment: segment,
      score: Segment.parse(segment).scoreValue,
    );
    state = await process(state, dart);
    return state;
  }

  /// The live (non-corrected, non-superseded) DartThrown event ids for the
  /// active competitor, in throw order.
  Future<List<String>> liveDartIds() async {
    final activeCompId = state.competitors[state.currentTurnIndex].competitorId;
    final events = await eventRepo.getEventsForGame(state.gameId);
    final corrected = <String>{};
    final superseded = <String>{};
    for (final e in events) {
      if (e.eventType != 'DartCorrected') continue;
      final o = e.payload['original_event_id'];
      if (o is String) corrected.add(o);
      final s = e.payload['superseded_event_ids'];
      if (s is List) {
        for (final id in s) {
          if (id is String) superseded.add(id);
        }
      }
    }
    return [
      for (final e in events)
        if (e.eventType == 'DartThrown' &&
            e.payload['competitor_id'] == activeCompId &&
            !corrected.contains(e.eventId) &&
            !superseded.contains(e.eventId))
          e.eventId,
    ];
  }

  /// Cold-load replay of the full log — the source-of-truth state the app
  /// would reconstruct on next launch.
  Future<GameState> replayFromLog() async {
    final events = await eventRepo.getEventsForGame(game.gameId);
    return replayEvents(
      initial: GameState.initial(game, competitors),
      events: events,
      engine: engine,
    );
  }
}

Future<_Harness> _setupX01(dynamic base, {int startingScore = 501}) async {
  final playerRepo = await base.createPlayerRepository();
  final gameRepo = await base.createGameRepository();
  final dartRepo = await base.createDartThrowRepository();
  final eventRepo = await base.createGameEventRepository();

  const gameId = 'g1';
  const c1 = 'c1';
  const c2 = 'c2';
  const p1 = 'p1';
  const p2 = 'p2';

  await playerRepo.createPlayer(Player(
      playerId: p1,
      name: 'P1',
      createdAt: DateTime.now(),
      lastActive: DateTime.now()));
  await playerRepo.createPlayer(Player(
      playerId: p2,
      name: 'P2',
      createdAt: DateTime.now(),
      lastActive: DateTime.now()));

  final game = Game(
    gameId: gameId,
    gameType: GameType.x01,
    config: GameConfig.x01(
      startingScore: startingScore,
      inStrategy: 'straight',
      outStrategy: 'double',
    ),
    startTime: DateTime.now(),
    isComplete: false,
  );
  final competitors = [
    const Competitor(
      competitorId: c1,
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'P1',
      players: [CompetitorPlayer(playerId: p1, rotationPosition: 0)],
    ),
    const Competitor(
      competitorId: c2,
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'P2',
      players: [CompetitorPlayer(playerId: p2, rotationPosition: 1)],
    ),
  ];
  await gameRepo.createGame(game, competitors);

  final engine = StatelessX01Engine();
  final process = ProcessDartUseCase(gameRepo, eventRepo, dartRepo, engine);
  final undo = UndoLastDartUseCase(eventRepo, dartRepo, engine);
  final correct = CorrectDartUseCase(undo, process.execute, eventRepo);

  // Bootstrap the first turn (the app emits this in CreateGameUseCase).
  await eventRepo.appendEvent(GameEvent(
    eventId: '$gameId-ts0',
    gameId: gameId,
    eventType: 'TurnStarted',
    localSequence: 1,
    occurredAt: DateTime.now(),
    payload: {
      'competitor_id': c1,
      'player_id': p1,
      'starting_score': startingScore,
      'turn_index': 0,
      'leg_index': 0,
    },
    synced: false,
    actorId: 'system',
    source: EventSource.client,
  ));
  final state = replayEvents(
    initial: GameState.initial(game, competitors),
    events: await eventRepo.getEventsForGame(gameId),
    engine: engine,
  );

  return _Harness(
      game, competitors, process.execute, correct, engine, eventRepo, state);
}

Future<_Harness> _setupCricket(dynamic base) async {
  final playerRepo = await base.createPlayerRepository();
  final gameRepo = await base.createGameRepository();
  final dartRepo = await base.createDartThrowRepository();
  final eventRepo = await base.createGameEventRepository();

  const gameId = 'g1';
  const c1 = 'c1';
  const c2 = 'c2';
  const p1 = 'p1';
  const p2 = 'p2';

  await playerRepo.createPlayer(Player(
      playerId: p1,
      name: 'P1',
      createdAt: DateTime.now(),
      lastActive: DateTime.now()));
  await playerRepo.createPlayer(Player(
      playerId: p2,
      name: 'P2',
      createdAt: DateTime.now(),
      lastActive: DateTime.now()));

  final game = Game(
    gameId: gameId,
    gameType: GameType.cricket,
    config: const GameConfig.cricket(scoring: 'standard', targetMode: 'fixed'),
    startTime: DateTime.now(),
    isComplete: false,
  );
  final competitors = [
    const Competitor(
      competitorId: c1,
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'P1',
      players: [CompetitorPlayer(playerId: p1, rotationPosition: 0)],
    ),
    const Competitor(
      competitorId: c2,
      gameId: gameId,
      type: CompetitorType.solo,
      name: 'P2',
      players: [CompetitorPlayer(playerId: p2, rotationPosition: 1)],
    ),
  ];
  await gameRepo.createGame(game, competitors);

  final engine = StatelessCricketEngine();
  final process =
      ProcessCricketDartUseCase(gameRepo, eventRepo, dartRepo, engine);
  final undo = UndoLastDartUseCase(eventRepo, dartRepo, engine);
  final correct = CorrectDartUseCase(undo, process.execute, eventRepo);

  await eventRepo.appendEvent(GameEvent(
    eventId: '$gameId-ts0',
    gameId: gameId,
    eventType: 'TurnStarted',
    localSequence: 1,
    occurredAt: DateTime.now(),
    payload: {
      'competitor_id': c1,
      'player_id': p1,
      'turn_index': 0,
      'leg_index': 0,
    },
    synced: false,
    actorId: 'system',
    source: EventSource.client,
  ));
  final state = replayEvents(
    initial: GameState.initial(game, competitors),
    events: await eventRepo.getEventsForGame(gameId),
    engine: engine,
  );

  return _Harness(
      game, competitors, process.execute, correct, engine, eventRepo, state);
}

void main() {
  runHybridTests('CorrectDartUseCase — guards', (base) {
    test('rejects a completed game', () async {
      final h = await _setupX01(base);
      await h.throwDart('20');
      final ids = await h.liveDartIds();
      expect(
        () => h.correct.execute(
          h.state.copyWith(isComplete: true),
          originalEventId: ids.first,
          segment: 5,
          multiplier: 1,
        ),
        throwsA(isA<GameAlreadyCompleteException>()),
      );
    });

    test('rejects an unknown / non-live dart id', () async {
      final h = await _setupX01(base);
      await h.throwDart('20');
      expect(
        () => h.correct.execute(h.state,
            originalEventId: 'does-not-exist', segment: 5, multiplier: 1),
        throwsA(isA<DartNotCorrectableException>()),
      );
    });
  });

  runHybridTests('CorrectDartUseCase — X01', (base) {
    test('corrects a mid-turn dart, preserving the tail', () async {
      final h = await _setupX01(base);
      await h.throwDart('20'); // d1
      await h.throwDart('20'); // d2
      await h.throwDart('20'); // d3 → turn of 60, score 441
      final ids = await h.liveDartIds();
      expect(h.state.competitors[0].score, 441);

      // Correct the first dart 20 → 5.
      final newState = await h.correct
          .execute(h.state, originalEventId: ids.first, segment: 5, multiplier: 1);

      expect(newState.competitors[0].score, 501 - 5 - 20 - 20); // 456
      final darts = newState.competitors[0].dartThrows;
      expect(darts.sublist(darts.length - 3), ['5', '20', '20']);
    });

    test('correction can flip a turn into a bust (non-bust → bust)', () async {
      final h = await _setupX01(base, startingScore: 100);
      await h.throwDart('20'); // 80
      await h.throwDart('20'); // 60
      await h.throwDart('20'); // 40, no bust
      final ids = await h.liveDartIds();
      expect(h.state.competitors[0].score, 40);

      // Correct d1 20 → T20: 100-60-20-20 = 0 reached on a single → bust,
      // score restored to 100.
      final newState = await h.correct.execute(h.state,
          originalEventId: ids.first, segment: 20, multiplier: 3);

      expect(newState.competitors[0].score, 100);
      expect(newState.turnActive, isFalse);
    });

    test('correction can clear a bust (bust → non-bust), reopening the turn',
        () async {
      final h = await _setupX01(base, startingScore: 100);
      await h.throwDart('T20'); // 40
      await h.throwDart('T20'); // bust (40-60<0) → score restored to 100
      final ids = await h.liveDartIds();
      expect(h.state.competitors[0].score, 100);

      // Correct d1 T20 → S20: 100-20=80, then tail d2 T20 → 80-60=20, no bust.
      final newState = await h.correct.execute(h.state,
          originalEventId: ids.first, segment: 20, multiplier: 1);

      expect(newState.competitors[0].score, 20);
      expect(newState.turnActive, isTrue);
      expect(newState.dartsThrownInTurn, 2);
    });

    test('a correction that checks out completes the game', () async {
      final h = await _setupX01(base, startingScore: 40);
      await h.throwDart('10'); // 30 — wrong; was actually D20
      final ids = await h.liveDartIds();

      final newState = await h.correct.execute(h.state,
          originalEventId: ids.first, segment: 20, multiplier: 2); // D20 → 0

      expect(newState.isComplete, isTrue);
      expect(newState.winnerCompetitorId, 'c1');

      // The games table flag is set via appendEventsAndCompleteGame.
      final game = await (await base.createGameRepository()).getGame('g1');
      expect(game!.isComplete, isTrue);
    });

    test('post-correction log replays to the same state (cold-load parity)',
        () async {
      final h = await _setupX01(base);
      await h.throwDart('20');
      await h.throwDart('20');
      await h.throwDart('20');
      final ids = await h.liveDartIds();
      final corrected = await h.correct
          .execute(h.state, originalEventId: ids[1], segment: 19, multiplier: 3);

      final replayed = await h.replayFromLog();
      // Compare the durable per-competitor facts. The turn pointer
      // (dartsThrownInTurn / currentTurnIndex) legitimately differs at a turn
      // boundary: ProcessDart returns the non-rotated state (awaiting NEXT)
      // while a cold replay applies the persisted TurnEnded and rotates — a
      // pre-existing representation difference, not a correction bug.
      for (var i = 0; i < corrected.competitors.length; i++) {
        expect(replayed.competitors[i].score, corrected.competitors[i].score);
        expect(replayed.competitors[i].dartThrows,
            corrected.competitors[i].dartThrows);
      }
      expect(replayed.isComplete, corrected.isComplete);
      expect(replayed.winnerCompetitorId, corrected.winnerCompetitorId);
    });

    test('correct then undo compose coherently', () async {
      final h = await _setupX01(base);
      await h.throwDart('20');
      await h.throwDart('20');
      final ids = await h.liveDartIds();
      // Correct d1 20 → 5 (tail = [d2]).
      await h.correct
          .execute(h.state, originalEventId: ids.first, segment: 5, multiplier: 1);
      // Now undo the last live dart (the re-emitted d2).
      final undo = UndoLastDartUseCase(
        await base.createGameEventRepository(),
        await base.createDartThrowRepository(),
        StatelessX01Engine(),
      );
      final afterUndo = await undo.execute(await h.replayFromLog());
      // One dart left this turn (the corrected '5'): 501 - 5 = 496.
      expect(afterUndo.competitors[0].score, 496);
      expect(afterUndo.dartsThrownInTurn, 1);
    });
  });

  runHybridTests('CorrectDartUseCase — Cricket', (base) {
    test('overflow points are re-attributed after correcting an early dart',
        () async {
      final h = await _setupCricket(base);
      await h.throwDart('T20'); // closes 20 (3 marks), no points
      await h.throwDart('T20'); // 20 closed, opponent open → 60 points
      final ids = await h.liveDartIds();
      expect(h.state.competitors[0].score, 60);

      // Correct d1 T20 → S20 (1 mark): d1 = 1 mark, d2 T20 = +3 = 4 marks →
      // closes at 3, overflow 1 → 20 points.
      final newState = await h.correct.execute(h.state,
          originalEventId: ids.first, segment: 20, multiplier: 1);

      expect(newState.competitors[0].score, 20);
    });
  });
}
