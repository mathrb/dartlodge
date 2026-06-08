/// Decides which clockwise quarter-turn rotation presents the dartboard UPRIGHT
/// to the model, from which rotations yield a proper upright cal arrangement
/// over a few frames (#393 portrait orientation fix). Pure domain logic — the
/// aim view runs the detector at each candidate rotation, tests each with
/// [isCalArrangementUpright], feeds the eligibility here, and applies the locked
/// rotation to every served frame.
///
/// Robust to a rotation-locked screen because it works on the **pixel content**
/// (which rotation arranges the cals as the canonical upright diamond), needing
/// no device-orientation metadata. Counting cals alone is NOT enough — the model
/// emits four cal points at several rotations, including upside-down; only the
/// upright one passes the arrangement check. Ties prefer the lower rotation
/// (0 = no rotation, the native path).
class RotationAutoDetector {
  RotationAutoDetector({
    this.candidates = const [0, 1, 2, 3],
    this.requiredStableTicks = 2,
  });

  /// Candidate clockwise quarter-turns to consider.
  final List<int> candidates;

  /// Consecutive ticks the same rotation must stay upright before it locks
  /// (debounce against a one-frame fluke).
  final int requiredStableTicks;

  int? _locked;
  int? _candidate;
  int _streak = 0;

  /// The locked rotation, or null while still searching.
  int? get locked => _locked;

  /// Feed one tick's per-rotation "is the cal arrangement upright" results.
  /// Returns the locked rotation once one stays upright for [requiredStableTicks]
  /// consecutive ticks; null while still searching.
  int? update(Map<int, bool> uprightByQuarterTurn) {
    if (_locked != null) return _locked;

    int? best;
    for (final q in candidates) {
      if (uprightByQuarterTurn[q] ?? false) {
        best = q; // first upright candidate ⇒ ties keep the lower rotation
        break;
      }
    }

    if (best != null) {
      if (best == _candidate) {
        _streak += 1;
      } else {
        _candidate = best;
        _streak = 1;
      }
      if (_streak >= requiredStableTicks) _locked = _candidate;
    } else {
      _candidate = null;
      _streak = 0;
    }
    return _locked;
  }
}
