import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';

part 'game_setup_state.freezed.dart';

@freezed
abstract class GameSetupState with _$GameSetupState {
  /// Initial state — no game type chosen yet.
  const factory GameSetupState.selectingType() = _SelectingType;

  /// Variant chosen; config form is open.
  const factory GameSetupState.configuringGame({
    required GameType gameType,
    required GameConfig config,
  }) = _ConfiguringGame;

  /// Player list step.
  const factory GameSetupState.selectingPlayers({
    required GameType gameType,
    required GameConfig config,
    required List<String> selectedPlayerIds,
  }) = _SelectingPlayers;

  /// Team assignment step (UI not built in EPIC-004; included to avoid
  /// future breaking change at exhaustive `.map` call sites).
  const factory GameSetupState.formingTeams({
    required GameType gameType,
    required GameConfig config,
    required List<String> selectedPlayerIds,
  }) = _FormingTeams;

  /// All steps satisfied; notifier may call CreateGameUseCase.
  const factory GameSetupState.ready({
    required GameType gameType,
    required GameConfig config,
    required List<String> selectedPlayerIds,
  }) = _Ready;

  factory GameSetupState.initial() => const GameSetupState.selectingType();
}
