// Shanghai Engine Unit Tests
// Covers per-dart scoring, Shanghai bonus detection, turn flow, and end conditions.
// Shanghai (S+D+T of round number) → INSTANT WIN: increments practiceSuccesses
// and ends the game immediately on the 3rd dart.
// Game also ends via TurnEnded when all rounds complete (no Shanghai).

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_shanghai_engine.dart';
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

/// Build a minimal single-player Shanghai game state.
/// Pass [competitors] to override with custom multi-player setup.
GameState _makeState({
  int totalRounds = 7,
  int score = 0,
  int practiceRound = 1,
  List<String> dartThrows = const [],
  int dartsThrownInTurn = 0,
  bool turnActive = false,
  bool isComplete = false,
  String? winnerCompetitorId,
  List<CompetitorState>? competitors,
  int currentTurnIndex = 0,
}) {
  final comps = competitors ??
      [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: score,
          isComplete: isComplete,
          dartThrows: dartThrows,
          practiceRound: practiceRound,
        ),
      ];
  return GameState(
    gameId: 'game-1',
    gameType: GameType.shanghai,
    competitors: comps,
    currentTurnIndex: currentTurnIndex,
    dartsThrownInTurn: dartsThrownInTurn,
    isComplete: isComplete,
    winnerCompetitorId: winnerCompetitorId,
    status: isComplete ? GameEngineStatus.completed : GameEngineStatus.inProgress,
    turnActive: turnActive,
    shanghaiTotalRounds: totalRounds,
  );
}

/// Parse a canonical dart string to (segment, multiplier).
({int segment, int multiplier}) _parseCanonical(String c) {
  if (c == 'MISS') return (segment: 0, multiplier: 1);
  if (c == 'DB') return (segment: 25, multiplier: 2);
  if (c == 'SB') return (segment: 25, multiplier: 1);
  if (c.startsWith('D')) return (segment: int.parse(c.substring(1)), multiplier: 2);
  if (c.startsWith('T')) return (segment: int.parse(c.substring(1)), multiplier: 3);
  return (segment: int.parse(c), multiplier: 1);
}

/// Apply TurnStarted + 3 darts. If the game is not complete after the 3rd dart,
/// also apply TurnEnded (to advance the round). For Shanghai instant-win, the
/// game ends mid-dart, so TurnEnded is skipped.
GameState _applyTurn(
  StatelessShanghaiEngine engine,
  GameState state,
  List<String> darts, {
  String competitorId = 'c1',
}) {
  var s = engine.apply(state, _turnStarted(competitorId)).state;
  for (final d in darts) {
    final p = _parseCanonical(d);
    s = engine.apply(
      s,
      _dartThrown(competitorId: competitorId, segment: p.segment, multiplier: p.multiplier),
    ).state;
    if (s.isComplete) return s; // Instant win — no TurnEnded needed
  }
  s = engine.apply(s, _turnEnded(competitorId)).state;
  return s;
}

void main() {
  late StatelessShanghaiEngine engine;

  setUp(() {
    _seq = 0;
    engine = StatelessShanghaiEngine();
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
  // Per-dart scoring — non-target hits score 0
  // -------------------------------------------------------------------------
  group('Non-target hits score 0 (per-dart)', () {
    test('Round 3: single 5 (wrong number) scores 0', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 5, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 0);
    });

    test('Round 3: MISS scores 0', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 0);
    });

    test('Round 3: SB (Bull) scores 0', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 0);
    });

    test('Round 3: DB (Bull) scores 0', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2),
      );
      expect(result.state.competitors[0].score, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Per-dart scoring — target hits score immediately
  // -------------------------------------------------------------------------
  group('Target hits score correctly (per-dart)', () {
    test('Round 3: single 3 → score += 3 immediately', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 3);
    });

    test('Round 3: D3 → score += 6 immediately', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 3, multiplier: 2),
      );
      expect(result.state.competitors[0].score, 6);
    });

    test('Round 3: T3 → score += 9 immediately', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 3, multiplier: 3),
      );
      expect(result.state.competitors[0].score, 9);
    });

    test('Round 7: 7+D7+T7 → cumulative score = 42, Shanghai bonus counted', () {
      final state = _makeState(practiceRound: 7);
      final after = _applyTurn(engine, state, ['7', 'D7', 'T7']);
      // 7*1 + 7*2 + 7*3 = 7 + 14 + 21 = 42
      expect(after.competitors[0].score, 42);
      expect(after.competitors[0].practiceSuccesses, 1);
      // Round 7 is the final round → TurnEnded completes the game
      expect(after.isComplete, isTrue);
    });

    test('Score accumulates across darts within a turn', () {
      // Round 5: single 5 (5) + single 5 (5) = 10 before 3rd dart
      var state = _makeState(practiceRound: 5, turnActive: true);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 5, multiplier: 1)).state;
      expect(state.competitors[0].score, 5);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 5, multiplier: 1)).state;
      expect(state.competitors[0].score, 10);
    });
  });

  // -------------------------------------------------------------------------
  // Shanghai bonus (practiceSuccesses)
  // -------------------------------------------------------------------------
  group('Shanghai bonus (practiceSuccesses)', () {
    test('single+double+triple of round → instant win, practiceSuccesses incremented', () {
      final state = _makeState(practiceRound: 3);
      final after = _applyTurn(engine, state, ['3', 'D3', 'T3']);
      expect(after.isComplete, isTrue);
      expect(after.competitors[0].practiceSuccesses, 1);
    });

    test('order T+D+single also triggers Shanghai instant win', () {
      final state = _makeState(practiceRound: 3);
      final after = _applyTurn(engine, state, ['T3', 'D3', '3']);
      expect(after.isComplete, isTrue);
      expect(after.competitors[0].practiceSuccesses, 1);
    });

    test('order D+T+single also triggers Shanghai instant win', () {
      final state = _makeState(practiceRound: 3);
      final after = _applyTurn(engine, state, ['D3', 'T3', '3']);
      expect(after.isComplete, isTrue);
      expect(after.competitors[0].practiceSuccesses, 1);
    });

    test('missing triple — NOT Shanghai, practiceSuccesses stays 0', () {
      final state = _makeState(practiceRound: 3);
      final after = _applyTurn(engine, state, ['3', 'D3', '3']);
      expect(after.competitors[0].practiceSuccesses, 0);
    });

    test('Shanghai result has outcome = gameCompleted (instant win on 3rd dart)', () {
      final state = _makeState(
        practiceRound: 3,
        turnActive: true,
        dartsThrownInTurn: 2,
        dartThrows: ['3', 'D3'],
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 3, multiplier: 3),
      );
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('Shanghai sets turnActive=false and isComplete=true on 3rd dart', () {
      var state = _makeState(practiceRound: 3, turnActive: true);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1)).state;
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 2)).state;
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 3)).state;
      expect(state.turnActive, isFalse);
      expect(state.isComplete, isTrue); // Instant win
    });
  });

  // -------------------------------------------------------------------------
  // Not Shanghai — insufficient multiplier types
  // -------------------------------------------------------------------------
  group('Not Shanghai — insufficient multiplier types', () {
    test('single+double+MISS → no Shanghai', () {
      final state = _makeState(practiceRound: 3);
      final after = _applyTurn(engine, state, ['3', 'D3', 'MISS']);
      expect(after.competitors[0].practiceSuccesses, 0);
    });

    test('only triple → no Shanghai', () {
      final state = _makeState(practiceRound: 3);
      final after = _applyTurn(engine, state, ['T3', 'MISS', 'MISS']);
      expect(after.competitors[0].practiceSuccesses, 0);
    });

    test('only single → no Shanghai', () {
      final state = _makeState(practiceRound: 3);
      final after = _applyTurn(engine, state, ['3', 'MISS', 'MISS']);
      expect(after.competitors[0].practiceSuccesses, 0);
    });

    test('Shanghai not evaluated before 3rd dart', () {
      // After 2 darts that include single and double, game still in progress
      var state = _makeState(practiceRound: 3, turnActive: true);
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1)).state;
      state = engine.apply(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 2)).state;
      expect(state.isComplete, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Turn advancement — round counter
  // -------------------------------------------------------------------------
  group('Turn advancement — round counter', () {
    test('practiceRound starts at 1', () {
      final state = _makeState();
      expect(state.competitors[0].practiceRound, 1);
    });

    test('after round 1 turn (3 darts, no Shanghai), practiceRound = 2', () {
      final state = _makeState(practiceRound: 1);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.competitors[0].practiceRound, 2);
    });

    test('after round 6 turn (no Shanghai), practiceRound = 7', () {
      final state = _makeState(practiceRound: 6, score: 30);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.competitors[0].practiceRound, 7);
      expect(after.isComplete, isFalse);
    });

    test('practiceRound NOT incremented after Shanghai instant win (no TurnEnded)', () {
      final state = _makeState(practiceRound: 3);
      final after = _applyTurn(engine, state, ['3', 'D3', 'T3']);
      // Game ends instantly on 3rd dart — TurnEnded is not applied
      expect(after.competitors[0].practiceRound, 3); // unchanged
      expect(after.competitors[0].practiceSuccesses, 1);
      expect(after.isComplete, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Final round completion — no Shanghai
  // -------------------------------------------------------------------------
  group('Final round completion — no Shanghai', () {
    test('after totalRounds with no Shanghai, isComplete = true', () {
      final state = _makeState(totalRounds: 7, practiceRound: 7);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.isComplete, isTrue);
    });

    test('single-player: winnerCompetitorId = null', () {
      final state = _makeState(totalRounds: 7, practiceRound: 7);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.winnerCompetitorId, isNull);
    });

    test('single-player: status = completed', () {
      final state = _makeState(totalRounds: 7, practiceRound: 7);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.status, GameEngineStatus.completed);
    });

    test('3rd dart in final round has outcome = none (game completes at TurnEnded)', () {
      final state = _makeState(
        totalRounds: 7,
        practiceRound: 7,
        turnActive: true,
        dartsThrownInTurn: 2,
        dartThrows: ['MISS', 'MISS'],
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.outcome, LegOutcome.none);
    });

    test('custom totalRounds=3: ends after round 3', () {
      final state = _makeState(totalRounds: 3, practiceRound: 3);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.isComplete, isTrue);
    });

    test('custom totalRounds=3: round 2 does NOT end the game', () {
      final state = _makeState(totalRounds: 3, practiceRound: 2);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.isComplete, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Shanghai on final round
  // -------------------------------------------------------------------------
  group('Shanghai on final round', () {
    test('Shanghai on round 7 (final) → instant win, isComplete=true, single-player winner=null', () {
      final state = _makeState(totalRounds: 7, practiceRound: 7);
      final after = _applyTurn(engine, state, ['7', 'D7', 'T7']);
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, isNull); // single-player: no winner
      expect(after.competitors[0].practiceSuccesses, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Multi-player end — highest score wins
  // -------------------------------------------------------------------------
  group('Multi-player end — highest score wins', () {
    test('P1 finishes round 7 with higher score → P1 wins', () {
      // P2 already completed (practiceRound=8, score=50)
      // P1 at round 7, score=0; hits T7+T7+T7 → +63 = 63 > 50
      final comps = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 0,
          practiceRound: 7,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 50,
          practiceRound: 8, // already beyond final round
        ),
      ];
      final state = _makeState(totalRounds: 7, competitors: comps, currentTurnIndex: 0);
      final after = _applyTurn(engine, state, ['T7', 'T7', 'T7'], competitorId: 'c1');
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, 'c1');
    });

    test('P2 has higher score when P1 finishes round 7 → P2 wins', () {
      // P2 at practiceRound=8, score=100; P1 at round 7, score=0, all misses → 0
      final comps = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 0,
          practiceRound: 7,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 100,
          practiceRound: 8,
        ),
      ];
      final state = _makeState(totalRounds: 7, competitors: comps, currentTurnIndex: 0);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS'], competitorId: 'c1');
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, 'c2');
    });

    test('tie score → P1 (index 0) wins', () {
      // Both at score=50; P1 misses, finishes at 50; P2 at 50
      final comps = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 50,
          practiceRound: 7,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 50,
          practiceRound: 8,
        ),
      ];
      final state = _makeState(totalRounds: 7, competitors: comps, currentTurnIndex: 0);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS'], competitorId: 'c1');
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, 'c1');
    });

    test('P1 not last in final round while P2 still has rounds to play', () {
      // P1 at round 7, P2 at round 3 — P2 hasn't finished yet → game NOT complete
      final comps = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 0,
          practiceRound: 7,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 20,
          practiceRound: 3,
        ),
      ];
      final state = _makeState(totalRounds: 7, competitors: comps, currentTurnIndex: 0);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS'], competitorId: 'c1');
      expect(after.isComplete, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Multi-player natural completion — #595 regression
  //
  // The bug: `apply('TurnEnded')` set `isComplete=true` in state but returned
  // a bare `EngineResult` (outcome=none). `_advanceTurn` gates GameCompleted
  // emission on `outcome == gameCompleted`, so it skipped completion and
  // emitted a TurnStarted for a phantom round 8 → board soft-lock. These
  // tests assert the EngineResult itself (not just .state), which the prior
  // tests never did, and exercise a real round-by-round rotation to the end.
  // -------------------------------------------------------------------------
  group('Multi-player natural completion (#595)', () {
    test('final TurnEnded surfaces outcome=gameCompleted + winner', () {
      // P2 already beyond the final round; P1 throws its last round-7 turn.
      final comps = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 0,
          practiceRound: 7,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 50,
          practiceRound: 8,
        ),
      ];
      var state = _makeState(totalRounds: 7, competitors: comps, currentTurnIndex: 0);
      state = engine.apply(state, _turnStarted('c1')).state;
      for (var i = 0; i < 3; i++) {
        state = engine
            .apply(state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1))
            .state;
      }
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.outcome, LegOutcome.gameCompleted);
      expect(result.winnerCompetitorId, 'c2');
      expect(result.state.isComplete, isTrue);
    });

    test('intermediate TurnEnded has outcome=none (rotation continues)', () {
      final comps = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 0,
          practiceRound: 2,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 0,
          practiceRound: 2,
        ),
      ];
      var state = _makeState(totalRounds: 2, competitors: comps, currentTurnIndex: 0);
      state = engine.apply(state, _turnStarted('c1')).state;
      for (var i = 0; i < 3; i++) {
        state = engine
            .apply(state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1))
            .state;
      }
      // P1 finishes its final round but P2 still owes round 2 → not complete.
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.outcome, LegOutcome.none);
      expect(result.state.isComplete, isFalse);
      expect(result.state.currentTurnIndex, 1);
    });

    test('full 2-player rotation completes via the last TurnEnded', () {
      // Mirrors the live repro: both players play every round; the game must
      // complete on the final competitor's TurnEnded, not roll into round N+1.
      const rounds = 3;
      final comps = [
        CompetitorState(
            competitorId: 'c1',
            name: 'P1',
            playerIds: ['p1'],
            score: 0,
            practiceRound: 1),
        CompetitorState(
            competitorId: 'c2',
            name: 'P2',
            playerIds: ['p2'],
            score: 0,
            practiceRound: 1),
      ];
      var state = _makeState(totalRounds: rounds, competitors: comps);
      EngineResult? last;
      for (var r = 1; r <= rounds; r++) {
        for (final cid in ['c1', 'c2']) {
          state = engine.apply(state, _turnStarted(cid)).state;
          for (var i = 0; i < 3; i++) {
            // c1 always scores its round number, c2 always misses → c1 wins.
            final hit = cid == 'c1';
            state = engine
                .apply(
                    state,
                    _dartThrown(
                        competitorId: cid,
                        segment: hit ? r : 0,
                        multiplier: 1))
                .state;
          }
          last = engine.apply(state, _turnEnded(cid));
          state = last.state;
        }
      }
      expect(state.isComplete, isTrue,
          reason: 'game must complete after the final round rotation');
      expect(last!.outcome, LegOutcome.gameCompleted);
      expect(state.winnerCompetitorId, 'c1');
      // No phantom extra round: both competitors land exactly at rounds+1.
      expect(state.competitors.every((c) => c.practiceRound == rounds + 1), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // TurnStarted
  // -------------------------------------------------------------------------
  group('TurnStarted', () {
    test('sets dartsThrownInTurn=0 and turnActive=true', () {
      final state = _makeState(turnActive: false, dartsThrownInTurn: 2);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.turnActive, isTrue);
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
  // TurnEnded
  // -------------------------------------------------------------------------
  group('TurnEnded', () {
    test('increments practiceRound, resets dartsThrownInTurn, sets turnActive=false', () {
      final state = _makeState(
        practiceRound: 1,
        turnActive: true,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.competitors[0].practiceRound, 2);
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.turnActive, isFalse);
    });

    test('rotates currentTurnIndex for multi-player', () {
      final comps = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 0,
          practiceRound: 1,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 0,
          practiceRound: 1,
        ),
      ];
      final state = _makeState(competitors: comps, currentTurnIndex: 0, turnActive: true);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.currentTurnIndex, 1);
    });

    test('currentTurnIndex wraps back to 0 for last player', () {
      final comps = [
        CompetitorState(
          competitorId: 'c1',
          name: 'Player 1',
          playerIds: ['p1'],
          score: 0,
          practiceRound: 1,
        ),
        CompetitorState(
          competitorId: 'c2',
          name: 'Player 2',
          playerIds: ['p2'],
          score: 0,
          practiceRound: 1,
        ),
      ];
      final state = _makeState(competitors: comps, currentTurnIndex: 1, turnActive: true);
      final result = engine.apply(state, _turnEnded('c2'));
      expect(result.state.currentTurnIndex, 0);
    });

    test('TurnEnded on final round completes the game', () {
      final state = _makeState(
        totalRounds: 7,
        practiceRound: 7,
        turnActive: true,
        dartsThrownInTurn: 3,
      );
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
    });
  });

  // -------------------------------------------------------------------------
  // isComplete guard
  // -------------------------------------------------------------------------
  group('isComplete guard', () {
    test('events are ignored when game is already complete', () {
      final state = _makeState(isComplete: true, turnActive: false);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.turnActive, isFalse); // unchanged
      expect(result.state.isComplete, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // isValid rejections
  // -------------------------------------------------------------------------
  group('isValid rejections', () {
    test('DartThrown rejected when isComplete = true', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when dartsThrownInTurn >= 3', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when turn not active', () {
      final state = _makeState(turnActive: false);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1)),
        isFalse,
      );
    });

    test('TurnStarted rejected when turn already active', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('DartThrown accepted in normal mid-turn state', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 1);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1)),
        isTrue,
      );
    });

    test('unknown event type always valid', () {
      final state = _makeState();
      expect(engine.isValid(state, _event(type: 'UnknownEvent', payload: {})), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // GameCompleted event replay
  // -------------------------------------------------------------------------
  group('GameCompleted event replay', () {
    test('sets isComplete=true, status=completed, turnActive=false', () {
      final state = _makeState();
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': 'c1'}),
      );
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.state.turnActive, isFalse);
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('sets winnerCompetitorId from payload', () {
      final state = _makeState();
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': 'c1'}),
      );
      expect(result.state.winnerCompetitorId, 'c1');
    });

    test('winnerCompetitorId null when payload winner_id is null', () {
      final state = _makeState();
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': null}),
      );
      expect(result.state.winnerCompetitorId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Canonical string recording
  // -------------------------------------------------------------------------
  group('Canonical string recording', () {
    test('MISS recorded as MISS', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });

    test('SB recorded as SB', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1),
      );
      expect(result.state.competitors[0].dartThrows, contains('SB'));
    });

    test('DB recorded as DB', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2),
      );
      expect(result.state.competitors[0].dartThrows, contains('DB'));
    });

    test('single 3 recorded as 3', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 3, multiplier: 1),
      );
      expect(result.state.competitors[0].dartThrows, contains('3'));
    });

    test('D3 recorded as D3', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 3, multiplier: 2),
      );
      expect(result.state.competitors[0].dartThrows, contains('D3'));
    });

    test('T3 recorded as T3', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 3, multiplier: 3),
      );
      expect(result.state.competitors[0].dartThrows, contains('T3'));
    });

    test('non-target dart is still recorded (5 in round 3)', () {
      final state = _makeState(practiceRound: 3, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 5, multiplier: 1),
      );
      expect(result.state.competitors[0].dartThrows, contains('5'));
    });
  });
}
