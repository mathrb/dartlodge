// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameStatsImpl _$$GameStatsImplFromJson(Map<String, dynamic> json) =>
    _$GameStatsImpl(
      gameId: json['gameId'] as String,
      byCompetitor: (json['byCompetitor'] as List<dynamic>)
          .map((e) => CompetitorStats.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$GameStatsImplToJson(_$GameStatsImpl instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'byCompetitor': instance.byCompetitor,
    };

_$CompetitorStatsImpl _$$CompetitorStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$CompetitorStatsImpl(
      competitorId: json['competitorId'] as String,
      competitorName: json['competitorName'] as String,
      byPlayer: (json['byPlayer'] as List<dynamic>)
          .map((e) => PlayerTurnStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      threeDartAverage: (json['threeDartAverage'] as num).toDouble(),
      legsWon: (json['legsWon'] as num).toInt(),
      totalDartsThrown: (json['totalDartsThrown'] as num).toInt(),
    );

Map<String, dynamic> _$$CompetitorStatsImplToJson(
        _$CompetitorStatsImpl instance) =>
    <String, dynamic>{
      'competitorId': instance.competitorId,
      'competitorName': instance.competitorName,
      'byPlayer': instance.byPlayer,
      'threeDartAverage': instance.threeDartAverage,
      'legsWon': instance.legsWon,
      'totalDartsThrown': instance.totalDartsThrown,
    };

_$PlayerTurnStatsImpl _$$PlayerTurnStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayerTurnStatsImpl(
      playerId: json['playerId'] as String,
      threeDartAverage: (json['threeDartAverage'] as num).toDouble(),
      dartsThrown: (json['dartsThrown'] as num).toInt(),
    );

Map<String, dynamic> _$$PlayerTurnStatsImplToJson(
        _$PlayerTurnStatsImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'threeDartAverage': instance.threeDartAverage,
      'dartsThrown': instance.dartsThrown,
    };
