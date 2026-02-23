// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Player _$PlayerFromJson(Map<String, dynamic> json) => _Player(
  playerId: json['player_id'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  lastActive: DateTime.parse(json['last_active'] as String),
);

Map<String, dynamic> _$PlayerToJson(_Player instance) => <String, dynamic>{
  'player_id': instance.playerId,
  'name': instance.name,
  'created_at': instance.createdAt.toIso8601String(),
  'last_active': instance.lastActive.toIso8601String(),
};
