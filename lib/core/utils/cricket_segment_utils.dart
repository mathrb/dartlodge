/// Cricket-specific segment utilities.

/// Canonical fixed-cricket target set (15–20 + Bull as 25).
///
/// For Random Cricket the target set is **not** these numbers — the
/// projections that compute marks pass an override [targets] set
/// derived from the `CricketTargetsAssigned` event payload (plus the
/// implicit Bull 25). See
/// `docs/plans/2026-05-19-cricket-target-modes-design.md` §5/§6.
const kCricketTargets = {15, 16, 17, 18, 19, 20, 25};

/// Returns the number of cricket marks for a canonical segment string.
/// DB=2, SB=1, triple cricket target=3, double cricket target=2, single=1, non-target or MISS=0.
///
/// [targets] overrides the default fixed-cricket set; provide it when
/// computing stats on a Random (or future Crazy) Cricket game so that
/// hits on the assigned numbers count and hits on 15–20 that are *not*
/// part of the assigned set do not.
int cricketMarksForSegment(String segment, {Set<int>? targets}) {
  if (segment == 'DB') return 2;
  if (segment == 'SB') return 1;
  if (segment == 'MISS') return 0;
  int multiplier = 1;
  String stripped = segment;
  if (segment.startsWith('T')) {
    multiplier = 3;
    stripped = segment.substring(1);
  } else if (segment.startsWith('D')) {
    multiplier = 2;
    stripped = segment.substring(1);
  }
  final n = int.tryParse(stripped);
  final effectiveTargets = targets ?? kCricketTargets;
  if (n == null || !effectiveTargets.contains(n)) return 0;
  return multiplier;
}

/// Returns cricket marks from numeric (segment, multiplier) pair.
///
/// [targets] overrides the default fixed-cricket set; provide it when
/// computing stats on a Random (or future Crazy) Cricket game.
int cricketMarksFromPayload(int segment, int multiplier,
    {Set<int>? targets}) {
  if (segment == 0) return 0;
  final effectiveTargets = targets ?? kCricketTargets;
  if (!effectiveTargets.contains(segment)) return 0;
  return multiplier.clamp(0, 3);
}

/// Returns true if the numeric segment is a valid cricket target.
///
/// [targets] overrides the default fixed-cricket set; provide it when
/// computing stats on a Random (or future Crazy) Cricket game.
bool isCricketTargetNumeric(int segment, {Set<int>? targets}) {
  final effectiveTargets = targets ?? kCricketTargets;
  return segment != 0 && effectiveTargets.contains(segment);
}
