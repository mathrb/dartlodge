// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dart_throw.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DartThrowImpl _$$DartThrowImplFromJson(Map<String, dynamic> json) =>
    _$DartThrowImpl(
      dartId: json['dartId'] as String,
      gameId: json['gameId'] as String,
      competitorId: json['competitorId'] as String,
      playerId: json['playerId'] as String,
      turnNumber: (json['turnNumber'] as num).toInt(),
      dartNumber: (json['dartNumber'] as num).toInt(),
      segment: json['segment'] as String,
      score: (json['score'] as num).toInt(),
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$DartThrowImplToJson(_$DartThrowImpl instance) =>
    <String, dynamic>{
      'dartId': instance.dartId,
      'gameId': instance.gameId,
      'competitorId': instance.competitorId,
      'playerId': instance.playerId,
      'turnNumber': instance.turnNumber,
      'dartNumber': instance.dartNumber,
      'segment': instance.segment,
      'score': instance.score,
      'x': instance.x,
      'y': instance.y,
    };
