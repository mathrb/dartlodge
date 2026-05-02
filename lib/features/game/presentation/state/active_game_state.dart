import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';

part 'active_game_state.freezed.dart';

@freezed
abstract class ActiveGameState with _$ActiveGameState {
  const factory ActiveGameState({
    required GameState gameState,
    @Default(false) bool showBust,
    String? pendingLegWinnerId,
    String? pendingGameWinnerId,
    @Default(false) bool pendingCapSelection,
  }) = _ActiveGameState;
}
