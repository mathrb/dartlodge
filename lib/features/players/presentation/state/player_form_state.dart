import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_form_state.freezed.dart';

@freezed
abstract class PlayerFormState with _$PlayerFormState {
  const factory PlayerFormState({
    required String name,
    String? nameError,
    required bool isSubmitting,
  }) = _PlayerFormState;

  factory PlayerFormState.initial() => const PlayerFormState(
        name: '',
        nameError: null,
        isSubmitting: false,
      );
}
