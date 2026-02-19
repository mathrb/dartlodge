// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameEvent _$GameEventFromJson(Map<String, dynamic> json) => _GameEvent(
  eventId: json['event_id'] as String,
  gameId: json['game_id'] as String,
  eventType: json['event_type'] as String,
  localSequence: (json['local_sequence'] as num).toInt(),
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  payload: _parsePayload(json['payload_json']),
  synced: _parseBool(json['synced']),
);

Map<String, dynamic> _$GameEventToJson(_GameEvent instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'game_id': instance.gameId,
      'event_type': instance.eventType,
      'local_sequence': instance.localSequence,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'payload_json': _stringifyPayload(instance.payload),
      'synced': _boolToInt(instance.synced),
    };
