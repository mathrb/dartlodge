// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameEventImpl _$$GameEventImplFromJson(Map<String, dynamic> json) =>
    _$GameEventImpl(
      eventId: json['eventId'] as String,
      gameId: json['gameId'] as String,
      eventType: json['eventType'] as String,
      localSequence: (json['localSequence'] as num).toInt(),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      payload: json['payload'] as Map<String, dynamic>,
      synced: json['synced'] as bool,
    );

Map<String, dynamic> _$$GameEventImplToJson(_$GameEventImpl instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'gameId': instance.gameId,
      'eventType': instance.eventType,
      'localSequence': instance.localSequence,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'payload': instance.payload,
      'synced': instance.synced,
    };
