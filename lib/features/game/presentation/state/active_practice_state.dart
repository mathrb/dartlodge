import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';

part 'active_practice_state.freezed.dart';

@freezed
abstract class ActivePracticeState with _$ActivePracticeState {
  const factory ActivePracticeState({
    required GameState gameState,
    String? pendingGameWinnerId,
    @Default(false) bool showShanghaiBonus,
  }) = _ActivePracticeState;
}
