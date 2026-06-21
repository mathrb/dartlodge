import 'package:dart_lodge/core/utils/cricket_segment_utils.dart';
import 'package:dart_lodge/features/statistics/domain/engines/segment_utils.dart';

/// Forward, per-competitor cricket closure tracker for dead-number detection
/// (#638).
///
/// A cricket number is **dead** once EVERY competitor has closed it (≥3 marks).
/// A hit on a dead number generates **0 marks** (it only yields points, or
/// nothing under no-score) — matching the standard / electronic-machine MPR
/// convention. Overflow on a number still live for at least one competitor
/// keeps counting.
///
/// Closure is reconstructed **forward** from `DartThrown` events within the
/// same single replay pass — never from a cross-turn diff of board snapshots —
/// so it stays consistent with `docs/statistics/statistics.architecture.md`
/// §7.3 and survives Crazy Cricket discard-on-rotate: non-locked numbers have
/// their marks wiped on every roll, exactly mirroring
/// `StatelessCricketEngine._applyCrazyTargetsRolled`. Closing logic (≥3 marks,
/// lock-on-close, clamp-to-3) mirrors `StatelessCricketEngine._applyDartThrown`
/// and `_isAllClosed`. "Closed by all" is keyed on `competitor_id` (the engine's
/// closing unit), and includes the thrower.
class CricketClosureTracker {
  final Set<String> _roster = {};
  final Map<String, Map<String, int>> _marks = {};
  final Set<int> _locked = {};

  /// Full reset (call from the projection's `init`).
  void reset() {
    _roster.clear();
    _marks.clear();
    _locked.clear();
  }

  /// Seed the competitor roster explicitly, for event slices that do NOT carry
  /// a `GameCreated` event (e.g. a per-leg slice after leg 1). When a
  /// `GameCreated` IS present, [onGameCreated] overrides this with the
  /// authoritative list.
  void seedRoster(Iterable<String> competitorIds) {
    _roster
      ..clear()
      ..addAll(competitorIds);
  }

  /// `GameCreated`: capture the authoritative roster from the payload's
  /// `competitors` list and reset the board.
  void onGameCreated(Object? competitors) {
    if (competitors is List) {
      _roster
        ..clear()
        ..addAll(competitors.map((e) => e.toString()));
    }
    _marks.clear();
    _locked.clear();
  }

  /// Per-leg board reset (the engine resets marks + locks each leg).
  void onLegReset() {
    _marks.clear();
    _locked.clear();
  }

  /// `CrazyTargetsRolled`: wipe every non-locked, non-Bull number's marks for
  /// all competitors — mirrors `StatelessCricketEngine._applyCrazyTargetsRolled`.
  void onCrazyRoll() {
    final lockedKeys = <String>{for (final n in _locked) n.toString(), 'Bull'};
    for (final m in _marks.values) {
      m.removeWhere((k, _) => !lockedKeys.contains(k));
    }
  }

  String _key(int segment) => segment == 25 ? 'Bull' : segment.toString();

  /// Whether [segment] is closed by EVERY competitor (dead) — evaluated against
  /// the current (pre-throw) accumulator. Returns false when the roster is
  /// unknown (never suppress without authority).
  bool isDead(int segment) {
    if (_roster.isEmpty) return false;
    final key = _key(segment);
    return _roster.every((c) => (_marks[c]?[key] ?? 0) >= 3);
  }

  /// Record a hit by [competitorId] on [segment] (× [multiplier]). Mirrors the
  /// engine's clamp-to-3 and crazy lock-on-close.
  void recordHit(String? competitorId, int segment, int multiplier) {
    if (competitorId == null) return;
    final key = _key(segment);
    final m = _marks.putIfAbsent(competitorId, () => {});
    final next = ((m[key] ?? 0) + multiplier).clamp(0, 3);
    m[key] = next;
    if (next >= 3 && segment != 25) _locked.add(segment);
  }
}

/// Dead-number-aware mark credit for one `DartThrown`, scoped to
/// [scopedPlayerId] (#638).
///
/// Records the thrower's hit into [closure] (so later darts see the correct
/// closure state) and returns the marks to credit toward the scoped player's
/// MPR: 0 for a non-target, 0 for another player's dart, 0 for a hit on a
/// **dead** number (closed by all), else the cricket marks. Dead-ness is
/// evaluated BEFORE recording, so the dart that closes a number for the last
/// remaining competitor still counts (it was live at throw time).
///
/// Call this for EVERY `DartThrown` (not just the scoped player's) so the
/// closure accumulator stays complete across all competitors.
int scopedCricketMarksForDart({
  required Map<String, dynamic> payload,
  required CricketClosureTracker closure,
  required Set<int> activeTargets,
  required String? scopedPlayerId,
}) {
  final s = readSegmentFromPayload(payload);
  // Non-targets never close and never score marks.
  if (!isCricketTargetNumeric(s.segment, targets: activeTargets)) return 0;
  final dead = closure.isDead(s.segment);
  closure.recordHit(payload['competitor_id'] as String?, s.segment, s.multiplier);
  if ((payload['player_id'] as String?) != scopedPlayerId) return 0;
  return dead
      ? 0
      : cricketMarksFromPayload(s.segment, s.multiplier, targets: activeTargets);
}
