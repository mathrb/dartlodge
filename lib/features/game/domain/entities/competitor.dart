// Competitor Entity
// Represents a competitor (solo player or team) in a game

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/constants.dart';

part 'competitor.freezed.dart';
part 'competitor.g.dart';

@freezed
abstract class Competitor with _$Competitor {
  const factory Competitor({
    @JsonKey(name: 'competitor_id') required String competitorId,
    @JsonKey(name: 'game_id') required String gameId,
    @JsonKey(name: 'type') required CompetitorType type,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'players') required List<CompetitorPlayer> players,
  }) = _Competitor;

  factory Competitor.fromJson(Map<String, dynamic> json) => _$CompetitorFromJson(json);
}

@freezed
abstract class CompetitorPlayer with _$CompetitorPlayer {
  const factory CompetitorPlayer({
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'rotation_position') required int rotationPosition,
  }) = _CompetitorPlayer;

  factory CompetitorPlayer.fromJson(Map<String, dynamic> json) => _$CompetitorPlayerFromJson(json);
}