// Game Event Entity
// Represents an event that occurred during a game

import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_event.freezed.dart';
part 'game_event.g.dart';

@freezed
class GameEvent with _$GameEvent {
  const factory GameEvent({
    required String eventId,
    required String gameId,
    required String eventType,
    required int localSequence,
    required DateTime occurredAt,
    required Map<String, dynamic> payload,
    required bool synced,
  }) = _GameEvent;

  factory GameEvent.fromJson(Map<String, dynamic> json) => _$GameEventFromJson(json);
}