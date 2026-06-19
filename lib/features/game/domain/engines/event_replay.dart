// Event replay — pure helper that takes an initial GameState plus the
// recorded event log and returns the final GameState after engine application.
//
// `stripSupersededEvents` (below) is the single source of truth for
// DartCorrected / superseded-event skip handling, so every replay-aware call
// site (cold loaders for active-game notifiers, post-game `GetGameResultUseCase`,
// the stats assembler, the history turn-breakdown builder) recovers identical
// results from the same events.

import '../entities/game_event.dart';
import '../models/game_state.dart';
import 'base_game_engine.dart';

GameState replayEvents({
  required GameState initial,
  required List<GameEvent> events,
  required GameEngine engine,
}) {
  var gs = initial;
  for (final event in stripSupersededEvents(events)) {
    gs = engine.apply(gs, event).state;
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
