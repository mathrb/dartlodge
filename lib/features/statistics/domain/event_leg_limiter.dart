// EventLegLimiter
// Trims an event list to the last N completed legs.
//
// Used by repository implementations before delegating to PlayerStatsAssembler.
// Lives in domain/ so both backends can share the implementation; the trim
// logic is pure event-list processing with no DB or Flutter dependency.

import 'package:dart_lodge/features/game/domain/engines/event_replay.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

class EventLegLimiter {
  const EventLegLimiter._();

  /// Returns [events] trimmed to the last [legLimit] completed legs.
  ///
  /// Returns [events] unchanged if [legLimit] is null, ≤ 0, or if the input
  /// contains no more than [legLimit] completed legs. A trimmed result has the
  /// events superseded by an undo removed (see [stripSupersededEvents]).
  ///
  /// A leg closes on `LegCompleted`. Practice drills end with `GameCompleted`
  /// alone (their engines never advance the leg index), so when
  /// [closeLegOnGameCompleted] is true a `GameCompleted` also closes the open
  /// leg, unless that leg was already closed by a `LegCompleted` (so it is
  /// never counted twice). This mirrors
  /// `PlayerStatsAssembler.legHistoryFromEvents`, which feeds the trend chart.
  ///
  /// When the cut falls on the last leg of a game, that game's trailing
  /// `GameCompleted` is dropped too: it belongs to no leg in the window and
  /// would otherwise count the game in game-level projections (win rate).
  ///
  /// Caller MUST pass events in chronological game order (oldest game first)
  /// with each game's events contiguous and sorted by `local_sequence` — the
  /// trim keeps the events after a global index, so "last N" is only "most
  /// recent N" when the games are ordered by when they were played.
  static List<GameEvent> trim(
    List<GameEvent> events,
    int? legLimit, {
    bool closeLegOnGameCompleted = false,
  }) {
    if (legLimit == null || legLimit <= 0) return events;

    // A `LegCompleted` superseded by an undo (the leg-winning dart was taken
    // back) closes no leg, so count and cut on the surviving events.
    final live = stripSupersededEvents(events);

    final legEndIndices = <int>[];
    // True while the current game has an open (not yet closed) leg.
    bool legOpen = false;
    String? currentGameId;
    for (int i = 0; i < live.length; i++) {
      final e = live[i];
      if (e.gameId != currentGameId) {
        currentGameId = e.gameId;
        legOpen = false;
      }
      if (e.eventType == 'LegCompleted') {
        legEndIndices.add(i);
        legOpen = false;
      } else if (e.eventType == 'GameCompleted') {
        if (closeLegOnGameCompleted && legOpen) legEndIndices.add(i);
        legOpen = false;
      } else {
        legOpen = true;
      }
    }
    if (legEndIndices.length <= legLimit) return events;

    // Slice from the event after the (N - legLimit)th leg end, skipping the
    // cut game's trailing GameCompleted.
    final cutIdx = legEndIndices[legEndIndices.length - legLimit - 1];
    final cutGameId = live[cutIdx].gameId;
    var start = cutIdx + 1;
    while (start < live.length &&
        live[start].gameId == cutGameId &&
        live[start].eventType == 'GameCompleted') {
      start++;
    }
    return live.sublist(start);
  }
}
