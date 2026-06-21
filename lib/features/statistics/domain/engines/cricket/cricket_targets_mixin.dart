import 'package:dart_lodge/core/utils/cricket_segment_utils.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/cricket/cricket_closure_tracker.dart';

/// Tracks the active cricket target set for a projection by consuming
/// `CricketTargetsAssigned` events.
///
/// For fixed-mode games (no `CricketTargetsAssigned` ever emitted) the
/// set stays at the canonical [kCricketTargets]. For Random Cricket the
/// event lands once right after `GameCreated` and replaces the set with
/// the assigned 6 numbers plus the implicit Bull (25).
///
/// Cricket projections that read marks via [cricketMarksFromPayload] /
/// [isCricketTargetNumeric] mix this in and pass [activeCricketTargets]
/// as the `targets:` override so Random Cricket hits on the assigned
/// numbers count (and stale 15–20 hits do not). See
/// `docs/plans/2026-05-19-cricket-target-modes-design.md` §6.
mixin CricketTargetsTracker {
  Set<int> _activeTargets = kCricketTargets;

  /// Forward per-competitor closure state for dead-number mark suppression
  /// (#638). Mark-counting projections credit a dart's marks via
  /// [cricketScopedMarksForDart], which records every competitor's hit here and
  /// returns 0 for a hit on a number already closed by all.
  final CricketClosureTracker _closure = CricketClosureTracker();

  /// The cricket target set currently in effect.
  /// Mixers must pass this to mark-counting helpers.
  Set<int> get activeCricketTargets => _activeTargets;

  /// Call from the mixer's `init()` to reset back to the canonical set
  /// (the runner builds a fresh projection per game).
  void resetCricketTargets() {
    _activeTargets = kCricketTargets;
    _closure.reset();
  }

  /// Seed the closure roster for slices that carry no `GameCreated` event
  /// (e.g. a per-leg slice after leg 1). A `GameCreated`, when present,
  /// overrides this with the authoritative competitor list.
  void seedCricketRoster(Iterable<String> competitorIds) {
    _closure.seedRoster(competitorIds);
  }

  /// Call from the mixer's `reset(ProjectionScope.leg)` so the closure board
  /// resets each leg, mirroring the engine's per-leg mark reset.
  void resetCricketClosureForLeg() {
    _closure.onLegReset();
  }

  /// Dead-number-aware marks for one `DartThrown`, scoped to [scopedPlayerId].
  /// Records the thrower's hit (keeping the accumulator complete) and returns
  /// the marks to credit toward the scoped player (0 for non-targets, other
  /// players, or hits on a dead number). See [scopedCricketMarksForDart].
  int cricketScopedMarksForDart(GameEvent event, String? scopedPlayerId) {
    return scopedCricketMarksForDart(
      payload: event.payload,
      closure: _closure,
      activeTargets: _activeTargets,
      scopedPlayerId: scopedPlayerId,
    );
  }

  /// Returns `true` when [event] handles a target-set lifecycle event:
  /// `GameCreated` resets to the canonical fixed set; `CricketTargetsAssigned`
  /// replaces it with the random set; `CrazyTargetsRolled` replaces it
  /// with the per-turn open targets. Mixers should early-return when this
  /// returns true so their own switch doesn't double-handle the event.
  ///
  /// Resetting on `GameCreated` keeps career replay correct across game
  /// boundaries: a random/crazy game's emitted target events would
  /// otherwise leak their target set into the next fixed game (which
  /// emits no such event) and silently distort that game's mark counts.
  ///
  /// For Crazy Cricket the target set rotates **every turn**; cumulative
  /// marks can decrease across turns via discard-on-rotate. Projections
  /// that count marks must do so from `DartThrown` payloads within a
  /// turn (turn-scoped, additive) — never from cross-turn board-state
  /// diffs — to stay correct under discard. See
  /// `docs/statistics/statistics.architecture.md` §7.3.
  bool maybeApplyCricketTargets(GameEvent event) {
    if (event.eventType == 'GameCreated') {
      _activeTargets = kCricketTargets;
      // Capture the authoritative competitor roster + reset the closure board
      // for dead-number detection (#638).
      _closure.onGameCreated(event.payload['competitors']);
      return true;
    }
    if (event.eventType == 'CricketTargetsAssigned') {
      final raw = event.payload['targets'] as List<dynamic>;
      _activeTargets = {
        for (final t in raw) (t as num).toInt(),
        25, // Bull is implicit; always a 7th target.
      };
      return true;
    }
    if (event.eventType == 'CrazyTargetsRolled') {
      final raw = event.payload['open_targets'] as List<dynamic>;
      _activeTargets = {
        for (final t in raw) (t as num).toInt(),
        25,
      };
      // Wipe non-locked closure marks, mirroring the engine's discard-on-rotate
      // so dead-number detection stays correct under Crazy Cricket (#638).
      _closure.onCrazyRoll();
      return true;
    }
    return false;
  }
}
