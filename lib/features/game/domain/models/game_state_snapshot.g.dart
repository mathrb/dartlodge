// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameStateSnapshot _$GameStateSnapshotFromJson(Map<String, dynamic> json) =>
    _GameStateSnapshot(
      gameId: json['gameId'] as String,
      gameType: json['gameType'] as String,
      stateData: json['stateData'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isComplete: json['isComplete'] as bool,
      winnerId: json['winnerId'] as String?,
    );

Map<String, dynamic> _$GameStateSnapshotToJson(_GameStateSnapshot instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'gameType': instance.gameType,
      'stateData': instance.stateData,
      'timestamp': instance.timestamp.toIso8601String(),
      'isComplete': instance.isComplete,
      'winnerId': instance.winnerId,
    };
