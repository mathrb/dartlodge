/// Leg-count arithmetic for multi-leg matches.
///
/// A match is configured by `legsToWin` (first to N), but players read the
/// format as "best of" the longest possible head-to-head match. These helpers
/// convert between the two so labels never show legs-to-win as a total.
library;

/// The "best of" leg count of a first-to-[legsToWin] match between two
/// players: `2 * legsToWin - 1` (first to 2 = best of 3).
int bestOfLegs(int legsToWin) => 2 * legsToWin - 1;

/// The most legs a first-to-[legsToWin] match can last with
/// [competitorCount] competitors: every competitor wins `legsToWin - 1` legs,
/// then one decider. Equals [bestOfLegs] for two competitors. A solo player
/// wins every leg they check out, so a solo match is exactly [legsToWin] legs.
int maxLegsInMatch(int legsToWin, int competitorCount) {
  if (competitorCount <= 1) return legsToWin;
  return competitorCount * (legsToWin - 1) + 1;
}
