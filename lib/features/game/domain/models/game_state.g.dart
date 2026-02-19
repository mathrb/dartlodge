// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameState _$GameStateFromJson(Map<String, dynamic> json) => _GameState(
  gameId: json['gameId'] as String,
  gameType: $enumDecode(_$GameTypeEnumMap, json['gameType']),
  competitors: (json['competitors'] as List<dynamic>)
      .map((e) => CompetitorState.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentTurnIndex: (json['currentTurnIndex'] as num).toInt(),
  dartsThrownInTurn: (json['dartsThrownInTurn'] as num).toInt(),
  isComplete: json['isComplete'] as bool,
  winnerCompetitorId: json['winnerCompetitorId'] as String?,
  status:
      $enumDecodeNullable(_$GameEngineStatusEnumMap, json['status']) ??
      GameEngineStatus.initialized,
);

Map<String, dynamic> _$GameStateToJson(_GameState instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'gameType': _$GameTypeEnumMap[instance.gameType]!,
      'competitors': instance.competitors,
      'currentTurnIndex': instance.currentTurnIndex,
      'dartsThrownInTurn': instance.dartsThrownInTurn,
      'isComplete': instance.isComplete,
      'winnerCompetitorId': instance.winnerCompetitorId,
      'status': _$GameEngineStatusEnumMap[instance.status]!,
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

const _$GameEngineStatusEnumMap = {
  GameEngineStatus.initialized: 'initialized',
  GameEngineStatus.inProgress: 'inProgress',
  GameEngineStatus.completed: 'completed',
  GameEngineStatus.cancelled: 'cancelled',
};

_CompetitorState _$CompetitorStateFromJson(Map<String, dynamic> json) =>
    _CompetitorState(
      competitorId: json['competitorId'] as String,
      name: json['name'] as String,
      playerIds: (json['playerIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      score: (json['score'] as num).toInt(),
      isComplete: json['isComplete'] as bool? ?? false,
      dartThrows:
          (json['dartThrows'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CompetitorStateToJson(_CompetitorState instance) =>
    <String, dynamic>{
      'competitorId': instance.competitorId,
      'name': instance.name,
      'playerIds': instance.playerIds,
      'score': instance.score,
      'isComplete': instance.isComplete,
      'dartThrows': instance.dartThrows,
    };
