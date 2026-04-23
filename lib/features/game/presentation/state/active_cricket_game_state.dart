import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:my_darts/features/game/domain/models/game_state.dart';

part 'active_cricket_game_state.freezed.dart';

@freezed
abstract class ActiveCricketGameState with _$ActiveCricketGameState {
  const factory ActiveCricketGameState({
    required GameState gameState,
    String? pendingLegWinnerId,
    String? pendingGameWinnerId,
    @Default(false) bool pendingCapSelection,
  }) = _ActiveCricketGameState;
}
