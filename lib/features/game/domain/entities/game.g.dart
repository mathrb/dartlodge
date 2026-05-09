// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Game _$GameFromJson(Map<String, dynamic> json) => _Game(
  gameId: json['game_id'] as String,
  gameType: $enumDecode(
    _$GameTypeEnumMap,
    json['game_type'],
    unknownValue: GameType.x01,
  ),
  config: GameConfig.fromJson(json['config_json'] as Map<String, dynamic>),
  startTime: DateTime.parse(json['start_time'] as String),
  endTime: json['end_time'] == null
      ? null
      : DateTime.parse(json['end_time'] as String),
  winnerCompetitorId: json['winner_competitor_id'] as String?,
  isComplete: _parseBoolFromDynamic(json['is_complete']),
  activeState: json['game_state_json'] == null
      ? null
      : GameStateSnapshot.fromJson(
          json['game_state_json'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$GameToJson(_Game instance) => <String, dynamic>{
  'game_id': instance.gameId,
  'game_type': _$GameTypeEnumMap[instance.gameType]!,
  'config_json': instance.config,
  'start_time': instance.startTime.toIso8601String(),
  'end_time': instance.endTime?.toIso8601String(),
  'winner_competitor_id': instance.winnerCompetitorId,
  'is_complete': _convertBoolToInt(instance.isComplete),
  'game_state_json': instance.activeState,
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
  GameType.catch40: 'catch40',
  GameType.bobs27: 'bobs27',
  GameType.checkoutPractice: 'checkoutPractice',
  GameType.countUp: 'countUp',
};
