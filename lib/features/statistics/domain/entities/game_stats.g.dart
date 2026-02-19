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
);

Map<String, dynamic> _$GameStatsToJson(_GameStats instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'byCompetitor': instance.byCompetitor,
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
    );

Map<String, dynamic> _$CompetitorStatsToJson(_CompetitorStats instance) =>
    <String, dynamic>{
      'competitorId': instance.competitorId,
      'competitorName': instance.competitorName,
      'byPlayer': instance.byPlayer,
      'threeDartAverage': instance.threeDartAverage,
      'legsWon': instance.legsWon,
      'totalDartsThrown': instance.totalDartsThrown,
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
