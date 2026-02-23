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
  }) = _PlayerStats;

  factory PlayerStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatsFromJson(json);
}