// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameImpl _$$GameImplFromJson(Map<String, dynamic> json) => _$GameImpl(
      gameId: json['game_id'] as String,
      gameType: $enumDecode(_$GameTypeEnumMap, json['game_type'],
          unknownValue: GameType.x01),
      config: _parseJsonMap(json['config_json'] as String),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      winnerCompetitorId: json['winner_competitor_id'] as String?,
      isComplete: _parseBoolFromInt((json['is_complete'] as num?)?.toInt()),
      activeState: _parseNullableJsonMap(json['game_state_json'] as String?),
    );

Map<String, dynamic> _$$GameImplToJson(_$GameImpl instance) =>
    <String, dynamic>{
      'game_id': instance.gameId,
      'game_type': _$GameTypeEnumMap[instance.gameType]!,
      'config_json': _stringifyJsonMap(instance.config),
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'winner_competitor_id': instance.winnerCompetitorId,
      'is_complete': _convertBoolToInt(instance.isComplete),
      'game_state_json': _stringifyNullableJsonMap(instance.activeState),
    };

const _$GameTypeEnumMap = {
  GameType.x01: 'x01',
  GameType.cricket: 'cricket',
  GameType.aroundTheClock: 'aroundTheClock',
  GameType.killer: 'killer',
  GameType.baseball: 'baseball',
  GameType.golf: 'golf',
  GameType.shanghai: 'shanghai',
  GameType.scram: 'scram',
  GameType.halveIt: 'halveIt',
  GameType.highScore: 'highScore',
  GameType.blindCricket: 'blindCricket',
  GameType.blindGolf: 'blindGolf',
  GameType.blindKiller: 'blindKiller',
  GameType.blindShanghai: 'blindShanghai',
  GameType.chaseTheDragon: 'chaseTheDragon',
};
