// GetGameResultUseCase — produces the post-game `GameResult` for the four
// practice drills (Around the Clock, Catch 40, Bob's 27, 170 Checkout) and
// Shanghai by replaying recorded `game_events` through the existing engine
// for that game type. Count-Up is intentionally NOT covered — it stays on
// the shared `gameStatsProvider` (x01-shaped chrome fits it).
//
// No new scoring math: every field comes from the final `CompetitorState` /
// `GameState` that the engine produces, with three exceptions that observe
// engine output rather than recompute it —
//   - `CheckoutPracticeResult.dartsThrown` counts surviving `DartThrown`
//     events directly (the checkout engine pads bust turns with phantom
//     `MISS` darts, so `dartThrows.length` over-counts).
//   - `CheckoutPracticeResult.attempts` counts surviving `TurnStarted`
//     events for the subject (each turn is one attempt at the checkout).
//     `practiceSuccesses` on the final state already tracks successes;
//     attempts has no engine-maintained counterpart.
//   - `ShanghaiResult.bestRound` walks events a second time and accumulates
//     per-round score deltas off the engine's score field between
//     `TurnEnded` boundaries.

import 'dart:math' as math;

import '../engines/base_game_engine.dart';
import '../engines/event_replay.dart';
import '../engines/stateless_around_the_clock_engine.dart';
import '../engines/stateless_bobs_27_engine.dart';
import '../engines/stateless_catch_40_engine.dart';
import '../engines/stateless_checkout_practice_engine.dart';
import '../engines/stateless_shanghai_engine.dart';
import '../entities/game_event.dart';
import '../models/game_result.dart';
import '../models/game_state.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/game_repository.dart';
import '../../../../core/utils/constants.dart';

class GetGameResultUseCase {
  final GameRepository _gameRepo;
  final GameEventRepository _eventRepo;
  final StatelessAroundTheClockEngine _aroundTheClockEngine;
  final StatelessCatch40Engine _catch40Engine;
  final StatelessBobs27Engine _bobs27Engine;
  final StatelessShanghaiEngine _shanghaiEngine;
  final StatelessCheckoutPracticeEngine _checkoutPracticeEngine;

  GetGameResultUseCase(
    this._gameRepo,
    this._eventRepo,
    this._aroundTheClockEngine,
    this._catch40Engine,
    this._bobs27Engine,
    this._shanghaiEngine,
    this._checkoutPracticeEngine,
  );

  /// Returns the post-game `GameResult` for [gameId], or `null` when the game
  /// is missing or its `GameType` is not one of the practice/Shanghai variants
  /// `GameResult` represents.
  Future<GameResult?> execute(String gameId) async {
    final game = await _gameRepo.getGame(gameId);
    if (game == null) return null;

    final engine = _engineFor(game.gameType);
    if (engine == null) return null;

    final competitors = await _gameRepo.getCompetitors(gameId);
    final events = await _eventRepo.getEventsForGame(gameId);

    // Override `isComplete: false` for replay: `GameState.initial` copies
    // `game.isComplete` from the DB row (true for the completed games this
    // use case is called on), which would cause the Shanghai and Catch-40
    // engines — both of which short-circuit `apply` when `state.isComplete`
    // — to skip every event. Recover completion from the event log instead.
    final initial =
        GameState.initial(game, competitors).copyWith(isComplete: false);
    final finalState =
        replayEvents(initial: initial, events: events, engine: engine);

    if (finalState.competitors.isEmpty) return null;

    return switch (game.gameType) {
      GameType.aroundTheClock => GameResult.aroundTheClock(
          competitors: _buildAtcCompetitors(finalState, events),
          winnerCompetitorId: finalState.winnerCompetitorId,
          doublesOnly: finalState.aroundTheClockVariant == 'doublesOnly',
        ),
      GameType.shanghai => GameResult.shanghai(
          competitors: _buildShanghaiCompetitors(
            initial: initial,
            finalState: finalState,
            events: events,
            engine: engine,
          ),
          winnerCompetitorId: finalState.winnerCompetitorId,
          totalRounds: finalState.shanghaiTotalRounds,
        ),
      // Solo drills (maxPlayers == 1): keep the single-subject result shape.
      GameType.catch40 ||
      GameType.bobs27 ||
      GameType.checkoutPractice =>
        _buildSoloResult(game.gameType, finalState, events),
      _ => null,
    };
  }

  GameResult? _buildSoloResult(
    GameType gameType,
    GameState finalState,
    List<GameEvent> events,
  ) {
    final subject = _subjectCompetitor(finalState);
    if (subject == null) return null;
    return switch (gameType) {
      GameType.catch40 => GameResult.catch40(
          competitorName: subject.name,
          score: subject.score,
          targetsCleared: subject.practiceSuccesses,
        ),
      GameType.bobs27 => GameResult.bobs27(
          competitorName: subject.name,
          finalScore: subject.score,
          // practiceRound is bumped after a round's 3rd dart finalises that
          // round's scoring, so `practiceRound - 1` is the last round
          // actually played (1..20).
          roundReached: math.max(1, subject.practiceRound - 1).clamp(1, 20),
          bustedToZero: subject.score <= 0,
        ),
      GameType.checkoutPractice => GameResult.checkoutPractice(
          competitorName: subject.name,
          attempts: _countTurnStarted(events, subject.competitorId),
          successes: subject.practiceSuccesses,
          dartsThrown: _countDarts(events, subject.competitorId),
          fromScore: subject.startingScore,
        ),
      _ => null,
    };
  }

  /// ATC per-competitor results, ordered for the podium: finishers first
  /// (fewer turns wins ties), then non-finishers ranked by closeness to
  /// the variant's goal.
  ///
  /// The ATC engine flips `CompetitorState.isComplete = true` when a player
  /// hits the final target but does NOT advance `currentTarget` past the
  /// end of the range — so the per-competitor `isComplete` flag is the
  /// authoritative "finished" signal. `lastTargetHit` is derived from the
  /// next target and the variant direction.
  List<AtcCompetitorResult> _buildAtcCompetitors(
    GameState finalState,
    List<GameEvent> events,
  ) {
    final isReverse = finalState.aroundTheClockVariant == 'reverse';
    final results = finalState.competitors.map((c) {
      final finished = c.isComplete;
      final nextTarget = c.currentTarget;
      final int lastHit;
      if (finished) {
        // Engine doesn't push `currentTarget` past the final value; the
        // final target IS the last hit.
        lastHit = isReverse ? 1 : 20;
      } else if (nextTarget == null) {
        // No ATC state set yet (defensive — should never happen for ATC).
        // Use 0 in both directions so the UI shows "nothing hit" rather
        // than a sentinel like 21.
        lastHit = 0;
      } else {
        // Standard: lastHit = next - 1 (0 if no hits yet).
        // Reverse: lastHit = next + 1, except when nothing has been hit
        // (nextTarget == 20, the starting target) — clamp to 0 so the UI
        // shows "nothing hit" rather than 21, which isn't a valid ATC
        // target.
        if (isReverse) {
          lastHit = nextTarget == 20 ? 0 : nextTarget + 1;
        } else {
          lastHit = nextTarget - 1;
        }
      }
      return AtcCompetitorResult(
        competitorId: c.competitorId,
        competitorName: c.name,
        turnsCompleted: c.practiceRound,
        totalDarts: _countDarts(events, c.competitorId),
        lastTargetHit: lastHit,
        finished: finished,
      );
    }).toList();

    // Order: finished above unfinished; ties broken by fewer turns / fewer
    // darts (finished group). Non-finishers ranked by hit count — derive
    // it from lastTargetHit (standard: count == lastHit; reverse: count
    // == 21 - lastHit when > 0). 0 always means "no hits" and sorts last.
    int hitCount(AtcCompetitorResult r) {
      if (r.lastTargetHit == 0) return 0;
      return isReverse ? 21 - r.lastTargetHit : r.lastTargetHit;
    }
    results.sort((a, b) {
      if (a.finished != b.finished) return a.finished ? -1 : 1;
      if (a.finished) {
        final byTurns = a.turnsCompleted.compareTo(b.turnsCompleted);
        if (byTurns != 0) return byTurns;
        return a.totalDarts.compareTo(b.totalDarts);
      }
      return hitCount(b).compareTo(hitCount(a));
    });
    return results;
  }

  /// Shanghai per-competitor results, ordered for the podium by
  /// `(totalScore desc, shanghaiBonuses desc, bestRound desc)`.
  List<ShanghaiCompetitorResult> _buildShanghaiCompetitors({
    required GameState initial,
    required GameState finalState,
    required List<GameEvent> events,
    required GameEngine engine,
  }) {
    final results = finalState.competitors.map((c) {
      return ShanghaiCompetitorResult(
        competitorId: c.competitorId,
        competitorName: c.name,
        totalScore: c.score,
        shanghaiBonuses: c.practiceSuccesses,
        bestRound: _bestRoundScore(
          initial: initial,
          events: events,
          engine: engine,
          competitorId: c.competitorId,
        ),
        // Count TurnStarted events for this competitor (one per round
        // they participated in). `practiceRound` is bumped at TurnEnded
        // time, which inflates the count by 1 for the player whose turn
        // finished just before another player ended the game via Shanghai
        // (#323). Clamp at the configured cap for completeness.
        roundsPlayed: math.min(
          _countTurnStarted(events, c.competitorId),
          finalState.shanghaiTotalRounds,
        ),
      );
    }).toList();

    results.sort((a, b) {
      final byScore = b.totalScore.compareTo(a.totalScore);
      if (byScore != 0) return byScore;
      final byShanghais = b.shanghaiBonuses.compareTo(a.shanghaiBonuses);
      if (byShanghais != 0) return byShanghais;
      return b.bestRound.compareTo(a.bestRound);
    });
    return results;
  }

  GameEngine? _engineFor(GameType type) => switch (type) {
        GameType.aroundTheClock => _aroundTheClockEngine,
        GameType.catch40 => _catch40Engine,
        GameType.bobs27 => _bobs27Engine,
        GameType.shanghai => _shanghaiEngine,
        GameType.checkoutPractice => _checkoutPracticeEngine,
        _ => null,
      };

  /// The competitor whose result the post-game screen displays — the winner
  /// if the engine recorded one, otherwise the first competitor (covers
  /// solo drills like Bob's 27 where `winnerCompetitorId` is intentionally
  /// null even on completion).
  CompetitorState? _subjectCompetitor(GameState state) {
    if (state.competitors.isEmpty) return null;
    final winnerId = state.winnerCompetitorId;
    if (winnerId != null) {
      final match = state.competitors
          .where((c) => c.competitorId == winnerId)
          .firstOrNull;
      if (match != null) return match;
    }
    return state.competitors.first;
  }

  /// Counts the surviving `DartThrown` events for [competitorId], applying
  /// the same DartCorrected / superseded skip handling as `replayEvents`.
  /// Authoritative for "darts the user actually threw" — distinct from
  /// `CompetitorState.dartThrows.length`, which can include phantom MISS
  /// padding the checkout-practice engine inserts on bust.
  int _countDarts(List<GameEvent> events, String competitorId) {
    final skip = _buildSkipSets(events);
    var count = 0;
    for (final e in events) {
      if (e.eventType != 'DartThrown') continue;
      if (skip.correctedDartIds.contains(e.eventId)) continue;
      if (skip.supersededEventIds.contains(e.eventId)) continue;
      if (e.payload['competitor_id'] != competitorId) continue;
      count++;
    }
    return count;
  }

  /// Counts the surviving `TurnStarted` events for [competitorId]. Each
  /// turn is one checkout attempt — TurnStarted is more reliable than
  /// TurnEnded because End Drill mid-attempt skips the closing TurnEnded
  /// while TurnStarted was already recorded when the attempt began.
  int _countTurnStarted(List<GameEvent> events, String competitorId) {
    final skip = _buildSkipSets(events);
    var count = 0;
    for (final e in events) {
      if (e.eventType != 'TurnStarted') continue;
      if (skip.supersededEventIds.contains(e.eventId)) continue;
      if (e.payload['competitor_id'] != competitorId) continue;
      count++;
    }
    return count;
  }

  /// Highest single-round score the [competitorId] accumulated in Shanghai.
  /// Observes the engine's score deltas between `TurnEnded` boundaries for
  /// that competitor; does not recompute scoring.
  int _bestRoundScore({
    required GameState initial,
    required List<GameEvent> events,
    required GameEngine engine,
    required String competitorId,
  }) {
    final skip = _buildSkipSets(events);

    int compIndex(GameState gs) =>
        gs.competitors.indexWhere((c) => c.competitorId == competitorId);

    var gs = initial;
    var idx = compIndex(gs);
    if (idx < 0) return 0;
    var prevScore = gs.competitors[idx].score;
    var currentRoundScore = 0;
    var best = 0;

    for (final event in events) {
      if (event.eventType == 'DartThrown' &&
          skip.correctedDartIds.contains(event.eventId)) {
        continue;
      }
      if (skip.supersededEventIds.contains(event.eventId)) continue;

      // Close out the round just before applying TurnEnded for this
      // competitor, so the round's score deltas are correctly bucketed.
      if (event.eventType == 'TurnEnded' &&
          event.payload['competitor_id'] == competitorId) {
        best = math.max(best, currentRoundScore);
        currentRoundScore = 0;
      }

      gs = engine.apply(gs, event).state;
      idx = compIndex(gs);
      if (idx < 0) continue;
      final cur = gs.competitors[idx].score;
      if (cur > prevScore) currentRoundScore += (cur - prevScore);
      prevScore = cur;
    }

    // The final round (and any Shanghai-instant-win round) ends without a
    // matching TurnEnded — flush whatever's accumulated.
    best = math.max(best, currentRoundScore);
    return best;
  }

  _SkipSets _buildSkipSets(List<GameEvent> events) {
    final corrected = <String>{};
    final superseded = <String>{};
    for (final e in events) {
      if (e.eventType != 'DartCorrected') continue;
      final origId = e.payload['original_event_id'];
      if (origId is String) corrected.add(origId);
      final list = e.payload['superseded_event_ids'];
      if (list is List) {
        for (final id in list) {
          if (id is String) superseded.add(id);
        }
      }
    }
    return _SkipSets(corrected, superseded);
  }
}

class _SkipSets {
  final Set<String> correctedDartIds;
  final Set<String> supersededEventIds;
  const _SkipSets(this.correctedDartIds, this.supersededEventIds);
}
