import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';

part 'active_practice_state.freezed.dart';

@freezed
abstract class ActivePracticeState with _$ActivePracticeState {
  const factory ActivePracticeState({
    required GameState gameState,
    String? pendingGameWinnerId,
    @Default(false) bool showShanghaiBonus,

    /// Transient flag set true on the dart that busted in Catch 40 (#325).
    /// The board page listens for the false→true transition to flash a
    /// BUST snackbar; the next dart (or `dismissBust`) clears it. Only
    /// Catch 40 currently emits this — other practice modes either
    /// can't bust (ATC) or already handle their own busts (X01 in
    /// `ActiveGameState`).
    @Default(false) bool showBust,

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
