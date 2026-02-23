// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dart_throw.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DartThrow _$DartThrowFromJson(Map<String, dynamic> json) => _DartThrow(
  dartId: json['dart_id'] as String,
  gameId: json['game_id'] as String,
  competitorId: json['competitor_id'] as String,
  playerId: json['player_id'] as String,
  turnNumber: (json['turn_number'] as num).toInt(),
  dartNumber: (json['dart_number'] as num).toInt(),
  segment: json['segment'] as String,
  score: (json['score'] as num).toInt(),
  x: (json['x'] as num?)?.toDouble(),
  y: (json['y'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DartThrowToJson(_DartThrow instance) =>
    <String, dynamic>{
      'dart_id': instance.dartId,
      'game_id': instance.gameId,
      'competitor_id': instance.competitorId,
      'player_id': instance.playerId,
      'turn_number': instance.turnNumber,
      'dart_number': instance.dartNumber,
      'segment': instance.segment,
      'score': instance.score,
      'x': instance.x,
      'y': instance.y,
    };
