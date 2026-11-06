// Event replay — pure helper that takes an initial GameState plus the
// recorded event log and returns the final GameState after engine application.
//
// `stripSupersededEvents` (below) is the single source of truth for
// DartCorrected / superseded-event skip handling, so every replay-aware call
// site (cold loaders for active-game notifiers, post-game `GetGameResultUseCase`,
// the stats assembler, the history turn-breakdown builder) recovers identical
// results from the same events.

import '../../../../core/utils/constants.dart';
import '../entities/game_event.dart';
import '../models/game_state.dart';
import 'base_game_engine.dart';

/// Game types whose engines fold leg/game completion into the deciding
/// `DartThrown` (and round-cap `TurnEnded`) AND separately persist
/// `LegCompleted`/`GameCompleted`. Re-applying those persisted events during
/// replay double-counts `legsWon` and `currentLegIndex` (#663), so the shared
/// replay skips them. Practice/round-based engines (ATC,
/// Shanghai, Catch 40, Count Up) instead RELY on `LegCompleted` to increment
/// `legsWon`, so they are deliberately absent.
///
/// One exception: a round cap that ends in a tie. `TurnEnded`→`_resolveRoundCap`
/// then returns [LegOutcome.roundCapReached] and leaves the leg open; the
/// `LegCompleted` persisted by `selectCapWinner` is the only record of the
/// user's pick, so it IS applied (#111). A cap with a clear winner is resolved
/// by the `TurnEnded` itself, so its persisted `LegCompleted` stays skipped.
///
/// `UndoLastDartUseCase` replays these game types through this function too,
/// so undo and cold load share one replay path.
const _foldsLegCompletionIntoTurn = {GameType.x01, GameType.cricket};

/// Whether [replayEvents] treats [gameType] as folding leg/game completion
/// into the turn (see `_foldsLegCompletionIntoTurn`).
bool foldsLegCompletionIntoTurn(GameType gameType) =>
    _foldsLegCompletionIntoTurn.contains(gameType);

GameState replayEvents({
  required GameState initial,
  required List<GameEvent> events,
  required GameEngine engine,
}) {
  final skipLegEvents = _foldsLegCompletionIntoTurn.contains(initial.gameType);
  var gs = initial;
  // True between a `TurnEnded` that hit a tied round cap and the
  // `LegCompleted` that records the user's pick.
  var capPending = false;
  for (final event in stripSupersededEvents(events)) {
    if (skipLegEvents) {
      if (event.eventType == 'GameCompleted') continue;
      if (event.eventType == 'LegCompleted') {
        if (!capPending) continue;
        capPending = false;
      }
    }
    final result = engine.apply(gs, event);
    gs = result.state;
    if (event.eventType == 'TurnEnded') {
      capPending = result.outcome == LegOutcome.roundCapReached;
    }
  }
  return gs;
}

/// Removes the events that a `DartCorrected` supersedes, returning a stream
/// safe to fold through an engine or scan for display. Two skip flavours:
///
///   * `original_event_id` — the corrected `DartThrown`; dropped so consumers
///     see only the replacement dart (#187).
///   * `superseded_event_ids` — the turn-boundary events (TurnStarted /
///     TurnEnded) that bracketed a cross-turn undo. Replaying a stale
///     TurnStarted shifts `currentTurnIndex` so later darts land on the wrong
///     competitor (#108); a stale TurnEnded inflates per-turn projection
///     denominators (#321).
///
/// This is the single source of truth for DartCorrected skip handling. Every
/// replay-aware path MUST funnel raw events through it: cold-load replay
/// (above), the stats assembler, and the history turn-breakdown builder.
/// Returns [events] unchanged (same instance) when nothing is superseded.
List<GameEvent> stripSupersededEvents(List<GameEvent> events) {
  final correctedDartIds = <String>{};
  final supersededEventIds = <String>{};
  for (final e in events) {
    if (e.eventType != 'DartCorrected') continue;
    final origId = e.payload['original_event_id'];
    if (origId is String) correctedDartIds.add(origId);
    final superseded = e.payload['superseded_event_ids'];
    if (superseded is List) {
      for (final id in superseded) {
        if (id is String) supersededEventIds.add(id);
      }
    }
  }
  if (correctedDartIds.isEmpty && supersededEventIds.isEmpty) return events;
  return events.where((e) {
    if (e.eventType == 'DartThrown' && correctedDartIds.contains(e.eventId)) {
      return false;
    }
    return !supersededEventIds.contains(e.eventId);
  }).toList();
}
