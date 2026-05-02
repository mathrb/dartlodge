// Stateless Around the Clock Engine Unit Tests
// Covers all transition tables from docs/games/around-the-clock.md

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_around_the_clock_engine.dart';
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

/// Build a minimal game state for around-the-clock tests.
/// Default competitors: c1 (index 0), c2 (index 1).
/// currentTarget is set per variant: 'reverse' → 20, else → 1.
GameState _makeState({
  String variant = 'standard',
  int legsToWin = 1,
  int currentTurnIndex = 0,
  int dartsThrownInTurn = 0,
  bool turnActive = false,
  bool isComplete = false,
  String? winnerCompetitorId,
  int currentLegIndex = 0,
  List<CompetitorState>? competitors,
}) {
  final defaultTarget = variant == 'reverse' ? 20 : 1;
  final defaultCompetitors = [
    CompetitorState(
      competitorId: 'c1',
      name: 'Player 1',
      playerIds: ['p1'],
      score: 0,
      isComplete: false,
      dartThrows: const [],
      legsWon: 0,
      currentTarget: defaultTarget,
    ),
    CompetitorState(
      competitorId: 'c2',
      name: 'Player 2',
      playerIds: ['p2'],
      score: 0,
      isComplete: false,
      dartThrows: const [],
      legsWon: 0,
      currentTarget: defaultTarget,
    ),
  ];

  return GameState(
    gameId: 'game-1',
    gameType: GameType.aroundTheClock,
    competitors: competitors ?? defaultCompetitors,
    currentTurnIndex: currentTurnIndex,
    dartsThrownInTurn: dartsThrownInTurn,
    isComplete: isComplete,
    winnerCompetitorId: winnerCompetitorId,
    status: isComplete ? GameEngineStatus.completed : GameEngineStatus.inProgress,
    turnActive: turnActive,
    legsToWin: legsToWin,
    currentLegIndex: currentLegIndex,
    aroundTheClockVariant: variant,
  );
}

void main() {
  late StatelessAroundTheClockEngine engine;

  setUp(() {
    _seq = 0;
    engine = StatelessAroundTheClockEngine();
  });

  // -------------------------------------------------------------------------
  // GameCreated
  // -------------------------------------------------------------------------
  group('GameCreated', () {
    test('sets status to inProgress', () {
      final state = _makeState().copyWith(status: GameEngineStatus.initialized);
      final result = engine.apply(state, _event(type: 'GameCreated', payload: {}));
      expect(result.state.status, GameEngineStatus.inProgress);
    });
  });

  // -------------------------------------------------------------------------
  // Table A — TurnStarted
  // -------------------------------------------------------------------------
  group('Table A — TurnStarted', () {
    test('sets dartsThrownInTurn=0 and turnActive=true', () {
      final state = _makeState(turnActive: false, dartsThrownInTurn: 2);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.turnActive, isTrue);
    });

    test('sets currentTurnIndex to matching competitor index', () {
      final state = _makeState(currentTurnIndex: 0);
      final result = engine.apply(state, _turnStarted('c2'));
      expect(result.state.currentTurnIndex, 1);
    });

    test('isValid returns false when turn is already active', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('isValid returns true when no active turn', () {
      final state = _makeState(turnActive: false);
      expect(engine.isValid(state, _turnStarted('c1')), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Table B — DartThrown acceptance / rejection
  // -------------------------------------------------------------------------
  group('Table B — DartThrown validation', () {
    test('rejects when game is complete', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1)),
        isFalse,
      );
    });

    test('rejects when turn is inactive', () {
      final state = _makeState(turnActive: false);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1)),
        isFalse,
      );
    });

    test('rejects when 3 darts already thrown', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1)),
        isFalse,
      );
    });

    test('rejects when current player is already complete', () {
      final state = _makeState(
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1',
            name: 'P1',
            playerIds: ['p1'],
            score: 0,
            isComplete: true,
            dartThrows: [],
            legsWon: 1,
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'P2',
            playerIds: ['p2'],
            score: 0,
            isComplete: false,
            dartThrows: [],
            legsWon: 0,
            currentTarget: 1,
          ),
        ],
      );
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1)),
        isFalse,
      );
    });

    test('accepts when turn active and fewer than 3 darts thrown', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 0);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1)),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Table D1 — Standard hit validation
  // -------------------------------------------------------------------------
  group('Table D1 — Standard: any multiplier on current target advances', () {
    test('single on current target advances', () {
      final state = _makeState(variant: 'standard', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 2);
    });

    test('double on current target advances', () {
      final state = _makeState(variant: 'standard', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2));
      expect(result.state.competitors[0].currentTarget, 2);
    });

    test('triple on current target advances', () {
      final state = _makeState(variant: 'standard', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 3));
      expect(result.state.competitors[0].currentTarget, 2);
    });

    test('wrong segment does not advance target', () {
      final state = _makeState(variant: 'standard', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 2, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 1); // unchanged
    });

    test('Bull (25) ignored — no target change', () {
      final state = _makeState(variant: 'standard', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 1); // unchanged
    });

    test('Miss (0) ignored — no target change', () {
      final state = _makeState(variant: 'standard', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 1); // unchanged
    });
  });

  group('Table D1 — Reverse: any multiplier on current target advances', () {
    test('single on target 20 decrements to 19', () {
      final state = _makeState(variant: 'reverse', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 19);
    });

    test('double on target 20 decrements to 19', () {
      final state = _makeState(variant: 'reverse', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.state.competitors[0].currentTarget, 19);
    });

    test('wrong segment does not change target', () {
      final state = _makeState(variant: 'reverse', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 19, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 20); // unchanged
    });

    test('Bull (25) ignored in Reverse', () {
      final state = _makeState(variant: 'reverse', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2));
      expect(result.state.competitors[0].currentTarget, 20); // unchanged
    });
  });

  // -------------------------------------------------------------------------
  // Table D2 — DoublesOnly hit validation
  // -------------------------------------------------------------------------
  group('Table D2 — DoublesOnly: only doubles advance target', () {
    test('double on current target advances', () {
      final state = _makeState(variant: 'doublesOnly', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2));
      expect(result.state.competitors[0].currentTarget, 2);
    });

    test('single on current target does NOT advance', () {
      final state = _makeState(variant: 'doublesOnly', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 1); // unchanged
    });

    test('triple on current target does NOT advance', () {
      final state = _makeState(variant: 'doublesOnly', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 3));
      expect(result.state.competitors[0].currentTarget, 1); // unchanged
    });

    test('double on wrong segment does NOT advance', () {
      final state = _makeState(variant: 'doublesOnly', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 5, multiplier: 2));
      expect(result.state.competitors[0].currentTarget, 1); // unchanged
    });
  });

  // -------------------------------------------------------------------------
  // Table E1 — Standard target advancement
  // -------------------------------------------------------------------------
  group('Table E1 — Standard: ascending 1→20', () {
    test('target at 1: hit 1 → target becomes 2 (not complete)', () {
      final state = _makeState(variant: 'standard', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 2);
      expect(result.state.competitors[0].isComplete, isFalse);
    });

    test('target at 19: hit 19 → target becomes 20 (not complete)', () {
      final state = _makeState(
        variant: 'standard',
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 19,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 19, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 20);
      expect(result.state.competitors[0].isComplete, isFalse);
    });

    test('target at 20: hit 20 → completed, game won (legsToWin=1)', () {
      final state = _makeState(
        variant: 'standard',
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.competitors[0].isComplete, isTrue);
      expect(result.state.isComplete, isTrue);
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c1');
    });
  });

  // -------------------------------------------------------------------------
  // Table E2 — Reverse target advancement
  // -------------------------------------------------------------------------
  group('Table E2 — Reverse: descending 20→1', () {
    test('target at 20: hit 20 → target becomes 19 (not complete)', () {
      final state = _makeState(variant: 'reverse', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 19);
      expect(result.state.competitors[0].isComplete, isFalse);
    });

    test('target at 2: hit 2 → target becomes 1 (not complete)', () {
      final state = _makeState(
        variant: 'reverse',
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 2,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 2, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 1);
      expect(result.state.competitors[0].isComplete, isFalse);
    });

    test('target at 1: hit 1 → completed, game won (legsToWin=1)', () {
      final state = _makeState(
        variant: 'reverse',
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1));
      expect(result.state.competitors[0].isComplete, isTrue);
      expect(result.state.isComplete, isTrue);
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c1');
    });
  });

  // -------------------------------------------------------------------------
  // Table E3 — DoublesOnly target advancement
  // -------------------------------------------------------------------------
  group('Table E3 — DoublesOnly: ascending 1→20, doubles only', () {
    test('target at 1: double-1 → target becomes 2', () {
      final state = _makeState(variant: 'doublesOnly', turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 2));
      expect(result.state.competitors[0].currentTarget, 2);
    });

    test('target at 20: double-20 → completed, game won', () {
      final state = _makeState(
        variant: 'doublesOnly',
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.state.isComplete, isTrue);
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('target at 20: single-20 does NOT complete (not a double)', () {
      final state = _makeState(
        variant: 'doublesOnly',
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.competitors[0].currentTarget, 20); // unchanged
      expect(result.state.isComplete, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Table F — Win condition: immediate win on dart that completes sequence
  // -------------------------------------------------------------------------
  group('Table F — Win on completion dart', () {
    test('win on 1st dart: turnActive=false immediately', () {
      final state = _makeState(
        variant: 'standard',
        turnActive: true,
        dartsThrownInTurn: 0,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 5,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.isComplete, isTrue);
      expect(result.state.turnActive, isFalse);
      expect(result.state.winnerCompetitorId, 'c1');
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('win on 2nd dart: turn ends immediately', () {
      final state = _makeState(
        variant: 'standard',
        turnActive: true,
        dartsThrownInTurn: 1,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: ['MISS'], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.isComplete, isTrue);
      expect(result.state.turnActive, isFalse);
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('win on 3rd dart: game complete', () {
      final state = _makeState(
        variant: 'standard',
        turnActive: true,
        dartsThrownInTurn: 2,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: ['MISS', 'MISS'], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.isComplete, isTrue);
      expect(result.outcome, LegOutcome.gameCompleted);
    });
  });

  // -------------------------------------------------------------------------
  // Table H — Turn end conditions
  // -------------------------------------------------------------------------
  group('Table H — Turn end conditions', () {
    test('turn does NOT end after 1st dart (non-hit)', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 0);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 5, multiplier: 1));
      expect(result.state.dartsThrownInTurn, 1);
      expect(result.state.turnActive, isTrue);
    });

    test('turn does NOT end after 2nd dart (non-hit)', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 1);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 5, multiplier: 1));
      expect(result.state.dartsThrownInTurn, 2);
      expect(result.state.turnActive, isTrue);
    });

    test('turn ends after 3rd dart (non-hit)', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 2);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 5, multiplier: 1));
      expect(result.state.dartsThrownInTurn, 3);
      expect(result.state.turnActive, isFalse);
    });

    test('turn ends immediately on completion (1st dart)', () {
      final state = _makeState(
        variant: 'standard',
        turnActive: true,
        dartsThrownInTurn: 0,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.state.turnActive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Table I — TurnEnded
  // -------------------------------------------------------------------------
  group('Table I — TurnEnded', () {
    test('sets turnActive=false and resets dartsThrownInTurn', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.turnActive, isFalse);
      expect(result.state.dartsThrownInTurn, 0);
    });

    test('advances currentTurnIndex from 0 to 1', () {
      final state = _makeState(currentTurnIndex: 0, turnActive: true);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.currentTurnIndex, 1);
    });

    test('wraps currentTurnIndex from 1 back to 0 for 2-player game', () {
      final state = _makeState(currentTurnIndex: 1, turnActive: true);
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.state.currentTurnIndex, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Table K — Leg reset
  // -------------------------------------------------------------------------
  group('Table K — Leg reset', () {
    test('Standard: currentTarget resets to 1 for all competitors', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 5,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.competitors[0].currentTarget, 1);
      expect(result.state.competitors[1].currentTarget, 1);
    });

    test('Reverse: currentTarget resets to 20 for all competitors', () {
      final state = _makeState(
        variant: 'reverse',
        legsToWin: 2,
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 15,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.competitors[0].currentTarget, 20);
      expect(result.state.competitors[1].currentTarget, 20);
    });

    test('DoublesOnly: currentTarget resets to 1 for all competitors', () {
      final state = _makeState(
        variant: 'doublesOnly',
        legsToWin: 2,
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 7,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.competitors[0].currentTarget, 1);
      expect(result.state.competitors[1].currentTarget, 1);
    });

    test('isComplete resets to false for all competitors after leg reset', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 5,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.competitors[0].isComplete, isFalse);
      expect(result.state.competitors[1].isComplete, isFalse);
    });

    test('dartThrows cleared for all competitors after leg reset', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: ['1', '2', '3'], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: ['4', '5'], legsWon: 0, currentTarget: 5,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.competitors[0].dartThrows, isEmpty);
      expect(result.state.competitors[1].dartThrows, isEmpty);
    });

    test('currentTurnIndex resets to 0 and turnActive=false after leg reset', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        turnActive: true,
        currentTurnIndex: 1,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 5,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c2', segment: 20, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.currentTurnIndex, 0);
      expect(result.state.turnActive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Multi-leg game
  // -------------------------------------------------------------------------
  group('Multi-leg game', () {
    test('legsWon increments after winning a leg', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      // legsWon is set before reset; after reset, it is preserved on the winner
      expect(result.state.competitors[0].legsWon, 1);
    });

    test('outcome is legCompleted when legsWon < legsToWin', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.isComplete, isFalse);
    });

    test('outcome is gameCompleted when legsWon reaches legsToWin', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        turnActive: true,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 1, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.state.isComplete, isTrue);
      expect(result.state.competitors[0].legsWon, 2);
    });

    test('currentLegIndex increments after leg reset', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        turnActive: true,
        currentLegIndex: 0,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1));
      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.currentLegIndex, 1);
    });
  });

  // -------------------------------------------------------------------------
  // LegCompleted event replay
  // -------------------------------------------------------------------------
  group('LegCompleted event replay', () {
    test('increments legsWon and resets leg when not game over', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 2,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: ['1', '2'], legsWon: 0, currentTarget: 5,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: ['3'], legsWon: 0, currentTarget: 3,
          ),
        ],
      );
      final result = engine.apply(
        state,
        _event(type: 'LegCompleted', payload: {'winner_competitor_id': 'c1'}),
      );
      expect(result.state.competitors[0].legsWon, 1);
      expect(result.state.isComplete, isFalse);
      expect(result.state.competitors[0].currentTarget, 1); // reset
      expect(result.state.competitors[0].dartThrows, isEmpty); // reset
    });

    test('sets game complete when legsWon reaches legsToWin', () {
      final state = _makeState(
        variant: 'standard',
        legsToWin: 1,
        competitors: [
          const CompetitorState(
            competitorId: 'c1', name: 'P1', playerIds: ['p1'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 20,
          ),
          const CompetitorState(
            competitorId: 'c2', name: 'P2', playerIds: ['p2'],
            score: 0, dartThrows: [], legsWon: 0, currentTarget: 1,
          ),
        ],
      );
      final result = engine.apply(
        state,
        _event(type: 'LegCompleted', payload: {'winner_competitor_id': 'c1'}),
      );
      expect(result.state.isComplete, isTrue);
      expect(result.state.winnerCompetitorId, 'c1');
      expect(result.outcome, LegOutcome.gameCompleted);
    });
  });

  // -------------------------------------------------------------------------
  // Table L — GameCompleted event
  // -------------------------------------------------------------------------
  group('Table L — GameCompleted event', () {
    test('sets isComplete=true, winnerCompetitorId, and status=completed', () {
      final state = _makeState(isComplete: true, winnerCompetitorId: 'c1');
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': 'c1'}),
      );
      expect(result.state.isComplete, isTrue);
      expect(result.state.winnerCompetitorId, 'c1');
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.state.turnActive, isFalse);
      expect(result.outcome, LegOutcome.gameCompleted);
    });
  });

  // -------------------------------------------------------------------------
  // isValid edge cases
  // -------------------------------------------------------------------------
  group('isValid edge cases', () {
    test('GameCompleted accepted only when isComplete=true and winner set', () {
      final state = _makeState(isComplete: true, winnerCompetitorId: 'c1');
      expect(
        engine.isValid(state, _event(type: 'GameCompleted', payload: {'winner_id': 'c1'})),
        isTrue,
      );
    });

    test('unknown event type is always valid', () {
      final state = _makeState();
      expect(engine.isValid(state, _event(type: 'UnknownEvent', payload: {})), isTrue);
    });

    test('DartThrown is invalid after game complete regardless of turnActive', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 1, multiplier: 1)),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Canonical string recording
  // -------------------------------------------------------------------------
  group('Canonical string recording', () {
    test('miss recorded as MISS', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });

    test('single bull recorded as SB', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('SB'));
    });

    test('double bull recorded as DB', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2));
      expect(result.state.competitors[0].dartThrows, contains('DB'));
    });

    test('single 5 recorded as 5', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 5, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('5'));
    });

    test('double 10 recorded as D10', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 10, multiplier: 2));
      expect(result.state.competitors[0].dartThrows, contains('D10'));
    });

    test('triple 20 recorded as T20', () {
      final state = _makeState(turnActive: true);
      // Target is 1 for standard, so T20 is a non-hit but dart is still recorded
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.competitors[0].dartThrows, contains('T20'));
    });

    test('dart throw always recorded even on miss/wrong segment', () {
      final state = _makeState(variant: 'standard', turnActive: true);
      // Target is 1, hitting 7 → no advance but still recorded
      final result = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 7, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, hasLength(1));
      expect(result.state.competitors[0].dartThrows.first, '7');
    });
  });
}
