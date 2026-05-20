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
    /// "End Drill" menu (i.e. the user manually abandoned the drill).
    /// `practice_board_page` distinguishes manual completions from natural
    /// engine completions to decide whether to navigate to the post-game
    /// summary (natural) or home (manual).
    @Default(false) bool wasEndedManually,
  }) = _ActivePracticeState;
}
