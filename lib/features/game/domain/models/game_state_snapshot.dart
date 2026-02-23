// Game State Snapshot Entity
// Represents a typed snapshot of the game state for persistence

import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state_snapshot.freezed.dart';
part 'game_state_snapshot.g.dart';

@freezed
abstract class GameStateSnapshot with _$GameStateSnapshot {
  const factory GameStateSnapshot({
    required String gameId,
    required String gameType,
    required Map<String, dynamic> stateData, // Game-specific state data
    required DateTime timestamp,
    required bool isComplete,
    String? winnerId,
  }) = _GameStateSnapshot;

  factory GameStateSnapshot.fromJson(Map<String, dynamic> json) => _$GameStateSnapshotFromJson(json);
}
