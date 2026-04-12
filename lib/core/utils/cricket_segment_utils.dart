/// Cricket-specific segment utilities.

/// Canonical set of cricket target numbers (bull represented as 25).
const kCricketTargets = {15, 16, 17, 18, 19, 20, 25};

/// Returns the number of cricket marks for a canonical segment string.
/// DB=2, SB=1, triple cricket target=3, double cricket target=2, single=1, non-target or MISS=0.
int cricketMarksForSegment(String segment) {
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
  if (n == null || !kCricketTargets.contains(n)) return 0;
  return multiplier;
}

/// Returns cricket marks from numeric (segment, multiplier) pair.
int cricketMarksFromPayload(int segment, int multiplier) {
  if (segment == 0) return 0;
  if (!kCricketTargets.contains(segment)) return 0;
  return multiplier.clamp(0, 3);
}

/// Returns true if the numeric segment is a valid cricket target.
bool isCricketTargetNumeric(int segment) {
  return segment != 0 && kCricketTargets.contains(segment);
}
