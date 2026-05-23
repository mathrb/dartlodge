import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';

part 'active_practice_state.freezed.dart';

@freezed
abstract class ActivePracticeState with _$ActivePracticeState {
  const factory ActivePracticeState({
    required GameState gameState,
    String? pendingGameWinnerId,
    @Default(false) bool showShanghaiBonus,

    /// Set to `true` when `EndPracticeUseCase` was invoked via the
    /// "End Drill" menu (i.e. the user manually ended the drill). Both
    /// natural completion and manual end now route to the post-game
    /// summary (#289/#291); the flag stays so the completion listener in
    /// `practice_board_page` can skip its own navigation when the menu
    /// handler is already going to navigate explicitly — preventing a
    /// double-nav race.
    @Default(false) bool wasEndedManually,
  }) = _ActivePracticeState;
}
