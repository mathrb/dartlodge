// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameStats _$GameStatsFromJson(Map<String, dynamic> json) => _GameStats(
  gameId: json['gameId'] as String,
  byCompetitor: (json['byCompetitor'] as List<dynamic>)
      .map((e) => CompetitorStats.fromJson(e as Map<String, dynamic>))
      .toList(),
  gameType: json['gameType'] as String? ?? '',
);

Map<String, dynamic> _$GameStatsToJson(_GameStats instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'byCompetitor': instance.byCompetitor,
      'gameType': instance.gameType,
    };

_CompetitorStats _$CompetitorStatsFromJson(Map<String, dynamic> json) =>
    _CompetitorStats(
      competitorId: json['competitorId'] as String,
      competitorName: json['competitorName'] as String,
      byPlayer: (json['byPlayer'] as List<dynamic>)
          .map((e) => PlayerTurnStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      threeDartAverage: (json['threeDartAverage'] as num).toDouble(),
      legsWon: (json['legsWon'] as num).toInt(),
      totalDartsThrown: (json['totalDartsThrown'] as num).toInt(),
      checkoutPercentage: (json['checkoutPercentage'] as num?)?.toDouble(),
      highestCheckout: (json['highestCheckout'] as num?)?.toInt(),
      oneEightyTurns: (json['oneEightyTurns'] as num?)?.toInt() ?? 0,
      sixtyPlusTurns: (json['sixtyPlusTurns'] as num?)?.toInt() ?? 0,
      oneHundredPlusTurns: (json['oneHundredPlusTurns'] as num?)?.toInt() ?? 0,
      oneFortyPlusTurns: (json['oneFortyPlusTurns'] as num?)?.toInt() ?? 0,
      marksPerRound: (json['marksPerRound'] as num?)?.toDouble(),
      firstNineMarksPerRound: (json['firstNineMarksPerRound'] as num?)
          ?.toDouble(),
      fiveMarkTurns: (json['fiveMarkTurns'] as num?)?.toInt() ?? 0,
      sixMarkTurns: (json['sixMarkTurns'] as num?)?.toInt() ?? 0,
      sevenMarkTurns: (json['sevenMarkTurns'] as num?)?.toInt() ?? 0,
      eightMarkTurns: (json['eightMarkTurns'] as num?)?.toInt() ?? 0,
      nineMarkTurns: (json['nineMarkTurns'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CompetitorStatsToJson(_CompetitorStats instance) =>
    <String, dynamic>{
      'competitorId': instance.competitorId,
      'competitorName': instance.competitorName,
      'byPlayer': instance.byPlayer,
      'threeDartAverage': instance.threeDartAverage,
      'legsWon': instance.legsWon,
      'totalDartsThrown': instance.totalDartsThrown,
      'checkoutPercentage': instance.checkoutPercentage,
      'highestCheckout': instance.highestCheckout,
      'oneEightyTurns': instance.oneEightyTurns,
      'sixtyPlusTurns': instance.sixtyPlusTurns,
      'oneHundredPlusTurns': instance.oneHundredPlusTurns,
      'oneFortyPlusTurns': instance.oneFortyPlusTurns,
      'marksPerRound': instance.marksPerRound,
      'firstNineMarksPerRound': instance.firstNineMarksPerRound,
      'fiveMarkTurns': instance.fiveMarkTurns,
      'sixMarkTurns': instance.sixMarkTurns,
      'sevenMarkTurns': instance.sevenMarkTurns,
      'eightMarkTurns': instance.eightMarkTurns,
      'nineMarkTurns': instance.nineMarkTurns,
    };

_PlayerTurnStats _$PlayerTurnStatsFromJson(Map<String, dynamic> json) =>
    _PlayerTurnStats(
      playerId: json['playerId'] as String,
      threeDartAverage: (json['threeDartAverage'] as num).toDouble(),
      dartsThrown: (json['dartsThrown'] as num).toInt(),
    );

Map<String, dynamic> _$PlayerTurnStatsToJson(_PlayerTurnStats instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'threeDartAverage': instance.threeDartAverage,
      'dartsThrown': instance.dartsThrown,
    };
