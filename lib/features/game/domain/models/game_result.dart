// Game Result — sealed sum type produced by `GetGameResultUseCase` for the
// post-game summary screen of practice drills and Shanghai.
//
// Constraint #4 — "Statistics Are Projections — Never Stored" — applies: every
// field on every variant is derived by replaying `game_events` through the
// existing practice/Shanghai engine. No new scoring math lives here; the
// use case reads fields off the final `CompetitorState`/`GameState` and
// observes per-round score deltas where the engine doesn't expose them
// directly (Shanghai's `bestRound`).
//
// Count-Up is intentionally NOT a variant: it stays on the shared
// `gameStatsProvider` (x01-shaped summary chrome fits it).
//
// Around the Clock and Shanghai accept multiple competitors (see
// `GameType.maxPlayers`) and the post-game summary must rank all of them —
// not just the winner — so those two variants carry a per-competitor list
// instead of a single subject (#279). Bob's 27 / Catch 40 / Checkout
// Practice are solo drills (maxPlayers == 1) and keep the single-subject
// shape.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_result.freezed.dart';
part 'game_result.g.dart';

@freezed
sealed class GameResult with _$GameResult {
  const factory GameResult.aroundTheClock({
    required List<AtcCompetitorResult> competitors,
    required String? winnerCompetitorId,
    required bool doublesOnly,
  }) = AroundTheClockResult;

  const factory GameResult.catch40({
    required String competitorName,
    required int score,
    required int targetsCleared,
  }) = Catch40Result;

  const factory GameResult.bobs27({
    required String competitorName,
    required int finalScore,
    required int roundReached,
    required bool bustedToZero,
  }) = Bobs27Result;

  const factory GameResult.checkoutPractice({
    required String competitorName,
    required int attempts,
    required int successes,
    required int dartsThrown,
    required int fromScore,
    // Configured checkout quota (`target_successes`); null = ∞ (manual end).
    // Drives the post-game header denominator (#603) — quota progress, not the
    // attempt count.
    int? targetSuccesses,
    // Target mode + range (#636) so the post-game "FROM" can show a single
    // value (fixed) or a range ("40–170" random / "60→170" progressive).
    @Default('fixed') String targetMode,
    @Default(170) int fixedTarget,
    @Default(40) int minTarget,
    @Default(170) int maxTarget,
  }) = CheckoutPracticeResult;

  const factory GameResult.shanghai({
    required List<ShanghaiCompetitorResult> competitors,
    required String? winnerCompetitorId,
    required int totalRounds,
  }) = ShanghaiResult;

  factory GameResult.fromJson(Map<String, dynamic> json) =>
      _$GameResultFromJson(json);
}

/// Per-competitor result for an Around the Clock game. The post-game podium
/// orders by `(finished desc, turnsCompleted asc, totalDarts asc)` for
/// finishers; non-finishers fall in below ordered by `lastTargetHit`
/// descending for standard / `lastTargetHit` ascending for reverse (closer
/// to the goal first).
///
/// `lastTargetHit` is the highest target number actually hit for standard /
/// doublesOnly (0 if no hits yet) and the lowest target hit for reverse
/// (21 if no hits yet — i.e. nothing below 20 yet). The use case derives it
/// from `CompetitorState.currentTarget` plus the variant; consumers don't
/// have to know about that math.
@freezed
sealed class AtcCompetitorResult with _$AtcCompetitorResult {
  const factory AtcCompetitorResult({
    required String competitorId,
    required String competitorName,
    required int turnsCompleted,
    required int totalDarts,
    required int lastTargetHit,
    required bool finished,
  }) = _AtcCompetitorResult;

  factory AtcCompetitorResult.fromJson(Map<String, dynamic> json) =>
      _$AtcCompetitorResultFromJson(json);
}

/// Per-competitor result for a Shanghai game. The post-game podium orders by
/// `(totalScore desc, shanghaiBonuses desc, bestRound desc)` — highest score
/// wins, with shanghai bonuses then best round as tie-breakers.
@freezed
sealed class ShanghaiCompetitorResult with _$ShanghaiCompetitorResult {
  const factory ShanghaiCompetitorResult({
    required String competitorId,
    required String competitorName,
    required int totalScore,
    required int shanghaiBonuses,
    required int bestRound,
    required int roundsPlayed,
  }) = _ShanghaiCompetitorResult;

  factory ShanghaiCompetitorResult.fromJson(Map<String, dynamic> json) =>
      _$ShanghaiCompetitorResultFromJson(json);
}
