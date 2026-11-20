import '../../../../core/utils/cricket_segment_utils.dart';
import '../../../../core/utils/stat_formatter.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';

/// Live running averages shown on the in-game boards, shared by the manual and
/// camera-first layouts so both render the identical figure (#696). Each
/// returns the display string (already `StatFormatter`-formatted).

/// X01 points-per-round (3-dart average) for [cs] mid-leg.
///
/// Sum of dart values ÷ darts × 3 — independent of starting score and game
/// type, and naturally including busted darts (the #247 projection
/// convention; the old `startingScore - currentScore` shortcut leaked the X01
/// handicap into PPR, #246). Returns `'—'` until at least one full visit (3
/// darts) has been thrown.
String x01LivePprDisplay(CompetitorState cs) {
  if (cs.dartThrows.length < 3) return '—';
  final pointsScored = cs.dartThrows
      .map((d) => Segment.parse(d).scoreValue)
      .fold<int>(0, (a, b) => a + b);
  return StatFormatter.fmtDouble((pointsScored / cs.dartThrows.length) * 3);
}

/// Cricket marks-per-round for [cs] mid-leg, counting marks on the game's
/// actual target set [targets] (Fixed = 15–20 + Bull, Random/Crazy = the
/// assigned set + Bull) so Random/Crazy hits aren't scored as zero marks
/// (#320). Marks (incl. overflow on closed numbers) of the completed 3-dart
/// visits ÷ those visits; `0` until the first visit completes.
///
/// The visit in progress is left out of BOTH the numerator and the
/// denominator, so the figure holds still during a visit and updates once its
/// 3rd dart lands. Counting its marks over completed visits only would read
/// above the physical maximum of 9 (e.g. 12 after T20 T20 MISS, T19 T19).
double cricketLiveMpr(CompetitorState cs, {required Set<int> targets}) {
  final rounds = cs.dartThrows.length ~/ 3;
  if (rounds == 0) return 0.0;
  final totalMarks = cs.dartThrows
      .take(rounds * 3)
      .fold(0, (sum, s) => sum + cricketMarksForSegment(s, targets: targets));
  return totalMarks / rounds;
}

/// [cricketLiveMpr] formatted for display.
String cricketLiveMprDisplay(CompetitorState cs, {required Set<int> targets}) =>
    StatFormatter.fmtDouble(cricketLiveMpr(cs, targets: targets));
