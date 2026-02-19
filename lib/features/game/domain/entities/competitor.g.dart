// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competitor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Competitor _$CompetitorFromJson(Map<String, dynamic> json) => _Competitor(
  competitorId: json['competitor_id'] as String,
  gameId: json['game_id'] as String,
  type: $enumDecode(_$CompetitorTypeEnumMap, json['type']),
  name: json['name'] as String,
  players: (json['players'] as List<dynamic>)
      .map((e) => CompetitorPlayer.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CompetitorToJson(_Competitor instance) =>
    <String, dynamic>{
      'competitor_id': instance.competitorId,
      'game_id': instance.gameId,
      'type': _$CompetitorTypeEnumMap[instance.type]!,
      'name': instance.name,
      'players': instance.players,
    };

const _$CompetitorTypeEnumMap = {
  CompetitorType.solo: 'solo',
  CompetitorType.team: 'team',
};

_CompetitorPlayer _$CompetitorPlayerFromJson(Map<String, dynamic> json) =>
    _CompetitorPlayer(
      playerId: json['player_id'] as String,
      rotationPosition: (json['rotation_position'] as num).toInt(),
    );

Map<String, dynamic> _$CompetitorPlayerToJson(_CompetitorPlayer instance) =>
    <String, dynamic>{
      'player_id': instance.playerId,
      'rotation_position': instance.rotationPosition,
    };
