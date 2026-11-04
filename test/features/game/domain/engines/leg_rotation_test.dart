// Leg rotation: the throw alternates leg by leg in multi-leg X01 and Cricket
// matches (docs/games/x01.transitions.md Table K, cricket.transitions.md
// Table L), and the round counter / round cap follow the leg starter.

import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/leg_rotation.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_cricket_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_x01_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';

int _seq = 0;

GameEvent _event(String type, Map<String, dynamic> payload) {
  _seq++;
  return GameEvent(
    eventId: 'e$_seq',
    gameId: 'g1',
    eventType: type,
    localSequence: _seq,
    occurredAt: DateTime.utc(2026, 1, 1),
    payload: payload,
    synced: false,
    actorId: 'test',
    source: EventSource.client,
  );
}

GameEvent _turnStarted(String id) =>
    _event('TurnStarted', {'competitor_id': id});
GameEvent _turnEnded(String id) => _event('TurnEnded', {'competitor_id': id});
GameEvent _dart(String id, int segment, int multiplier) => _event(
    'DartThrown',
    {'competitor_id': id, 'segment': segment, 'multiplier': multiplier});

CompetitorState _x01Competitor(String id, {int score = 501}) =>
    CompetitorState(
      competitorId: id,
      name: id,
      playerIds: ['p-$id'],
      score: score,
      startingScore: 501,
      isIn: true,
    );

GameState _x01State({
  required List<CompetitorState> competitors,
  int legsToWin = 3,
  int currentLegIndex = 0,
  int? totalRounds,
}) =>
    GameState(
      gameId: 'g1',
      gameType: GameType.x01,
      competitors: competitors,
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      status: GameEngineStatus.inProgress,
      legsToWin: legsToWin,
      currentLegIndex: currentLegIndex,
      x01TotalRounds: totalRounds,
      inStrategy: 'straight',
      outStrategy: 'double',
    );

GameState _applyAll(GameEngine engine, GameState state, List<GameEvent> es) {
  var s = state;
  for (final e in es) {
    s = engine.apply(s, e).state;
  }
  return s;
}

/// A full three-dart visit of misses for [id].
List<GameEvent> _missVisit(String id) => [
      _turnStarted(id),
      _dart(id, 0, 1),
      _dart(id, 0, 1),
      _dart(id, 0, 1),
      _turnEnded(id),
    ];

void main() {
  group('legStarterIndexFor', () {
    test('two players alternate leg by leg', () {
      expect([for (var leg = 0; leg < 5; leg++) legStarterIndexFor(leg, 2)],
          [0, 1, 0, 1, 0]);
    });

    test('three players rotate round-robin', () {
      expect([for (var leg = 0; leg < 6; leg++) legStarterIndexFor(leg, 3)],
          [0, 1, 2, 0, 1, 2]);
    });

    test('a solo player starts every leg', () {
      expect(legStarterIndexFor(4, 1), 0);
    });
  });

  group('X01 leg starter', () {
    final engine = StatelessX01Engine();

    test('the second player starts leg 2 after the first player checks out',
        () {
      var state = _x01State(competitors: [
        _x01Competitor('c1', score: 40),
        _x01Competitor('c2'),
      ]);
      state = engine.apply(state, _turnStarted('c1')).state;
      final result = engine.apply(state, _dart('c1', 20, 2));

      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.currentLegIndex, 1);
      expect(result.state.legStarterIndex, 1);
      expect(
          result.state.competitors[result.state.currentTurnIndex].competitorId,
          'c2');
    });

    test('the leg starter alternates regardless of the previous leg winner',
        () {
      // Leg 2 (index 1), started by c2; c2 checks out → leg 3 goes to c1.
      var state = _x01State(currentLegIndex: 1, competitors: [
        _x01Competitor('c1'),
        _x01Competitor('c2', score: 40),
      ]);
      state = engine.apply(state, _turnStarted('c2')).state;
      final result = engine.apply(state, _dart('c2', 20, 2));

      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.currentLegIndex, 2);
      expect(result.state.currentTurnIndex, 0);
      expect(result.state.legStarterIndex, 0);
    });

    test('three players: leg 2 is started by the second player', () {
      var state = _x01State(competitors: [
        _x01Competitor('c1', score: 40),
        _x01Competitor('c2'),
        _x01Competitor('c3'),
      ]);
      state = engine.apply(state, _turnStarted('c1')).state;
      final result = engine.apply(state, _dart('c1', 20, 2));

      expect(result.state.currentTurnIndex, 1);
    });

    test('the round advances when the turn returns to the leg starter', () {
      // Leg 2, started by c2.
      var state = _x01State(currentLegIndex: 1, competitors: [
        _x01Competitor('c1'),
        _x01Competitor('c2'),
      ]);

      state = _applyAll(engine, state, _missVisit('c2'));
      state = engine.apply(state, _turnStarted('c1')).state;
      expect(state.currentRoundInLeg, 1,
          reason: 'c1 throws second in round 1 of this leg');

      state = _applyAll(engine, state, [
        _dart('c1', 0, 1),
        _dart('c1', 0, 1),
        _dart('c1', 0, 1),
        _turnEnded('c1'),
        _turnStarted('c2'),
      ]);
      expect(state.currentRoundInLeg, 2);
    });

    test('the round cap fires after the last thrower of the round', () {
      // One-round cap, leg 2 started by c2: c2 then c1 make up the round.
      var state = _x01State(currentLegIndex: 1, totalRounds: 1, competitors: [
        _x01Competitor('c1', score: 100),
        _x01Competitor('c2', score: 200),
      ]);

      state = _applyAll(engine, state, [
        _turnStarted('c2'),
        _dart('c2', 0, 1),
        _dart('c2', 0, 1),
        _dart('c2', 0, 1),
      ]);
      final afterStarter = engine.apply(state, _turnEnded('c2'));
      expect(afterStarter.outcome, LegOutcome.none,
          reason: 'c1 has not thrown in this round yet');

      state = _applyAll(engine, afterStarter.state, [
        _turnStarted('c1'),
        _dart('c1', 0, 1),
        _dart('c1', 0, 1),
        _dart('c1', 0, 1),
      ]);
      final afterLast = engine.apply(state, _turnEnded('c1'));
      expect(afterLast.outcome, LegOutcome.legCompleted);
      expect(afterLast.winnerCompetitorId, 'c1');
      expect(afterLast.state.currentTurnIndex, 0,
          reason: 'leg 3 goes back to c1');
    });

    test('a stream where the first player started leg 2 keeps that starter',
        () {
      // Recorded before starters rotated: c1 checked out leg 1 and the next
      // TurnStarted was for c1 again. The leg's first TurnStarted wins, so
      // the round counter and cap follow the starter that was played.
      var state = _x01State(competitors: [
        _x01Competitor('c1', score: 40),
        _x01Competitor('c2'),
      ]);
      state = _applyAll(engine, state, [
        _turnStarted('c1'),
        _dart('c1', 20, 2),
        _turnEnded('c1'),
        ..._missVisit('c1'),
      ]);
      expect(state.legStarterIndex, 0);
      expect(isLastTurnOfRound(state.copyWith(currentTurnIndex: 1)), isTrue);

      state = _applyAll(engine, state, [
        ..._missVisit('c2'),
        _turnStarted('c1'),
      ]);
      expect(state.currentRoundInLeg, 2);
    });
  });

  group('Cricket leg starter', () {
    final engine = StatelessCricketEngine();

    test('the second player starts leg 2 after the first player closes out',
        () {
      final closedButBull = <String, int>{
        '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3, 'Bull': 2,
      };
      var state = GameState(
        gameId: 'g1',
        gameType: GameType.cricket,
        competitors: [
          CompetitorState(
            competitorId: 'c1',
            name: 'c1',
            playerIds: const ['p1'],
            score: 10,
            marksPerNumber: closedButBull,
          ),
          const CompetitorState(
            competitorId: 'c2',
            name: 'c2',
            playerIds: ['p2'],
            score: 0,
          ),
        ],
        currentTurnIndex: 0,
        dartsThrownInTurn: 0,
        isComplete: false,
        status: GameEngineStatus.inProgress,
        legsToWin: 2,
      );
      state = engine.apply(state, _turnStarted('c1')).state;
      final result = engine.apply(state, _dart('c1', 25, 1));

      expect(result.outcome, LegOutcome.legCompleted);
      expect(result.state.legStarterIndex, 1);
      expect(
          result.state.competitors[result.state.currentTurnIndex].competitorId,
          'c2');
    });
  });
}
