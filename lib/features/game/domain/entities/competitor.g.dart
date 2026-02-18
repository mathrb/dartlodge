// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competitor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompetitorImpl _$$CompetitorImplFromJson(Map<String, dynamic> json) =>
    _$CompetitorImpl(
      competitorId: json['competitorId'] as String,
      gameId: json['gameId'] as String,
      type: $enumDecode(_$CompetitorTypeEnumMap, json['type']),
      name: json['name'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => CompetitorPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$CompetitorImplToJson(_$CompetitorImpl instance) =>
    <String, dynamic>{
      'competitorId': instance.competitorId,
      'gameId': instance.gameId,
      'type': _$CompetitorTypeEnumMap[instance.type]!,
      'name': instance.name,
      'players': instance.players,
    };

const _$CompetitorTypeEnumMap = {
  CompetitorType.solo: 'solo',
  CompetitorType.team: 'team',
};

_$CompetitorPlayerImpl _$$CompetitorPlayerImplFromJson(
        Map<String, dynamic> json) =>
    _$CompetitorPlayerImpl(
      playerId: json['playerId'] as String,
      rotationPosition: (json['rotationPosition'] as num).toInt(),
    );

Map<String, dynamic> _$$CompetitorPlayerImplToJson(
        _$CompetitorPlayerImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'rotationPosition': instance.rotationPosition,
    };
