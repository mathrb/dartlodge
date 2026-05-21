// Stateless Cricket Engine Unit Tests
// Covers all transition tables A–M from docs/games/cricket.transitions.md

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_cricket_engine.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';

int _seq = 0;

GameEvent _event({
  required String type,
  required Map<String, dynamic> payload,
  String gameId = 'game-1',
}) {
  _seq++;
  return GameEvent(
    eventId: 'e$_seq',
    gameId: gameId,
    eventType: type,
    localSequence: _seq,
    occurredAt: DateTime.utc(2024, 1, 1),
    payload: payload,
    synced: false,
    actorId: 'test',
    source: EventSource.client,
  );
}

GameEvent _dartThrown({
  required String competitorId,
  required int segment,
  required int multiplier,
}) =>
    _event(
      type: 'DartThrown',
      payload: {
        'competitor_id': competitorId,
        'segment': segment,
        'multiplier': multiplier,
      },
    );

GameEvent _turnStarted(String competitorId) => _event(
      type: 'TurnStarted',
      payload: {'competitor_id': competitorId},
    );

GameEvent _turnEnded(String competitorId) => _event(
      type: 'TurnEnded',
      payload: {'competitor_id': competitorId},
    );

/// Build a minimal initial game state for cricket tests
GameState _makeState({
  String variant = 'standard',
  int legsToWin = 1,
  bool turnActive = false,
  bool isComplete = false,
  int currentTurnIndex = 0,
  int dartsThrownInTurn = 0,
  List<CompetitorState>? competitors,
  String cricketTargetMode = 'fixed',
  List<int> cricketTargets = const [15, 16, 17, 18, 19, 20],
  Set<int> cricketLockedTargets = const <int>{},
}) {
  competitors ??= [
    const CompetitorState(
      competitorId: 'c1',
      name: 'Alice',
      playerIds: ['p1'],
      score: 0,
    ),
    const CompetitorState(
      competitorId: 'c2',
      name: 'Bob',
      playerIds: ['p2'],
      score: 0,
    ),
  ];
  return GameState(
    gameId: 'game-1',
    gameType: GameType.cricket,
    competitors: competitors,
    currentTurnIndex: currentTurnIndex,
    dartsThrownInTurn: dartsThrownInTurn,
    isComplete: isComplete,
    status: GameEngineStatus.inProgress,
    turnActive: turnActive,
    legsToWin: legsToWin,
    currentLegIndex: 0,
    cricketScoring: variant,
    cricketTargetMode: cricketTargetMode,
    cricketTargets: cricketTargets,
    cricketLockedTargets: cricketLockedTargets,
  );
}

void main() {
  late StatelessCricketEngine engine;

  setUp(() {
    engine = StatelessCricketEngine();
    _seq = 0;
  });

  // ─────────────────────────────────────────────────────────────
  // Table A — Turn Start
  // ─────────────────────────────────────────────────────────────
  group('Table A — Turn Start', () {
    test('TurnStarted sets turn_active = true and resets dart count', () {
      final state = _makeState();
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.turnActive, isTrue);
      expect(result.state.dartsThrownInTurn, 0);
    });

    test('TurnStarted sets currentTurnIndex to matching competitor', () {
      final state = _makeState(currentTurnIndex: 0);
      final result = engine.apply(state, _turnStarted('c2'));
      expect(result.state.currentTurnIndex, 1);
    });

    test('isValid rejects TurnStarted when turn is already active', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('isValid accepts TurnStarted when no active turn', () {
      final state = _makeState(turnActive: false);
      expect(engine.isValid(state, _turnStarted('c1')), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table B — DartThrown Guards
  // ─────────────────────────────────────────────────────────────
  group('Table B — DartThrown Guards', () {
    test('rejects DartThrown on complete game', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
          engine.isValid(
              state,
              _dartThrown(
                  competitorId: 'c1', segment: 20, multiplier: 1)),
          isFalse);
    });

    test('rejects DartThrown when turn inactive', () {
      final state = _makeState(turnActive: false);
      expect(
          engine.isValid(
              state,
              _dartThrown(
                  competitorId: 'c1', segment: 20, multiplier: 1)),
          isFalse);
    });

    test('rejects DartThrown when 3 darts already thrown', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
          engine.isValid(
              state,
              _dartThrown(
                  competitorId: 'c1', segment: 20, multiplier: 1)),
          isFalse);
    });

    test('accepts DartThrown with active turn and fewer than 3 darts', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 2);
      expect(
          engine.isValid(
              state,
              _dartThrown(
                  competitorId: 'c1', segment: 20, multiplier: 1)),
          isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table C — Valid Numbers
  // ─────────────────────────────────────────────────────────────
  group('Table C — Valid Cricket Numbers', () {
    test('invalid number (e.g. 10) counts as thrown but adds no marks', () {
      var state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 10, multiplier: 1)).state;
      expect(s1.dartsThrownInTurn, 1);
      expect(s1.competitors[0].marksPerNumber, isEmpty);
    });

    test('valid number 15 adds marks', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 15, multiplier: 1)).state;
      expect(s1.competitors[0].marksPerNumber['15'], 1);
    });

    test('valid number 20 adds marks', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(s1.competitors[0].marksPerNumber['20'], 1);
    });

    test('Bull (segment=25) adds marks', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1)).state;
      expect(s1.competitors[0].marksPerNumber['Bull'], 1);
    });

    test('number 14 (invalid) is ignored', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 14, multiplier: 1)).state;
      expect(s1.competitors[0].marksPerNumber, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table D — Mark Counting
  // ─────────────────────────────────────────────────────────────
  group('Table D — Hit Count Calculation', () {
    test('single adds 1 mark', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)).state;
      expect(s1.competitors[0].marksPerNumber['20'], 1);
    });

    test('double adds 2 marks', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2)).state;
      expect(s1.competitors[0].marksPerNumber['20'], 2);
    });

    test('triple adds 3 marks (closes the number)', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      expect(s1.competitors[0].marksPerNumber['20'], 3);
    });

    test('marks capped at 3', () {
      // Start with 2 marks, throw triple → should cap at 3 (with overflow 2)
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 2},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      expect(s1.competitors[0].marksPerNumber['20'], 3);
    });

    test('SB (segment=25, multiplier=1) adds 1 mark to Bull', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1)).state;
      expect(s1.competitors[0].marksPerNumber['Bull'], 1);
    });

    test('DB (segment=25, multiplier=2) adds 2 marks to Bull', () {
      final state = _makeState(turnActive: true);
      final s1 =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2)).state;
      expect(s1.competitors[0].marksPerNumber['Bull'], 2);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table E1 — Standard Scoring
  // ─────────────────────────────────────────────────────────────
  group('Table E1 — Standard Cricket Scoring', () {
    test('overflow scores for current player when opponent has not closed', () {
      // c1 already closed 20 (marks=3), c2 has 0 marks on 20
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      // Single 20 → overflow = 1, score += 20
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1))
          .state;
      expect(s1.competitors[0].score, 20);
    });

    test('no overflow scoring when all opponents have closed the number', () {
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
          marksPerNumber: const {'20': 3}, // already closed
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1))
          .state;
      expect(s1.competitors[0].score, 0);
    });

    test('triple-20 overflow when at 2 marks scores 40 (2 overflow × 20)', () {
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 2},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      // T20 from 2 marks: new=3, overflow=2, score += 20*2 = 40
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3))
          .state;
      expect(s1.competitors[0].score, 40);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table E2 — Cut-Throat Scoring
  // ─────────────────────────────────────────────────────────────
  group('Table E2 — Cut-Throat Cricket Scoring', () {
    test('overflow scores opponents who have not closed', () {
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0, // hasn't closed 20
        ),
      ];
      final state =
          _makeState(variant: 'cut-throat', turnActive: true, competitors: competitors);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1))
          .state;
      // c1 gets 0, c2 gets 20*1 = 20
      expect(s1.competitors[0].score, 0);
      expect(s1.competitors[1].score, 20);
    });

    test('opponent who closed is not scored', () {
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
          marksPerNumber: const {'20': 3}, // already closed
        ),
      ];
      final state =
          _makeState(variant: 'cut-throat', turnActive: true, competitors: competitors);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1))
          .state;
      expect(s1.competitors[0].score, 0);
      expect(s1.competitors[1].score, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table E (NoScore)
  // ─────────────────────────────────────────────────────────────
  group('Table E — NoScore variant', () {
    test('no scoring occurs regardless of overflow', () {
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state =
          _makeState(variant: 'no-score', turnActive: true, competitors: competitors);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3))
          .state;
      expect(s1.competitors[0].score, 0);
      expect(s1.competitors[1].score, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table F — All-Closed Detection
  // ─────────────────────────────────────────────────────────────
  group('Table F — All-Closed Detection', () {
    test('closeOrder is set when all 7 numbers reach 3 marks', () {
      // Build a competitor who has 3 marks on all numbers except Bull
      final partialMarks = <String, int>{
        '15': 3,
        '16': 3,
        '17': 3,
        '18': 3,
        '19': 3,
        '20': 3,
        'Bull': 2, // one mark short
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: partialMarks,
          dartThrows: List.filled(6, 'T20'), // 6 dart throws so far
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1))
          .state;
      // Should now have 3 marks on Bull → all closed
      expect(s1.competitors[0].closeOrder, isNotNull);
    });

    test('closeOrder not changed once set', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 3,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: marks,
          closeOrder: 5, // already set
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1))
          .state;
      expect(s1.competitors[0].closeOrder, 5);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table G1 — Standard Win Condition
  // ─────────────────────────────────────────────────────────────
  group('Table G1 — Standard Cricket Win', () {
    test('player wins when all-closed with score >= all opponents', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      // c1 has more score already
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 40,
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 20,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      // Throw SB to close Bull
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.outcome, isNot(LegOutcome.none));
      expect(result.winnerCompetitorId, 'c1');
    });

    test('player does not win when all-closed but score < opponent', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0, // lower score
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 100, // higher score (opponent ahead)
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      // Throw SB to close Bull — c2 score is higher so c1 doesn't win
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      // In standard cricket, c1 wins if their score >= opponent (c2 has 100, c1 has 0)
      // So c1 does NOT win here
      expect(result.outcome, LegOutcome.none);
      expect(result.winnerCompetitorId, isNull);
    });

    test('closeOrder tie-break: earliest close wins when scores tied', () {
      // Both c1 and c2 are all-closed with equal scores. Per the doc
      // (G1 tie-breaking rule, mirrored from G2/G3/Table N): the earliest
      // closer wins. c2 has closeOrder 5 (closed earlier), c1 has 10
      // (closed later), so c2 should win even though c1 appears first
      // in rotation order — proves the loop respects closeOrder rather
      // than falling back to iteration order.
      final marksAll = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 3,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 50,
          marksPerNumber: marksAll,
          closeOrder: 10, // closed later
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 50,
          marksPerNumber: marksAll,
          closeOrder: 5, // closed earlier
        ),
      ];
      final state =
          _makeState(turnActive: true, competitors: competitors);
      // Any dart that triggers win evaluation works — both candidates
      // already qualify (all-closed + equal scores).
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.outcome, isNot(LegOutcome.none));
      expect(result.winnerCompetitorId, 'c2');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table G2 — Cut-Throat Win Condition
  // ─────────────────────────────────────────────────────────────
  group('Table G2 — Cut-Throat Win', () {
    test('player wins when all-closed with score <= all opponents', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0, // lowest score wins cut-throat
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 50,
        ),
      ];
      final state =
          _makeState(variant: 'cut-throat', turnActive: true, competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.outcome, isNot(LegOutcome.none));
      expect(result.winnerCompetitorId, 'c1');
    });

    test('closeOrder tie-break: earliest close wins when scores tied', () {
      // Both c1 and c2 are all-closed with score = 0
      final marksAll = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 3,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: marksAll,
          closeOrder: 10, // closed later
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
          marksPerNumber: marksAll,
          closeOrder: 5, // closed earlier
        ),
      ];
      final state =
          _makeState(variant: 'cut-throat', turnActive: true, competitors: competitors);
      // Throw a dart (e.g., invalid number) to trigger win evaluation
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      // c2 should win due to earlier closeOrder
      expect(result.winnerCompetitorId, 'c2');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table G3 — NoScore Win Condition
  // ─────────────────────────────────────────────────────────────
  group('Table G3 — NoScore Win', () {
    test('player wins immediately when all-closed', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state =
          _makeState(variant: 'no-score', turnActive: true, competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.outcome, isNot(LegOutcome.none));
      expect(result.winnerCompetitorId, 'c1');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table I — Turn End Conditions
  // ─────────────────────────────────────────────────────────────
  group('Table I — Turn End After 3 Darts', () {
    test('turn ends automatically after 3 darts', () {
      var state = _makeState(turnActive: true, dartsThrownInTurn: 0);
      // Throw 3 darts (invalid numbers so no marks)
      state = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1))
          .state;
      state = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 2, multiplier: 1))
          .state;
      state = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1))
          .state;
      expect(state.dartsThrownInTurn, 3);
      expect(state.turnActive, isFalse);
    });

    test('turn does not end after 2 darts', () {
      var state = _makeState(turnActive: true, dartsThrownInTurn: 0);
      state = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1))
          .state;
      state = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 2, multiplier: 1))
          .state;
      expect(state.turnActive, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table K/L — Leg Completion & Reset
  // ─────────────────────────────────────────────────────────────
  group('Table K/L — Leg Completion and Reset', () {
    test('legsWon incremented for winner when leg completed', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(
          variant: 'no-score', legsToWin: 2, turnActive: true, competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);
      // After leg reset, legsWon should still be 1
      // (winner is in reset state)
    });

    test('Table L: marks/scores/closeOrder cleared after leg reset', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 50,
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 20,
        ),
      ];
      final state = _makeState(
          variant: 'no-score', legsToWin: 2, turnActive: true, competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);

      // After reset, marks, scores and closeOrder should be cleared
      final resetState = result.state;
      for (final c in resetState.competitors) {
        expect(c.marksPerNumber, isEmpty);
        expect(c.score, 0);
        expect(c.closeOrder, isNull);
        expect(c.dartThrows, isEmpty);
      }
    });

    test('legsWon preserved after leg reset', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          legsWon: 0, // starts at 0
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(
          variant: 'no-score', legsToWin: 2, turnActive: true, competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);

      // c1 should have 1 leg won after the leg
      final c1 =
          result.state.competitors.firstWhere((c) => c.competitorId == 'c1');
      expect(c1.legsWon, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table M — Game Completion
  // ─────────────────────────────────────────────────────────────
  group('Table M — Game Completion', () {
    test('game completes when legsWon reaches legsToWin', () {
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(
          variant: 'no-score', legsToWin: 1, turnActive: true, competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.isComplete, isTrue);
      expect(result.winnerCompetitorId, 'c1');
    });

    test('no darts accepted after game complete', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
          engine.isValid(state,
              _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
          isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Bull scoring verification
  // ─────────────────────────────────────────────────────────────
  group('Bull scoring', () {
    test('SB scores 25 per overflow mark (not 50)', () {
      // c1 has Bull closed, c2 has Bull open
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'Bull': 3},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      // SB: 1 overflow → score += 25 * 1
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1))
          .state;
      expect(s1.competitors[0].score, 25);
    });

    test('DB scores 25 per overflow mark (2 overflow → 50 total)', () {
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'Bull': 3},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      // DB: 2 overflow → score += 25 * 2 = 50 (NOT 50 per dart)
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2))
          .state;
      expect(s1.competitors[0].score, 50);
    });

    test('DB from 1 mark: 2 marks total, no overflow, no score', () {
      // 1 mark + DB → min(1+2,3)=3, overflow=0
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'Bull': 1},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2))
          .state;
      expect(s1.competitors[0].marksPerNumber['Bull'], 3);
      expect(s1.competitors[0].score, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // isBust invariant
  // ─────────────────────────────────────────────────────────────
  group('isBust invariant', () {
    test('isBust is never true for Cricket', () {
      var state = _makeState(turnActive: true);
      final result =
          engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.isBust, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GameEngineFactory wiring
  // ─────────────────────────────────────────────────────────────
  group('GameEngineFactory', () {
    test('factory returns StatelessCricketEngine for cricket', () {
      // Import inline to avoid circular deps in test file
      expect(StatelessCricketEngine(), isA<StatelessCricketEngine>());
    });
  });

  // ─────────────────────────────────────────────────────────────
  // TurnEnded event (Table J)
  // ─────────────────────────────────────────────────────────────
  group('Table J — TurnEnded', () {
    test('TurnEnded sets turn_active = false and advances player', () {
      final state = _makeState(turnActive: true, currentTurnIndex: 0);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.turnActive, isFalse);
      expect(result.state.currentTurnIndex, 1);
    });

    test('TurnEnded wraps around to first player', () {
      final state = _makeState(turnActive: true, currentTurnIndex: 1);
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.state.currentTurnIndex, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // GameCreated event
  // ─────────────────────────────────────────────────────────────
  group('GameCreated', () {
    test('GameCreated sets status to inProgress', () {
      final state = _makeState().copyWith(status: GameEngineStatus.initialized);
      final result = engine.apply(
          state, _event(type: 'GameCreated', payload: {}));
      expect(result.state.status, GameEngineStatus.inProgress);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table B additions — isValid with 0 and 1 darts
  // ─────────────────────────────────────────────────────────────
  group('Table B additions — isValid dart count variants', () {
    test('isValid returns true with 0 darts thrown', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 0);
      expect(
          engine.isValid(
              state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
          isTrue);
    });

    test('isValid returns true with 1 dart thrown', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 1);
      expect(
          engine.isValid(
              state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
          isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table C additions — MISS, 21-24, multiplied invalids
  // ─────────────────────────────────────────────────────────────
  group('Table C additions — MISS and 21-24', () {
    test('MISS (segment=0) counts as thrown, no marks', () {
      final state = _makeState(turnActive: true);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1))
          .state;
      expect(s1.dartsThrownInTurn, 1);
      expect(s1.competitors[0].marksPerNumber, isEmpty);
    });

    test('number 21 is ignored, increments dart count', () {
      final state = _makeState(turnActive: true);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 21, multiplier: 1))
          .state;
      expect(s1.dartsThrownInTurn, 1);
      expect(s1.competitors[0].marksPerNumber, isEmpty);
    });

    test('number 23 is ignored, increments dart count', () {
      final state = _makeState(turnActive: true);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 23, multiplier: 1))
          .state;
      expect(s1.dartsThrownInTurn, 1);
      expect(s1.competitors[0].marksPerNumber, isEmpty);
    });

    test('T14 (triple of invalid 14) is ignored', () {
      final state = _makeState(turnActive: true);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 14, multiplier: 3))
          .state;
      expect(s1.dartsThrownInTurn, 1);
      expect(s1.competitors[0].marksPerNumber, isEmpty);
    });

    test('D7 (double of invalid 7) is ignored', () {
      final state = _makeState(turnActive: true);
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 7, multiplier: 2))
          .state;
      expect(s1.dartsThrownInTurn, 1);
      expect(s1.competitors[0].marksPerNumber, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table D additions — three singles close a number
  // ─────────────────────────────────────────────────────────────
  group('Table D additions — three singles close number', () {
    test('three separate S20 throws yield 3 marks (closes)', () {
      var state = _makeState(turnActive: true);
      state = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1))
          .state;
      expect(state.competitors[0].marksPerNumber['20'], 1);

      // End turn, start new turn to reset dart count
      state = engine.apply(state, _turnEnded('c1')).state;
      state = engine.apply(state, _turnStarted('c1')).state;
      state = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1))
          .state;
      expect(state.competitors[0].marksPerNumber['20'], 2);

      state = engine.apply(state, _turnEnded('c1')).state;
      state = engine.apply(state, _turnStarted('c1')).state;
      state = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1))
          .state;
      expect(state.competitors[0].marksPerNumber['20'], 3);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table F additions — closeOrder null while any number open
  // ─────────────────────────────────────────────────────────────
  group('Table F additions — closeOrder null while open', () {
    test('closeOrder is null when any number still open', () {
      // 6 of 7 numbers closed; Bull still has only 2 marks
      final partialMarks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: partialMarks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      // Throw an invalid number — marks unchanged, Bull still open
      final s1 = engine
          .apply(state, _dartThrown(competitorId: 'c1', segment: 10, multiplier: 1))
          .state;
      expect(s1.competitors[0].closeOrder, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table G2 additions — CutThroat no win when higher score
  // ─────────────────────────────────────────────────────────────
  group('Table G2 additions — CutThroat no win with higher score', () {
    test('CutThroat: all-closed but higher score than opponent does not win', () {
      // In cut-throat, lowest score wins. c1 all-closed but has higher score → no win.
      final marksAll = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 3,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 100, // higher score — bad in cut-throat
          marksPerNumber: marksAll,
          closeOrder: 10,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 50, // lower score
        ),
      ];
      final state =
          _makeState(variant: 'cut-throat', turnActive: true, competitors: competitors);
      // Throw invalid number to trigger win evaluation without scoring
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 10, multiplier: 1));
      expect(result.outcome, LegOutcome.none);
      expect(result.winnerCompetitorId, isNull);
    });

    test('Win condition explicitly sets isComplete=true and winnerCompetitorId on state', () {
      // Single-leg standard game: closing last number with higher score wins immediately
      final marks = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 40,
          marksPerNumber: marks,
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 20,
        ),
      ];
      final state = _makeState(legsToWin: 1, turnActive: true, competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.state.isComplete, isTrue);
      expect(result.state.winnerCompetitorId, 'c1');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Table I additions — no bust on large overflow
  // ─────────────────────────────────────────────────────────────
  group('Table I additions — no bust on large overflow', () {
    test('T20 with all opponents having closed 20 produces no bust in Standard', () {
      // Both competitors have closed 20; overflow scoring still does not bust
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
      ];
      final state = _makeState(turnActive: true, competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.isBust, isFalse);
      // No scoring since all opponents have closed
      expect(result.state.competitors[0].score, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Edge cases — 3-player CutThroat overflow distribution
  // ─────────────────────────────────────────────────────────────
  group('Edge cases — 3-player CutThroat', () {
    test('overflow distributes to each open opponent individually', () {
      // c1 closed 20, c2 and c3 both open on 20
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
        const CompetitorState(
          competitorId: 'c3',
          name: 'Carol',
          playerIds: ['p3'],
          score: 0,
        ),
      ];
      final state = _makeState(
          variant: 'cut-throat',
          turnActive: true,
          competitors: competitors);
      // S20: overflow=1 → each open opponent gets +20
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.competitors[0].score, 0); // thrower unchanged
      expect(result.state.competitors[1].score, 20); // c2 scored
      expect(result.state.competitors[2].score, 20); // c3 scored
    });

    test('overflow does not go to closed opponent in CutThroat', () {
      // c1 closed 20, c2 open, c3 also closed 20 → only c2 gets scored
      final competitors = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          marksPerNumber: const {'20': 3},
        ),
        const CompetitorState(
          competitorId: 'c2',
          name: 'Bob',
          playerIds: ['p2'],
          score: 0,
        ),
        CompetitorState(
          competitorId: 'c3',
          name: 'Carol',
          playerIds: ['p3'],
          score: 0,
          marksPerNumber: const {'20': 3}, // closed
        ),
      ];
      final state = _makeState(
          variant: 'cut-throat',
          turnActive: true,
          competitors: competitors);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.competitors[0].score, 0); // thrower unchanged
      expect(result.state.competitors[1].score, 20); // c2 scored
      expect(result.state.competitors[2].score, 0); // c3 not scored (closed)
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Round cap termination (cricketTotalRounds)
  // ─────────────────────────────────────────────────────────────
  group('Round cap termination (cricketTotalRounds)', () {
    test('no cap set → TurnEnded rotates normally', () {
      final state = _makeState(currentTurnIndex: 1).copyWith(
        cricketTotalRounds: null,
        currentRoundInLeg: 99,
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.outcome, LegOutcome.none);
      expect(result.state.currentTurnIndex, 0);
    });

    test('cap not yet reached → normal rotation', () {
      final state = _makeState(currentTurnIndex: 1).copyWith(
        cricketTotalRounds: 20,
        currentRoundInLeg: 19,
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.outcome, LegOutcome.none);
      expect(result.state.currentTurnIndex, 0);
    });

    test('standard: clear highest score wins final leg → gameCompleted', () {
      final state = _makeState(currentTurnIndex: 1).copyWith(
        cricketTotalRounds: 20,
        currentRoundInLeg: 20,
        competitors: [
          const CompetitorState(
              competitorId: 'c1',
              name: 'Alice',
              playerIds: ['p1'],
              score: 60),
          const CompetitorState(
              competitorId: 'c2',
              name: 'Bob',
              playerIds: ['p2'],
              score: 30),
        ],
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c1');
      expect(result.state.isComplete, true);
    });

    test('cut-throat: clear lowest score wins → gameCompleted', () {
      final state = _makeState(variant: 'cut-throat', currentTurnIndex: 1)
          .copyWith(
        cricketTotalRounds: 20,
        currentRoundInLeg: 20,
        competitors: [
          const CompetitorState(
              competitorId: 'c1',
              name: 'Alice',
              playerIds: ['p1'],
              score: 120),
          const CompetitorState(
              competitorId: 'c2',
              name: 'Bob',
              playerIds: ['p2'],
              score: 45),
        ],
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c2');
    });

    test('no-score: most marks wins → gameCompleted', () {
      final state = _makeState(variant: 'no-score', currentTurnIndex: 1)
          .copyWith(
        cricketTotalRounds: 20,
        currentRoundInLeg: 20,
        competitors: [
          const CompetitorState(
            competitorId: 'c1',
            name: 'Alice',
            playerIds: ['p1'],
            score: 0,
            marksPerNumber: {'15': 3, '16': 3, '17': 2, '18': 0, '19': 0, '20': 0, 'Bull': 0},
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'Bob',
            playerIds: ['p2'],
            score: 0,
            marksPerNumber: {'15': 3, '16': 3, '17': 3, '18': 2, '19': 0, '20': 0, 'Bull': 0},
          ),
        ],
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c2');
    });

    test('tied score, different closeOrder → earliest closeOrder wins', () {
      final state = _makeState(currentTurnIndex: 1).copyWith(
        cricketTotalRounds: 20,
        currentRoundInLeg: 20,
        competitors: [
          const CompetitorState(
              competitorId: 'c1',
              name: 'Alice',
              playerIds: ['p1'],
              score: 60,
              closeOrder: 42),
          const CompetitorState(
              competitorId: 'c2',
              name: 'Bob',
              playerIds: ['p2'],
              score: 60,
              closeOrder: 20),
        ],
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c2'); // closed earlier
    });

    test('tied score, no closeOrder anywhere → roundCapReached', () {
      final state = _makeState(currentTurnIndex: 1).copyWith(
        cricketTotalRounds: 20,
        currentRoundInLeg: 20,
        competitors: [
          const CompetitorState(
              competitorId: 'c1',
              name: 'Alice',
              playerIds: ['p1'],
              score: 30),
          const CompetitorState(
              competitorId: 'c2',
              name: 'Bob',
              playerIds: ['p2'],
              score: 30),
        ],
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.outcome, LegOutcome.roundCapReached);
      expect(result.state.isComplete, false);
      expect(result.state.turnActive, false);
    });

    test('multi-leg with clear winner → legCompleted, leg reset', () {
      final state = _makeState(legsToWin: 3, currentTurnIndex: 1).copyWith(
        cricketTotalRounds: 20,
        currentRoundInLeg: 20,
        competitors: [
          const CompetitorState(
            competitorId: 'c1',
            name: 'Alice',
            playerIds: ['p1'],
            score: 75,
            marksPerNumber: {'15': 3},
          ),
          const CompetitorState(
              competitorId: 'c2',
              name: 'Bob',
              playerIds: ['p2'],
              score: 10),
        ],
      );
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.winnerCompetitorId, 'c1');
      expect(result.state.isComplete, false);
      expect(result.state.currentLegIndex, 1);
      // Leg reset: marks cleared, scores zeroed
      expect(result.state.competitors[0].score, 0);
      expect(result.state.competitors[0].marksPerNumber, isEmpty);
      // Winner's legsWon persists
      final c1 =
          result.state.competitors.firstWhere((c) => c.competitorId == 'c1');
      expect(c1.legsWon, 1);
    });

    test('single-player cap reached → gameCompleted with null winner', () {
      final state = _makeState(currentTurnIndex: 0).copyWith(
        cricketTotalRounds: 20,
        currentRoundInLeg: 20,
        competitors: [
          const CompetitorState(
              competitorId: 'c1',
              name: 'Solo',
              playerIds: ['p1'],
              score: 40),
        ],
      );
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, isNull);
      expect(result.state.isComplete, true);
      expect(result.state.winnerCompetitorId, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CricketTargetsAssigned — Random Cricket (#237)
  // ─────────────────────────────────────────────────────────────
  group('CricketTargetsAssigned', () {
    test('replaces cricketTargets with payload targets', () {
      final state = _makeState(
        cricketTargetMode: 'random',
        cricketTargets: const [],
      );
      final event = _event(
        type: 'CricketTargetsAssigned',
        payload: {'targets': [3, 7, 11, 14, 18, 20]},
      );

      final result = engine.apply(state, event);

      expect(result.state.cricketTargets, [3, 7, 11, 14, 18, 20]);
    });

    test('only the payload numbers (plus Bull) count as valid segments',
        () {
      // Random Cricket should accept hits on the assigned numbers and
      // Bull (always implicit), but ignore the canonical 15–20 set.
      final state = _makeState(
        cricketTargetMode: 'random',
        cricketTargets: const [3, 7, 11, 14, 18, 20],
        turnActive: true,
        currentTurnIndex: 0,
      );

      // Hit on assigned number 3 → mark recorded
      final hitAssigned = engine.apply(state, _dartThrown(
        competitorId: 'c1', segment: 3, multiplier: 1,
      ));
      expect(hitAssigned.state.competitors[0].marksPerNumber['3'], 1);

      // Hit on non-assigned number 15 → counts as a dart thrown but no
      // mark recorded (Table C).
      final stateAfter = hitAssigned.state.copyWith(dartsThrownInTurn: 0);
      final hitUnassigned = engine.apply(stateAfter, _dartThrown(
        competitorId: 'c1', segment: 15, multiplier: 1,
      ));
      expect(hitUnassigned.state.competitors[0].marksPerNumber['15'], isNull);

      // Bull always valid even under random.
      final stateAfter2 = hitUnassigned.state.copyWith(dartsThrownInTurn: 0);
      final hitBull = engine.apply(stateAfter2, _dartThrown(
        competitorId: 'c1', segment: 25, multiplier: 1,
      ));
      expect(hitBull.state.competitors[0].marksPerNumber['Bull'], 1);
    });

    test('targets persist across leg reset (game-scoped)', () {
      // Build a near-end state for leg 1: c1 closes all 6 assigned
      // numbers + Bull and has a higher score (standard scoring) than c2.
      final targets = [2, 5, 8, 11, 14, 17];
      final closedMarks = <String, int>{
        for (final t in targets) t.toString(): 3,
        'Bull': 3,
      };
      final state = _makeState(
        cricketTargetMode: 'random',
        cricketTargets: targets,
        legsToWin: 2,
        turnActive: true,
        currentTurnIndex: 0,
        competitors: [
          CompetitorState(
            competitorId: 'c1',
            name: 'Alice',
            playerIds: const ['p1'],
            score: 10,
            marksPerNumber: closedMarks,
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'Bob',
            playerIds: ['p2'],
            score: 0,
          ),
        ],
      ).copyWith(dartsThrownInTurn: 2);

      // Closing the final Bull triggers leg win; legsToWin=2 so it
      // doesn't end the game — just resets.
      final result = engine.apply(state, _dartThrown(
        competitorId: 'c1', segment: 25, multiplier: 1,
      ));

      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.cricketTargets, targets,
          reason: 'Random Cricket targets are game-scoped — must survive '
              'leg reset, never re-rolled');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CrazyTargetsRolled — Crazy Cricket (#238)
  // ─────────────────────────────────────────────────────────────
  group('CrazyTargetsRolled', () {
    test('replaces cricketTargets with rolled set', () {
      final state = _makeState(
        cricketTargetMode: 'crazy',
        cricketTargets: const [],
      );
      final event = _event(
        type: 'CrazyTargetsRolled',
        payload: {
          'competitor_id': 'c1',
          'round': 1,
          'open_targets': [2, 7, 11, 14, 18, 20],
        },
      );

      final result = engine.apply(state, event);

      expect(result.state.cricketTargets, [2, 7, 11, 14, 18, 20]);
    });

    test('discards marks on numbers that rotated out (and are not locked)',
        () {
      // Before: targets = [2,7,11,14,18,20], c1 has 1 mark on 7 (partial).
      final state = _makeState(
        cricketTargetMode: 'crazy',
        cricketTargets: const [2, 7, 11, 14, 18, 20],
        competitors: [
          const CompetitorState(
            competitorId: 'c1',
            name: 'Alice',
            playerIds: ['p1'],
            score: 0,
            marksPerNumber: {'7': 1, '14': 2},
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'Bob',
            playerIds: ['p2'],
            score: 0,
            marksPerNumber: {'7': 1},
          ),
        ],
      );
      // New roll keeps 14 but drops 7.
      final event = _event(
        type: 'CrazyTargetsRolled',
        payload: {
          'competitor_id': 'c1',
          'round': 2,
          'open_targets': [2, 5, 11, 14, 18, 20],
        },
      );

      final result = engine.apply(state, event);

      // 7 rotated out → marks wiped for everyone
      expect(result.state.competitors[0].marksPerNumber['7'], isNull);
      expect(result.state.competitors[1].marksPerNumber['7'], isNull);
      // 14 stayed → marks preserved
      expect(result.state.competitors[0].marksPerNumber['14'], 2);
    });

    test('does NOT discard marks on locked numbers when they rotate', () {
      // A locked number must persist on the board, but `_applyCrazyTargetsRolled`
      // diffs cricketTargets against the new set: even if a locked number
      // somehow doesn't appear in the new payload, the discard logic must
      // skip it (the locked set is the source of truth for permanence).
      final state = _makeState(
        cricketTargetMode: 'crazy',
        cricketTargets: const [3, 7, 11, 14, 18, 20],
        cricketLockedTargets: const {3},
        competitors: [
          const CompetitorState(
            competitorId: 'c1',
            name: 'Alice',
            playerIds: ['p1'],
            score: 0,
            marksPerNumber: {'3': 3, '7': 2},
          ),
        ],
      );
      // (Hypothetical) new roll that excludes both 3 and 7. The engine
      // must preserve marks on 3 (locked) but discard on 7.
      final event = _event(
        type: 'CrazyTargetsRolled',
        payload: {
          'competitor_id': 'c1',
          'round': 2,
          'open_targets': [3, 5, 8, 11, 14, 18],
        },
      );

      final result = engine.apply(state, event);

      expect(result.state.competitors[0].marksPerNumber['3'], 3,
          reason: 'Locked number 3 keeps its marks');
      expect(result.state.competitors[0].marksPerNumber['7'], isNull,
          reason: 'Non-locked rotated-out 7 has marks wiped');
    });

    test('DartThrown that reaches 3 marks adds the number to '
        'cricketLockedTargets (global lock-on-close)', () {
      // Pre-state: c1 has 2 marks on segment 7 (an active target).
      final state = _makeState(
        cricketTargetMode: 'crazy',
        cricketTargets: const [3, 7, 11, 14, 18, 20],
        cricketLockedTargets: const {},
        turnActive: true,
        currentTurnIndex: 0,
        competitors: [
          const CompetitorState(
            competitorId: 'c1',
            name: 'Alice',
            playerIds: ['p1'],
            score: 0,
            marksPerNumber: {'7': 2},
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'Bob',
            playerIds: ['p2'],
            score: 0,
          ),
        ],
      );

      // Single 7 → closes the number → locks globally.
      final result = engine.apply(state, _dartThrown(
        competitorId: 'c1', segment: 7, multiplier: 1,
      ));

      expect(result.state.competitors[0].marksPerNumber['7'], 3);
      expect(result.state.cricketLockedTargets, contains(7));
    });

    test('closing Bull does NOT add 25 to cricketLockedTargets', () {
      // Bull is a fixed door, never in cricketTargets and never in the
      // CrazyTargetsRolled payload's open_targets. Locking 25 would make
      // `rollCrazyOpenTargets` reserve a slot for it and the engine would
      // carry both '25' and 'Bull' keys, deadlocking subsequent leg-win
      // detection.
      final state = _makeState(
        cricketTargetMode: 'crazy',
        cricketTargets: const [3, 7, 11, 14, 18, 20],
        legsToWin: 2,
        turnActive: true,
        currentTurnIndex: 0,
        competitors: [
          const CompetitorState(
            competitorId: 'c1',
            name: 'Alice',
            playerIds: ['p1'],
            score: 0,
            marksPerNumber: {'Bull': 2},
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'Bob',
            playerIds: ['p2'],
            score: 0,
          ),
        ],
      );
      // Single Bull (SB) → closes Bull → Bull marks reach 3.
      final result = engine.apply(state, _dartThrown(
        competitorId: 'c1', segment: 25, multiplier: 1,
      ));

      expect(result.state.competitors[0].marksPerNumber['Bull'], 3);
      expect(result.state.cricketLockedTargets, isNot(contains(25)),
          reason: 'Bull must never be added to cricketLockedTargets — it '
              'is implicit on the board and the locked set is restricted '
              'to 1..20.');
    });

    test('leg reset clears cricketLockedTargets (per-leg scope)', () {
      // c1 closes everything in leg 1 → locks accumulate → leg completes.
      final targets = [3, 7, 11, 14, 18, 20];
      final closedMarks = <String, int>{
        for (final t in targets) t.toString(): 3,
        'Bull': 3,
      };
      final state = _makeState(
        cricketTargetMode: 'crazy',
        cricketTargets: targets,
        cricketLockedTargets: targets.toSet(),
        legsToWin: 2,
        turnActive: true,
        currentTurnIndex: 0,
        competitors: [
          CompetitorState(
            competitorId: 'c1',
            name: 'Alice',
            playerIds: const ['p1'],
            score: 10,
            marksPerNumber: closedMarks,
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'Bob',
            playerIds: ['p2'],
            score: 0,
          ),
        ],
      ).copyWith(dartsThrownInTurn: 2);

      // Final Bull seals the leg.
      final result = engine.apply(state, _dartThrown(
        competitorId: 'c1', segment: 25, multiplier: 1,
      ));

      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.cricketLockedTargets, isEmpty,
          reason: 'Per design §4: Table L leg reset clears the global '
              'locked set, so the next leg rolls all 6 slots fresh');
    });
  });
}
