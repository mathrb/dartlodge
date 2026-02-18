// Game Entity
// Represents a darts game with its configuration and state

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import '../../../../core/utils/constants.dart';

part 'game.freezed.dart';
part 'game.g.dart';

@freezed
class Game with _$Game {
  const factory Game({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'game_id') required String gameId,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01) required GameType gameType,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'config_json', fromJson: _parseJsonMap, toJson: _stringifyJsonMap) required Map<String, dynamic> config,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'start_time') required DateTime startTime,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'end_time') DateTime? endTime,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'winner_competitor_id') String? winnerCompetitorId,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'is_complete', fromJson: _parseBoolFromInt, toJson: _convertBoolToInt) bool? isComplete,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'game_state_json', fromJson: _parseNullableJsonMap, toJson: _stringifyNullableJsonMap) Map<String, dynamic>? activeState,
  }) = _Game;

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}

// Custom JSON parsers for Map fields
Map<String, dynamic> _parseJsonMap(String jsonString) {
  try {
    return json.decode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    return {};
  }
}

String _stringifyJsonMap(Map<String, dynamic> map) {
  return json.encode(map);
}

Map<String, dynamic>? _parseNullableJsonMap(String? jsonString) {
  if (jsonString == null) return null;
  try {
    return json.decode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
}

String? _stringifyNullableJsonMap(Map<String, dynamic>? map) {
  if (map == null) return null;
  return json.encode(map);
}

// Custom JSON parsers for boolean fields stored as integers
bool? _parseBoolFromInt(int? intValue) {
  if (intValue == null) return null;
  return intValue == 1;
}

int? _convertBoolToInt(bool? boolValue) {
  if (boolValue == null) return null;
  return boolValue ? 1 : 0;
}