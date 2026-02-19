// Game Event Entity
// Represents an event that occurred during a game

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'game_event.freezed.dart';
part 'game_event.g.dart';

@freezed
abstract class GameEvent with _$GameEvent {
  const factory GameEvent({
    @JsonKey(name: 'event_id') required String eventId,
    @JsonKey(name: 'game_id') required String gameId,
    @JsonKey(name: 'event_type') required String eventType,
    @JsonKey(name: 'local_sequence') required int localSequence,
    @JsonKey(name: 'occurred_at') required DateTime occurredAt,
    @JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload) required Map<String, dynamic> payload,
    @JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt) required bool synced,
  }) = _GameEvent;

  factory GameEvent.fromJson(Map<String, dynamic> json) => _$GameEventFromJson(json);
}

Map<String, dynamic> _parsePayload(dynamic payload) {
  if (payload is String) return jsonDecode(payload) as Map<String, dynamic>;
  return payload as Map<String, dynamic>;
}

dynamic _stringifyPayload(Map<String, dynamic> payload) => jsonEncode(payload);

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  return false;
}

int _boolToInt(bool value) => value ? 1 : 0;