// Dart Throw Entity
// Represents a single dart throw in a game

import 'package:freezed_annotation/freezed_annotation.dart';

part 'dart_throw.freezed.dart';
part 'dart_throw.g.dart';

@freezed
class DartThrow with _$DartThrow {
  const factory DartThrow({
    required String dartId,
    required String gameId,
    required String competitorId,
    required String playerId,
    required int turnNumber,
    required int dartNumber, // 1, 2, or 3
    required String segment, // canonical: '20', 'T20', 'D20', 'SB', 'DB', 'MISS'
    required int score,
    double? x, // coordinates for auto-scoring
    double? y,
  }) = _DartThrow;

  factory DartThrow.fromJson(Map<String, dynamic> json) => _$DartThrowFromJson(json);
}