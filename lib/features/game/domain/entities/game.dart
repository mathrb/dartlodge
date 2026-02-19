// Game Entity
// Represents a darts game with its configuration and state

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/constants.dart';
import '../models/game_config.dart';
import '../models/game_state_snapshot.dart';

part 'game.freezed.dart';
part 'game.g.dart';

@freezed
abstract class Game with _$Game {
  const factory Game({
    
    @JsonKey(name: 'game_id') required String gameId,
    
    @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01) required GameType gameType,
   
    @JsonKey(name: 'config_json') required GameConfig config,
  
    @JsonKey(name: 'start_time') required DateTime startTime,
 
    @JsonKey(name: 'end_time') DateTime? endTime,

    @JsonKey(name: 'winner_competitor_id') String? winnerCompetitorId,

    @JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt) bool? isComplete,

    @JsonKey(name: 'game_state_json') GameStateSnapshot? activeState,
  }) = _Game;

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}

// Custom JSON parsers for boolean fields with flexible type handling
bool? _parseBoolFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return null;
}

int? _convertBoolToInt(bool? boolValue) {
  if (boolValue == null) return null;
  return boolValue ? 1 : 0;
}
