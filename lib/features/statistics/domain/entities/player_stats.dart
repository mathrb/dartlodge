// Player Statistics Entity
// Represents aggregated statistics for a player

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/constants.dart';

part 'player_stats.freezed.dart';
part 'player_stats.g.dart';

@freezed
abstract class PlayerStats with _$PlayerStats {
  const factory PlayerStats({
    required String playerId,
    required GameType gameType,
    required int totalGames,
    required int gamesWon,
    required double winRate,
    required double threeDartAverage,
    double? checkoutPercentage, // null for non-X01 games
    int? highestCheckout,
    required int highestTurnScore,
    required int totalDartsThrown,
    required double dartsPerLeg,
    required double bustRate, // 0.0–1.0
    @Default(0) int legsPlayed,
    @Default(0) int legsWon,
    double? firstNinePpr,
    @Default(0) int sixtyPlusTurns,
    @Default(0) int oneHundredPlusTurns,
    @Default(0) int oneFortyPlusTurns,
    @Default(0) int oneEightyTurns,
    // X01 best-of metrics (null when no data)
    double? bestLegPpr,
    double? bestFirstNinePpr,
    double? avgCheckoutScore,
    double? bestGameCheckoutPercentage,
    // X01 strategy-conditional metrics (null when strategy is 'straight' or
    // when no attempts recorded). Values are percentages (0–100).
    double? doubleOutSuccessRate,
    double? firstDartInSuccessRate,
    // Cricket-specific fields (null for non-cricket games). Mark-turn
    // counters in this career bundle are ≥-N counts (5+, 6+, 7+, 8+, 9
    // exact). For exact-N per-game counts, see `getGameStats`.
    double? marksPerTurn,
    double? hitRate,
    @Default(0) int fiveMarkTurns,
    @Default(0) int sixMarkTurns,
    @Default(0) int sevenMarkTurns,
    @Default(0) int eightMarkTurns,
    @Default(0) int nineMarkTurns,
    // Cricket best-of metrics (null when no data)
    double? bestLegMpt,
    double? bestGameHitRate,
    // Average marks in the first 9 darts (first 3 turns) per leg (#286).
    double? firstNineMpr,
    // ATC practice fields
    @Default(0) int atcCompletions,
    double? atcHitRate,
    double? atcAvgTurns,
    int? atcBestTurns,
    @Default(<int, int>{}) Map<int, int> atcSegmentHits,
    @Default(<int, int>{}) Map<int, int> atcSegmentAttempts,
    // Bob's 27 practice fields
    double? bobs27AvgScore,
    int? bobs27BestScore,
    double? bobs27CompletionRate,
    double? bobs27DoubleHitRate,
    // Shanghai practice fields
    double? shanghaiAvgScore,
    int? shanghaiBestScore,
    @Default(0) int shanghaiCount,
    // Catch-40 practice fields
    double? catch40AvgScore,
    int? catch40BestScore,
    @Default(0) int catch40TwoDartCheckouts,
    @Default(0) int catch40ThreeDartCheckouts,
    @Default(0) int catch40FourSixDartCheckouts,
    @Default(0) int catch40FailedCheckouts,
    // Checkout practice fields
    @Default(0) int checkoutAttempts,
    @Default(0) int checkoutSuccesses,
    double? checkoutSuccessRate,
  }) = _PlayerStats;

  factory PlayerStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatsFromJson(json);
}