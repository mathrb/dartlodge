// Stateless Cricket Game Engine
// Pure functional implementation of Cricket darts game (Standard, CutThroat, NoScore)
// Implements all transition tables from docs/games/cricket.transitions.md

import '../models/game_config.dart';
import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessCricketEngine implements GameEngine {
  // The cricket target set is no longer hardcoded: it is derived from
  // `state.cricketTargets` (+ implicit Bull) at every use site, so the
  // engine accepts any target mode (fixed/random/crazy). Bull (25) is
  // always a target; it never appears in `cricketTargets`.
  // See `docs/plans/2026-05-19-cricket-target-modes-design.md` §5.

  /// Cricket mark-keys for the current target set: `['15', '16', ..., 'Bull']`
  /// for fixed; for random/crazy it follows whatever numbers are active.
  /// Bull is always appended last.
  List<String> _cricketKeys(GameState state) => [
        for (final n in state.cricketTargets) n.toString(),
        'Bull',
      ];

  /// Valid cricket segment base numbers for the current target set
  /// (always includes 25 for Bull).
  Set<int> _validCricketSegments(GameState state) =>
      {...state.cricketTargets, 25};

  @override
  EngineResult apply(GameState state, GameEvent event) {
    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => _applyDartThrownWithOutcome(state, event),
      'TurnEnded' => _applyTurnEnded(state, event),
      'LegCompleted' => _applyLegCompleted(state, event),
      'GameCompleted' => EngineResult(
          state: _applyGameCompleted(state, event),
          outcome: LegOutcome.gameCompleted),
      _ => EngineResult(state: state),
    };
  }

  @override
  bool isValid(GameState state, GameEvent event) {
    if (state.isComplete && event.eventType != 'GameCompleted') return false;

    switch (event.eventType) {
      case 'TurnStarted':
        return !state.turnActive;
      case 'DartThrown':
        return state.turnActive && state.dartsThrownInTurn < 3;
      case 'GameCompleted':
        return state.isComplete && state.winnerCompetitorId != null;
      default:
        return true;
    }
  }

  GameState _applyTurnStarted(GameState state, GameEvent event) {
    final competitorId = event.payload['competitor_id'] as String;
    final competitorIndex =
        state.competitors.indexWhere((c) => c.competitorId == competitorId);
    final resolvedIndex = competitorIndex >= 0 ? competitorIndex : state.currentTurnIndex;

    // Increment round when cycling back to the first competitor after darts
    // have been thrown — i.e. a full visit cycle just completed.
    final newRound = resolvedIndex == 0 &&
            state.competitors[0].dartThrows.isNotEmpty
        ? state.currentRoundInLeg + 1
        : state.currentRoundInLeg;

    return state.copyWith(
      currentTurnIndex: resolvedIndex,
      dartsThrownInTurn: 0,
      turnActive: true,
      currentRoundInLeg: newRound,
    );
  }

  EngineResult _applyDartThrownWithOutcome(GameState state, GameEvent event) {
    final (newState, outcome, winnerId) = _applyDartThrown(state, event);
    return EngineResult(
      state: newState,
      outcome: outcome,
      winnerCompetitorId: winnerId,
      isBust: false, // Cricket has no bust
    );
  }

  (GameState, LegOutcome, String?) _applyDartThrown(
      GameState state, GameEvent event) {
    final payload = event.payload;
    final segmentNum = payload['segment'] as int;
    final multiplier = payload['multiplier'] as int;

    // Build canonical string for dart throw recording
    final canonicalString =
        Segment.fromBoardHit(segmentNum, multiplier).toCanonicalString();

    // Record the dart throw and increment count
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final currentCompetitor = updatedCompetitors[state.currentTurnIndex];
    updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
      dartThrows: [...currentCompetitor.dartThrows, canonicalString],
    );

    var newState = state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
    );

    // Table C — Valid cricket numbers check
    if (!_validCricketSegments(newState).contains(segmentNum)) {
      // Dart counts as thrown but has no game effect
      return (_checkTurnEnd(newState), LegOutcome.none, null);
    }

    final cricketKey = segmentNum == 25 ? 'Bull' : segmentNum.toString();

    // Table D — Update marks
    final currentHits =
        updatedCompetitors[newState.currentTurnIndex].marksPerNumber[cricketKey] ?? 0;
    final newHits = (currentHits + multiplier).clamp(0, 3);
    final overflow = (currentHits + multiplier - 3).clamp(0, multiplier);

    final competitorAfterMarks = updatedCompetitors[newState.currentTurnIndex];
    final updatedMarks = Map<String, int>.from(competitorAfterMarks.marksPerNumber)
      ..[cricketKey] = newHits;

    final competitorWithMarks = competitorAfterMarks.copyWith(marksPerNumber: updatedMarks);
    final competitorsAfterMarks = List<CompetitorState>.from(newState.competitors)
      ..[newState.currentTurnIndex] = competitorWithMarks;

    newState = newState.copyWith(competitors: competitorsAfterMarks);

    // Table E — Overflow scoring
    if (overflow > 0) {
      newState = _applyOverflowScoring(
          newState, cricketKey, segmentNum, multiplier, overflow);
    }

    // Table F — All-closed detection
    newState = _checkAllClosed(newState);

    // Table G — Win condition evaluation
    final (stateAfterWin, outcome, winnerId) = _evaluateWin(newState);
    if (outcome != LegOutcome.none) {
      return (stateAfterWin, outcome, winnerId);
    }

    // Table I — Turn end after 3 darts
    return (_checkTurnEnd(stateAfterWin), LegOutcome.none, null);
  }

  GameState _applyOverflowScoring(GameState state, String cricketKey,
      int segmentNum, int multiplier, int overflow) {
    final scoring = state.cricketScoring;
    // Scoring value is always 25 per mark for Bull, else the segment number
    final numberValue = segmentNum == 25 ? 25 : segmentNum;

    if (scoring == 'no-score') return state;

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);

    if (scoring == 'standard') {
      // E1: overflow scores for the current player if at least one opponent hasn't closed
      final atLeastOneOpponentOpen = updatedCompetitors.any((c) {
        if (c.competitorId ==
            updatedCompetitors[state.currentTurnIndex].competitorId) {
          return false;
        }
        return (c.marksPerNumber[cricketKey] ?? 0) < 3;
      });

      if (atLeastOneOpponentOpen) {
        final current = updatedCompetitors[state.currentTurnIndex];
        updatedCompetitors[state.currentTurnIndex] =
            current.copyWith(score: current.score + numberValue * overflow);
      }
    } else if (scoring == 'cut-throat') {
      // E2: overflow scores for each opponent who hasn't closed
      final currentCompetitorId =
          updatedCompetitors[state.currentTurnIndex].competitorId;
      for (var i = 0; i < updatedCompetitors.length; i++) {
        final opponent = updatedCompetitors[i];
        if (opponent.competitorId == currentCompetitorId) continue;
        if ((opponent.marksPerNumber[cricketKey] ?? 0) < 3) {
          updatedCompetitors[i] =
              opponent.copyWith(score: opponent.score + numberValue * overflow);
        }
      }
    }

    return state.copyWith(competitors: updatedCompetitors);
  }

  GameState _checkAllClosed(GameState state) {
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final keys = _cricketKeys(state);
    bool changed = false;

    for (var i = 0; i < updatedCompetitors.length; i++) {
      final competitor = updatedCompetitors[i];
      if (competitor.closeOrder != null) continue; // Already closed

      if (_isAllClosed(competitor, keys)) {
        // Calculate close_order as total darts thrown by all competitors
        final totalDarts = updatedCompetitors.fold<int>(
            0, (sum, c) => sum + c.dartThrows.length);
        updatedCompetitors[i] = competitor.copyWith(closeOrder: totalDarts);
        changed = true;
      }
    }

    return changed ? state.copyWith(competitors: updatedCompetitors) : state;
  }

  bool _isAllClosed(CompetitorState competitor, List<String> cricketKeys) {
    return cricketKeys
        .every((n) => (competitor.marksPerNumber[n] ?? 0) >= 3);
  }

  (GameState, LegOutcome, String?) _evaluateWin(GameState state) {
    final scoring = state.cricketScoring;
    final keys = _cricketKeys(state);
    String? winnerId;

    // Collect candidates: competitors who have all closed
    final closedCompetitors =
        state.competitors.where((c) => _isAllClosed(c, keys)).toList();

    if (closedCompetitors.isEmpty) {
      return (state, LegOutcome.none, null);
    }

    if (scoring == 'no-score') {
      // G3: first all-closed player wins
      // Pick lowest closeOrder among those who are all-closed
      closedCompetitors.sort((a, b) =>
          (a.closeOrder ?? 999999).compareTo(b.closeOrder ?? 999999));
      winnerId = closedCompetitors.first.competitorId;
    } else if (scoring == 'standard') {
      // G1: all-closed AND score >= all opponents' scores. When multiple
      // candidates qualify with equal scores (both closed, same score, no
      // strict score winner) the comment used to claim a closeOrder
      // tie-break but the loop walked rotation order — picking whoever
      // happened to appear first in `state.competitors`. Aligns Standard
      // with Cut-Throat / NoScore / Table N: sort candidates by
      // closeOrder ascending so the earliest-closer wins the tie.
      final sortedClosed = [...closedCompetitors]
        ..sort((a, b) =>
            (a.closeOrder ?? 999999).compareTo(b.closeOrder ?? 999999));
      for (final candidate in sortedClosed) {
        final allOpponentsHaveLowerOrEqualScore = state.competitors
            .where((c) => c.competitorId != candidate.competitorId)
            .every((opp) => candidate.score >= opp.score);
        if (allOpponentsHaveLowerOrEqualScore) {
          winnerId = candidate.competitorId;
          break;
        }
      }
    } else if (scoring == 'cut-throat') {
      // G2: all-closed + score <= all opponents' scores
      // Tie-break: earliest closeOrder
      final candidates = closedCompetitors.where((candidate) {
        return state.competitors
            .where((c) => c.competitorId != candidate.competitorId)
            .every((opp) => candidate.score <= opp.score);
      }).toList();

      if (candidates.isNotEmpty) {
        // Tie-break by earliest closeOrder
        candidates.sort((a, b) =>
            (a.closeOrder ?? 999999).compareTo(b.closeOrder ?? 999999));
        winnerId = candidates.first.competitorId;
      }
    }

    if (winnerId == null) {
      return (state, LegOutcome.none, null);
    }

    // Win found — increment legsWon and check game completion
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final winnerIndex =
        updatedCompetitors.indexWhere((c) => c.competitorId == winnerId);
    final winner = updatedCompetitors[winnerIndex];
    updatedCompetitors[winnerIndex] =
        winner.copyWith(legsWon: winner.legsWon + 1);

    final newLegsWon = updatedCompetitors[winnerIndex].legsWon;
    final isGameComplete = newLegsWon >= state.legsToWin;

    if (isGameComplete) {
      final completedState = state.copyWith(
        competitors: updatedCompetitors,
        isComplete: true,
        status: GameEngineStatus.completed,
        winnerCompetitorId: winnerId,
        turnActive: false,
      );
      return (completedState, LegOutcome.gameCompleted, winnerId);
    } else {
      final stateBeforeReset = state.copyWith(
        competitors: updatedCompetitors,
        currentLegIndex: state.currentLegIndex + 1,
        turnActive: false,
        winnerCompetitorId: winnerId,
      );
      final resetState = _resetLeg(stateBeforeReset);
      return (resetState, LegOutcome.legCompleted, winnerId);
    }
  }

  GameState _checkTurnEnd(GameState state) {
    if (state.dartsThrownInTurn >= 3) {
      return state.copyWith(turnActive: false);
    }
    return state;
  }

  EngineResult _applyTurnEnded(GameState state, GameEvent event) {
    final nextIndex = (state.currentTurnIndex + 1) % state.competitors.length;
    final rotated = state.copyWith(
      dartsThrownInTurn: 0,
      turnActive: false,
      currentTurnIndex: nextIndex,
    );

    final cap = state.cricketTotalRounds;
    final wasLastCompetitorOfRound =
        state.currentTurnIndex == state.competitors.length - 1;
    final capReached = cap != null &&
        state.currentRoundInLeg >= cap &&
        wasLastCompetitorOfRound;

    if (!capReached) {
      return EngineResult(state: rotated);
    }

    return _resolveRoundCap(state);
  }

  EngineResult _resolveRoundCap(GameState state) {
    final winnerId = _selectCricketCapWinner(state);
    final isSinglePlayer = state.competitors.length == 1;

    if (winnerId == null && !isSinglePlayer) {
      return EngineResult(
        state: state.copyWith(turnActive: false),
        outcome: LegOutcome.roundCapReached,
      );
    }

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    var newWinnerLegsWon = 0;
    if (winnerId != null) {
      final idx =
          updatedCompetitors.indexWhere((c) => c.competitorId == winnerId);
      if (idx >= 0) {
        final w = updatedCompetitors[idx];
        newWinnerLegsWon = w.legsWon + 1;
        updatedCompetitors[idx] = w.copyWith(legsWon: newWinnerLegsWon);
      }
    }

    final gameComplete =
        isSinglePlayer || newWinnerLegsWon >= state.legsToWin;

    if (gameComplete) {
      return EngineResult(
        state: state.copyWith(
          competitors: updatedCompetitors,
          isComplete: true,
          status: GameEngineStatus.completed,
          turnActive: false,
          winnerCompetitorId: winnerId,
        ),
        outcome: LegOutcome.gameCompleted,
        winnerCompetitorId: winnerId,
      );
    }

    final stateBeforeReset = state.copyWith(
      competitors: updatedCompetitors,
      currentLegIndex: state.currentLegIndex + 1,
      turnActive: false,
      winnerCompetitorId: winnerId,
    );
    return EngineResult(
      state: _resetLeg(stateBeforeReset),
      outcome: LegOutcome.legCompleted,
      winnerCompetitorId: winnerId,
    );
  }

  /// Per-variant cap winner: highest (standard), lowest (cut-throat), or most
  /// marks (no-score). Primary-metric ties break by earliest [closeOrder];
  /// null is earlier than null → unresolvable tie returns null for manual pick.
  String? _selectCricketCapWinner(GameState state) {
    if (state.competitors.length < 2) return null;
    final scoring = state.cricketScoring;
    final keys = _cricketKeys(state);

    int Function(CompetitorState) metric;
    bool higherWins;
    switch (scoring) {
      case 'cut-throat':
        metric = (c) => c.score;
        higherWins = false;
        break;
      case 'no-score':
        metric = (c) =>
            keys.fold<int>(0, (s, n) => s + (c.marksPerNumber[n] ?? 0));
        higherWins = true;
        break;
      case 'standard':
      default:
        metric = (c) => c.score;
        higherWins = true;
        break;
    }

    int bestMetric = metric(state.competitors.first);
    final tied = <CompetitorState>[state.competitors.first];
    for (var i = 1; i < state.competitors.length; i++) {
      final c = state.competitors[i];
      final m = metric(c);
      final beats = higherWins ? m > bestMetric : m < bestMetric;
      if (beats) {
        bestMetric = m;
        tied
          ..clear()
          ..add(c);
      } else if (m == bestMetric) {
        tied.add(c);
      }
    }
    if (tied.length == 1) return tied.first.competitorId;

    CompetitorState? earliest;
    var earliestTied = false;
    for (final c in tied) {
      if (c.closeOrder == null) continue;
      if (earliest == null || c.closeOrder! < earliest.closeOrder!) {
        earliest = c;
        earliestTied = false;
      } else if (c.closeOrder == earliest.closeOrder) {
        earliestTied = true;
      }
    }
    if (earliest == null || earliestTied) return null;
    return earliest.competitorId;
  }

  EngineResult _applyLegCompleted(GameState state, GameEvent event) {
    final legWinnerId = event.payload['winner_competitor_id'] as String;

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final winnerIndex =
        updatedCompetitors.indexWhere((c) => c.competitorId == legWinnerId);

    if (winnerIndex >= 0) {
      final winner = updatedCompetitors[winnerIndex];
      updatedCompetitors[winnerIndex] =
          winner.copyWith(legsWon: winner.legsWon + 1);
    }

    final winner = updatedCompetitors
        .firstWhere((c) => c.competitorId == legWinnerId);
    if (winner.legsWon >= state.legsToWin) {
      final newState = state.copyWith(
        competitors: updatedCompetitors,
        isComplete: true,
        status: GameEngineStatus.completed,
        turnActive: false,
        winnerCompetitorId: legWinnerId,
      );
      return EngineResult(
          state: newState,
          outcome: LegOutcome.gameCompleted,
          winnerCompetitorId: legWinnerId);
    } else {
      final newState = _resetLeg(state.copyWith(
        competitors: updatedCompetitors,
        currentLegIndex: state.currentLegIndex + 1,
        turnActive: false,
      ));
      return EngineResult(state: newState);
    }
  }

  /// Table L — Reset leg state for next leg
  GameState _resetLeg(GameState state) {
    final resetCompetitors = state.competitors.map((competitor) {
      return competitor.copyWith(
        score: 0,
        marksPerNumber: const {},
        closeOrder: null,
        dartThrows: const [],
        isComplete: false,
        turnStartScore: null,
      );
    }).toList();

    return state.copyWith(
      competitors: resetCompetitors,
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      turnActive: false,
      winnerCompetitorId: null,
      currentRoundInLeg: 1,
    );
  }

  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_competitor_id'] as String? ?? event.payload['winner_id'] as String?,
      turnActive: false,
    );
  }

}
