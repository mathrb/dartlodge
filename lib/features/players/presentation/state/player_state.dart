import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

part 'player_state.freezed.dart';

@freezed
abstract class PlayerState with _$PlayerState {
  const factory PlayerState({
    required List<Player> players,
    required bool isLoading,
    String? error,
  }) = _PlayerState;

  factory PlayerState.initial() => const PlayerState(
        players: [],
        isLoading: false,
        error: null,
      );
}
