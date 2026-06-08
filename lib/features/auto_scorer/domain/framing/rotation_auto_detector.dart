/// Decides which clockwise quarter-turn rotation presents the dartboard upright
/// to the model, from per-rotation cal-point counts observed over a few frames
/// (#393 portrait orientation fix). Pure domain logic — the aim view runs the
/// detector at each candidate rotation, feeds the counts here, and applies the
/// locked rotation to every served frame.
///
/// Robust to a rotation-locked screen because it works on the **pixel content**
/// (which rotation actually finds the cals), needing no device-orientation
/// metadata. Ties prefer the lower rotation (0 = no rotation, the native path).
class RotationAutoDetector {
  RotationAutoDetector({
    this.candidates = const [0, 1, 2, 3],
    this.requiredCals = 4,
    this.requiredStableTicks = 2,
  });

  /// Candidate clockwise quarter-turns to consider.
  final List<int> candidates;

  /// Cal points a rotation must yield to be eligible to lock (all four).
  final int requiredCals;

  /// Consecutive ticks the same rotation must stay best-and-eligible before it
  /// locks (debounce against a one-frame fluke).
  final int requiredStableTicks;

  int? _locked;
  int? _candidate;
  int _streak = 0;

  /// The locked rotation, or null while still searching.
  int? get locked => _locked;

  /// Feed one tick's cal counts keyed by quarter-turn. Returns the locked
  /// rotation once a candidate reaches [requiredCals] and stays the best choice
  /// for [requiredStableTicks] consecutive ticks; null while still searching.
  int? update(Map<int, int> calsByQuarterTurn) {
    if (_locked != null) return _locked;

    int? best;
    var bestCals = -1;
    for (final q in candidates) {
      final c = calsByQuarterTurn[q] ?? 0;
      if (c > bestCals) {
        bestCals = c;
        best = q; // strict `>` ⇒ ties keep the earlier (lower) candidate
      }
    }

    if (best != null && bestCals >= requiredCals) {
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
