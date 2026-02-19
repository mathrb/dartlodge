// Dart Throw Entity
// Represents a single dart throw in a game

import 'package:freezed_annotation/freezed_annotation.dart';

part 'dart_throw.freezed.dart';
part 'dart_throw.g.dart';

@freezed
abstract class DartThrow with _$DartThrow {
  const factory DartThrow({
    @JsonKey(name: 'dart_id') required String dartId,
    @JsonKey(name: 'game_id') required String gameId,
    @JsonKey(name: 'competitor_id') required String competitorId,
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'turn_number') required int turnNumber,
    @JsonKey(name: 'dart_number') required int dartNumber, // 1, 2, or 3
    @JsonKey(name: 'segment') required String segment, // canonical: '20', 'T20', 'D20', 'SB', 'DB', 'MISS'
    @JsonKey(name: 'score') required int score,
    @JsonKey(name: 'x') double? x, // coordinates for auto-scoring
    @JsonKey(name: 'y') double? y,
  }) = _DartThrow;

  factory DartThrow.fromJson(Map<String, dynamic> json) => _$DartThrowFromJson(json);
}