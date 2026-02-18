// Competitor Entity
// Represents a competitor (solo player or team) in a game

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/constants.dart';

part 'competitor.freezed.dart';
part 'competitor.g.dart';

@freezed
class Competitor with _$Competitor {
  const factory Competitor({
    required String competitorId,
    required String gameId,
    required CompetitorType type,
    required String name,
    required List<CompetitorPlayer> players,
  }) = _Competitor;

  factory Competitor.fromJson(Map<String, dynamic> json) => _$CompetitorFromJson(json);
}

@freezed
class CompetitorPlayer with _$CompetitorPlayer {
  const factory CompetitorPlayer({
    required String playerId,
    required int rotationPosition,
  }) = _CompetitorPlayer;

  factory CompetitorPlayer.fromJson(Map<String, dynamic> json) => _$CompetitorPlayerFromJson(json);
}