import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';

part 'active_count_up_state.freezed.dart';

/// Notifier state for the active count-up board page.
///
/// Count-up is single-leg, has no bust, and no round-cap ambiguity, so this
/// state is intentionally smaller than [ActiveGameState]:
/// - no `showBust` — every dart adds, never reverts
/// - no `pendingLegWinnerId` — a single leg coincides with the game
/// - no `pendingCapSelection` — winner is auto-determined (or null on tie)
@freezed
abstract class ActiveCountUpState with _$ActiveCountUpState {
  const factory ActiveCountUpState({
    required GameState gameState,
    String? pendingGameWinnerId,
  }) = _ActiveCountUpState;
}
