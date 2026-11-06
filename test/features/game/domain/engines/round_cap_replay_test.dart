// Round-cap legs must survive every replay path (#111).
//
// A leg decided by the per-leg round cap is resolved on `TurnEnded`
// (`_resolveRoundCap`), not on a dart. A tied cap leaves the leg open and the
// `LegCompleted` written by `selectCapWinner` is the only record of the
// user's pick. Both cold load (`replayEvents`) and undo
// (`UndoLastDartUseCase`) must rebuild the same state the live game had.

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/event_replay.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_cricket_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/usecases/undo_last_dart_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../usecases/undo_last_dart_use_case_test.mocks.dart';

void main() {
  late int seq;
  late List<GameEvent> events;

  setUp(() {
    seq = 0;
    events = [];
  });

  void add(String type, [Map<String, dynamic> payload = const {}]) {
    seq++;
    events.add(
      GameEvent(
        eventId: 'e$seq',
        gameId: 'g1',
        eventType: type,
        localSequence: seq,
        occurredAt: DateTime(2024),
        payload: payload,
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      ),
    );
  }

  void turn(String competitorId, List<(int, int)> darts) {
    add('TurnStarted', {'competitor_id': competitorId});
    for (final (segment, multiplier) in darts) {
      add('DartThrown', {
        'competitor_id': competitorId,
        'segment': segment,
        'multiplier': multiplier,
        'score': segment * multiplier,
        'input_method': 'manual',
      });
    }
    add('TurnEnded', {'competitor_id': competitorId, 'reason': 'normal'});
  }

  /// The state the live notifier holds after [log], for streams where no leg
  /// ends on a dart. The notifier applies each TurnEnded (as a transient
  /// copy) and the LegCompleted from `selectCapWinner` after a tied cap. When
  /// the TurnEnded itself resolves the cap, it persists a LegCompleted but
  /// does not apply it again.
  GameState live(GameState initial, GameEngine engine, List<GameEvent> log) {
    var gs = initial;
    var skipNextLegCompleted = false;
    for (final e in log) {
      if (e.eventType == 'LegCompleted' && skipNextLegCompleted) {
        skipNextLegCompleted = false;
        continue;
      }
      final result = engine.apply(gs, e);
      gs = result.state;
      if (e.eventType == 'TurnEnded') {
        skipNextLegCompleted = result.outcome == LegOutcome.legCompleted;
      }
    }
    return gs;
  }

  Future<GameState> undo(GameState current, GameEngine engine) {
    final eventRepo = MockGameEventRepository();
    final dartRepo = MockDartThrowRepository();
    when(
      eventRepo.getEventsForGame('g1'),
    ).thenAnswer((_) async => List.of(events));
    when(eventRepo.getLatestSequence('g1')).thenAnswer((_) async => seq);
    when(eventRepo.appendEvent(any)).thenAnswer((_) async {});
    when(dartRepo.deleteDart(any)).thenAnswer((_) async {});
    return UndoLastDartUseCase(eventRepo, dartRepo, engine).execute(current);
  }

  group('X01 round-cap leg (1 round, first to 2)', () {
    final engine = StatelessX01Engine();
    const initial = GameState(
      gameId: 'g1',
      gameType: GameType.x01,
      competitors: [
        CompetitorState(
          competitorId: 'c1',
          name: 'P1',
          playerIds: ['p1'],
          score: 501,
          startingScore: 501,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'P2',
          playerIds: ['p2'],
          score: 501,
          startingScore: 501,
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      legsToWin: 2,
      x01TotalRounds: 1,
      inStrategy: 'straight',
      outStrategy: 'double',
      startingScore: 501,
    );

    test('undo in the next leg keeps an auto-resolved cap leg', () async {
      add('GameCreated');
      turn('c1', [(20, 1), (20, 1), (20, 1)]); // 441
      turn('c2', [(1, 1), (1, 1), (1, 1)]); // 498 -> c1 wins on the cap
      add('LegCompleted', {'winner_competitor_id': 'c1'});
      add('TurnStarted', {'competitor_id': 'c2'}); // leg 2: c2 starts
      add('DartThrown', {
        'competitor_id': 'c2',
        'segment': 20,
        'multiplier': 1,
        'score': 20,
        'input_method': 'manual',
      });

      final before = live(initial, engine, events);
      expect(before.currentLegIndex, 1);
      expect(before.competitors[1].score, 481);

      final after = await undo(before, engine);

      expect(after.currentLegIndex, 1);
      expect(after.competitors[0].legsWon, 1);
      expect(after.competitors[1].legsWon, 0);
      expect(after.competitors[0].score, 501);
      expect(after.competitors[1].score, 501);
      expect(after.currentTurnIndex, 1);
      expect(after.turnActive, isTrue);
    });

    void tiedCapPickedForC2() {
      add('GameCreated');
      turn('c1', [(20, 1), (20, 1), (20, 1)]); // 441
      turn('c2', [(20, 1), (20, 1), (20, 1)]); // 441 -> tie, user picks c2
      add('LegCompleted', {'winner_competitor_id': 'c2'});
      add('TurnStarted', {'competitor_id': 'c2'});
      add('DartThrown', {
        'competitor_id': 'c2',
        'segment': 20,
        'multiplier': 1,
        'score': 20,
        'input_method': 'manual',
      });
    }

    test('cold load keeps the leg picked after a tied cap', () {
      tiedCapPickedForC2();

      final cold = replayEvents(
        initial: initial,
        events: events,
        engine: engine,
      );

      expect(cold.currentLegIndex, 1);
      expect(cold.competitors[1].legsWon, 1);
      expect(cold.competitors[0].legsWon, 0);
      expect(cold.competitors[1].score, 481);
      expect(cold.competitors[0].score, 501);
      expect(cold, live(initial, engine, events));
    });

    test(
      'undo in the next leg keeps the leg picked after a tied cap',
      () async {
        tiedCapPickedForC2();
        final before = live(initial, engine, events);

        final after = await undo(before, engine);

        expect(after.currentLegIndex, 1);
        expect(after.competitors[1].legsWon, 1);
        expect(after.competitors[1].score, 501);
        expect(after.currentTurnIndex, 1);
      },
    );

    test('cold load completes the game once when a tied cap decides it', () {
      add('GameCreated');
      turn('c1', [(20, 1), (20, 1), (20, 1)]);
      turn('c2', [(1, 1), (1, 1), (1, 1)]); // c1 wins leg 1 on the cap
      add('LegCompleted', {'winner_competitor_id': 'c1'});
      turn('c2', [(20, 1), (20, 1), (20, 1)]); // leg 2: c2 starts
      turn('c1', [(20, 1), (20, 1), (20, 1)]); // tie, user picks c1
      add('LegCompleted', {'winner_competitor_id': 'c1'});
      add('GameCompleted', {'winner_competitor_id': 'c1'});

      final cold = replayEvents(
        initial: initial,
        events: events,
        engine: engine,
      );

      expect(cold.isComplete, isTrue);
      expect(cold.winnerCompetitorId, 'c1');
      expect(cold.competitors[0].legsWon, 2);
      expect(cold.competitors[1].legsWon, 0);
    });

    test('a tied cap still awaiting the pick replays as pending', () {
      add('GameCreated');
      turn('c1', [(20, 1), (20, 1), (20, 1)]);
      turn('c2', [(20, 1), (20, 1), (20, 1)]);

      final cold = replayEvents(
        initial: initial,
        events: events,
        engine: engine,
      );

      expect(cold.currentLegIndex, 0);
      expect(cold.competitors.every((c) => c.legsWon == 0), isTrue);
      expect(cold.turnActive, isFalse);
    });
  });

  group('Cricket round-cap leg (1 round, first to 2)', () {
    final engine = StatelessCricketEngine();
    const initial = GameState(
      gameId: 'g1',
      gameType: GameType.cricket,
      competitors: [
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
      dartsThrownInTurn: 0,
      isComplete: false,
      legsToWin: 2,
      cricketTotalRounds: 1,
      cricketScoring: 'standard',
      cricketTargetMode: 'fixed',
      cricketTargets: [15, 16, 17, 18, 19, 20],
      startingScore: 0,
    );

    test('undo in the next leg keeps an auto-resolved cap leg', () async {
      add('GameCreated');
      turn('c1', [(20, 3), (20, 1), (20, 1)]); // closes 20, scores 40
      turn('c2', [(19, 1), (19, 1), (19, 1)]); // closes 19, scores 0
      add('LegCompleted', {'winner_competitor_id': 'c1'});
      add('TurnStarted', {'competitor_id': 'c2'});
      add('DartThrown', {
        'competitor_id': 'c2',
        'segment': 20,
        'multiplier': 1,
        'score': 20,
        'input_method': 'manual',
      });

      final before = live(initial, engine, events);
      expect(before.currentLegIndex, 1);

      final after = await undo(before, engine);

      expect(after.currentLegIndex, 1);
      expect(after.competitors[0].legsWon, 1);
      expect(after.competitors[0].score, 0);
      expect(after.competitors[1].marksPerNumber, isEmpty);
      expect(after.currentTurnIndex, 1);
    });

    test('cold load and undo keep the leg picked after a tied cap', () async {
      add('GameCreated');
      turn('c1', [(20, 1), (20, 1), (20, 1)]); // both close 20, 0 points
      turn('c2', [(20, 1), (20, 1), (20, 1)]); // tie, user picks c2
      add('LegCompleted', {'winner_competitor_id': 'c2'});
      add('TurnStarted', {'competitor_id': 'c2'});
      add('DartThrown', {
        'competitor_id': 'c2',
        'segment': 19,
        'multiplier': 1,
        'score': 19,
        'input_method': 'manual',
      });

      final cold = replayEvents(
        initial: initial,
        events: events,
        engine: engine,
      );
      expect(cold.currentLegIndex, 1);
      expect(cold.competitors[1].legsWon, 1);
      expect(cold.competitors[1].marksPerNumber, {'19': 1});
      expect(cold, live(initial, engine, events));

      final after = await undo(cold, engine);
      expect(after.currentLegIndex, 1);
      expect(after.competitors[1].legsWon, 1);
      expect(after.competitors[1].marksPerNumber, isEmpty);
    });
  });
}
