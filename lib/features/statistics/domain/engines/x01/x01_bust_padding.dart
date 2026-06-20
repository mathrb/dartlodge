import 'dart:math' as math;

/// Darts to ADD to a three-dart-average denominator when an X01 turn ends.
///
/// PDC / Wikipedia three-dart-average convention (#634, supersedes #610): a
/// **busted** visit counts as a full 3-dart visit in the denominator (it scored
/// 0, but is a complete visit). A non-bust turn — including a leg-winning
/// checkout on fewer than 3 darts — counts only the darts actually thrown, so
/// it needs no padding.
///
/// The event stream emits one `DartThrown` per dart actually thrown and stops
/// at the busting dart, so a bust on dart 1/2 leaves the per-dart denominator
/// short; this returns the missing darts (capped at 0) from the `TurnEnded`
/// `reason` plus the per-turn dart count — derivable purely from events, no
/// migration. Apply it to average denominators ONLY; never inflate a raw
/// "darts thrown" count.
int bustDartPadding(String? turnEndedReason, int dartsThrownThisTurn) =>
    turnEndedReason == 'bust' ? math.max(0, 3 - dartsThrownThisTurn) : 0;
