// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerStats _$PlayerStatsFromJson(Map<String, dynamic> json) => _PlayerStats(
  playerId: json['playerId'] as String,
  gameType: $enumDecode(_$GameTypeEnumMap, json['gameType']),
  totalGames: (json['totalGames'] as num).toInt(),
  gamesWon: (json['gamesWon'] as num).toInt(),
  winRate: (json['winRate'] as num).toDouble(),
  threeDartAverage: (json['threeDartAverage'] as num).toDouble(),
  checkoutPercentage: (json['checkoutPercentage'] as num?)?.toDouble(),
  highestCheckout: (json['highestCheckout'] as num?)?.toInt(),
  highestTurnScore: (json['highestTurnScore'] as num).toInt(),
  totalDartsThrown: (json['totalDartsThrown'] as num).toInt(),
  dartsPerLeg: (json['dartsPerLeg'] as num).toDouble(),
  bustRate: (json['bustRate'] as num).toDouble(),
);

Map<String, dynamic> _$PlayerStatsToJson(_PlayerStats instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'gameType': _$GameTypeEnumMap[instance.gameType]!,
      'totalGames': instance.totalGames,
      'gamesWon': instance.gamesWon,
      'winRate': instance.winRate,
      'threeDartAverage': instance.threeDartAverage,
      'checkoutPercentage': instance.checkoutPercentage,
      'highestCheckout': instance.highestCheckout,
      'highestTurnScore': instance.highestTurnScore,
      'totalDartsThrown': instance.totalDartsThrown,
      'dartsPerLeg': instance.dartsPerLeg,
      'bustRate': instance.bustRate,
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
};
