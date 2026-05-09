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
  turnActive: json['turnActive'] as bool? ?? false,
  legsToWin: (json['legsToWin'] as num?)?.toInt() ?? 1,
  currentLegIndex: (json['currentLegIndex'] as num?)?.toInt() ?? 0,
  currentRoundInLeg: (json['currentRoundInLeg'] as num?)?.toInt() ?? 1,
  x01TotalRounds: (json['x01TotalRounds'] as num?)?.toInt(),
  cricketTotalRounds: (json['cricketTotalRounds'] as num?)?.toInt(),
  inStrategy: json['inStrategy'] as String? ?? 'straight',
  outStrategy: json['outStrategy'] as String? ?? 'double',
  startingScore: (json['startingScore'] as num?)?.toInt() ?? 501,
  cricketVariant: json['cricketVariant'] as String? ?? 'standard',
  aroundTheClockVariant: json['aroundTheClockVariant'] as String? ?? 'standard',
  shanghaiTotalRounds: (json['shanghaiTotalRounds'] as num?)?.toInt() ?? 7,
  catch40TargetRemaining:
      (json['catch40TargetRemaining'] as num?)?.toInt() ?? 0,
  catch40DartsOnTarget: (json['catch40DartsOnTarget'] as num?)?.toInt() ?? 0,
  checkoutTargetSuccesses: (json['checkoutTargetSuccesses'] as num?)?.toInt(),
  countUpTotalRounds: (json['countUpTotalRounds'] as num?)?.toInt(),
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
      'turnActive': instance.turnActive,
      'legsToWin': instance.legsToWin,
      'currentLegIndex': instance.currentLegIndex,
      'currentRoundInLeg': instance.currentRoundInLeg,
      'x01TotalRounds': instance.x01TotalRounds,
      'cricketTotalRounds': instance.cricketTotalRounds,
      'inStrategy': instance.inStrategy,
      'outStrategy': instance.outStrategy,
      'startingScore': instance.startingScore,
      'cricketVariant': instance.cricketVariant,
      'aroundTheClockVariant': instance.aroundTheClockVariant,
      'shanghaiTotalRounds': instance.shanghaiTotalRounds,
      'catch40TargetRemaining': instance.catch40TargetRemaining,
      'catch40DartsOnTarget': instance.catch40DartsOnTarget,
      'checkoutTargetSuccesses': instance.checkoutTargetSuccesses,
      'countUpTotalRounds': instance.countUpTotalRounds,
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
      isIn: json['isIn'] as bool? ?? false,
      legsWon: (json['legsWon'] as num?)?.toInt() ?? 0,
      turnStartScore: (json['turnStartScore'] as num?)?.toInt(),
      marksPerNumber:
          (json['marksPerNumber'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      closeOrder: (json['closeOrder'] as num?)?.toInt(),
      currentTarget: (json['currentTarget'] as num?)?.toInt(),
      practiceRound: (json['practiceRound'] as num?)?.toInt() ?? 1,
      practiceAttempts: (json['practiceAttempts'] as num?)?.toInt() ?? 0,
      practiceSuccesses: (json['practiceSuccesses'] as num?)?.toInt() ?? 0,
      routeProgress: (json['routeProgress'] as num?)?.toInt() ?? 0,
      startingScore: (json['startingScore'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CompetitorStateToJson(_CompetitorState instance) =>
    <String, dynamic>{
      'competitorId': instance.competitorId,
      'name': instance.name,
      'playerIds': instance.playerIds,
      'score': instance.score,
      'isComplete': instance.isComplete,
      'dartThrows': instance.dartThrows,
      'isIn': instance.isIn,
      'legsWon': instance.legsWon,
      'turnStartScore': instance.turnStartScore,
      'marksPerNumber': instance.marksPerNumber,
      'closeOrder': instance.closeOrder,
      'currentTarget': instance.currentTarget,
      'practiceRound': instance.practiceRound,
      'practiceAttempts': instance.practiceAttempts,
      'practiceSuccesses': instance.practiceSuccesses,
      'routeProgress': instance.routeProgress,
      'startingScore': instance.startingScore,
    };
