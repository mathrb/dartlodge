// Game Statistics Entity
// Represents statistics for a completed game

import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_stats.freezed.dart';
part 'game_stats.g.dart';

@freezed
abstract class GameStats with _$GameStats {
  const factory GameStats({
    required String gameId,
    required List<CompetitorStats> byCompetitor,
  }) = _GameStats;

  factory GameStats.fromJson(Map<String, dynamic> json) =>
      _$GameStatsFromJson(json);
}

@freezed
abstract class CompetitorStats with _$CompetitorStats {
  const factory CompetitorStats({
    required String competitorId,
    required String competitorName,
    required List<PlayerTurnStats> byPlayer,
    required double threeDartAverage,
    required int legsWon,
    required int totalDartsThrown,
    double? checkoutPercentage,
    int? highestCheckout,
    @Default(0) int oneEightyTurns,
    @Default(0) int sixtyPlusTurns,
    @Default(0) int oneHundredPlusTurns,
    @Default(0) int oneFortyPlusTurns,
  }) = _CompetitorStats;

  factory CompetitorStats.fromJson(Map<String, dynamic> json) =>
      _$CompetitorStatsFromJson(json);
}

@freezed
abstract class PlayerTurnStats with _$PlayerTurnStats {
  const factory PlayerTurnStats({
    required String playerId,
    required double threeDartAverage,
    required int dartsThrown,
  }) = _PlayerTurnStats;

  factory PlayerTurnStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerTurnStatsFromJson(json);
}