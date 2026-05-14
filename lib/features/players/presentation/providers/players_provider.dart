import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/validators.dart';
import 'package:dart_lodge/features/players/presentation/state/player_form_state.dart';

part 'players_provider.g.dart';

String _playerFormErrorMessage(Object e) =>
    (e is DuplicatePlayerException || e is DuplicatePlayerNameException)
        ? 'A player with this name already exists'
        : e.toString();

@riverpod
class EditPlayerNotifier extends _$EditPlayerNotifier {
  @override
  PlayerFormState build() => PlayerFormState.initial();

  void setName(String name) {
    state = state.copyWith(name: name, nameError: null);
  }

  Future<void> submit(String playerId) async {
    final name = state.name.trim();

    final error = validatePlayerName(name);
    if (error != null) {
      state = state.copyWith(nameError: error);
      return;
    }

    state = state.copyWith(isSubmitting: true, nameError: null);

    final result = await AsyncValue.guard(() async {
      final repo = ref.read(playerRepositoryProvider);
      final existing = await repo.getAllPlayers();
      if (existing.any(
        (p) =>
            p.playerId != playerId &&
            p.name.toLowerCase() == name.toLowerCase(),
      )) {
        throw DuplicatePlayerNameException(name);
      }
      await repo.updatePlayerName(playerId, name);
    });

    result.when(
      data: (_) {
        state = state.copyWith(isSubmitting: false);
        ref.invalidate(allPlayersProvider);
        ref.invalidate(playerProvider(playerId));
      },
      error: (e, _) {
        state = state.copyWith(
          isSubmitting: false,
          nameError: _playerFormErrorMessage(e),
        );
      },
      loading: () {},
    );
  }

  /// Returns true on success, false when player has game history.
  Future<bool> deletePlayer(String playerId) async {
    final result = await AsyncValue.guard(() async {
      await ref.read(playerRepositoryProvider).deletePlayer(playerId);
    });

    if (result.hasValue) {
      ref.invalidate(allPlayersProvider);
      return true;
    }
    if (result.error is PlayerHasGameHistoryException) return false;
    state = state.copyWith(nameError: result.error.toString());
    return false;
  }
}

@riverpod
class CreatePlayerNotifier extends _$CreatePlayerNotifier {
  @override
  PlayerFormState build() => PlayerFormState.initial();

  void setName(String name) {
    state = state.copyWith(name: name, nameError: null);
  }

  void reset() {
    state = PlayerFormState.initial();
  }

  /// Form-driven submit used by [CreatePlayerPage]. Reads [state.name],
  /// surfaces validation/duplicate errors on the form state, and leaves the
  /// caller to navigate on success.
  Future<void> submit() async {
    final name = state.name.trim();

    final error = validatePlayerName(name);
    if (error != null) {
      state = state.copyWith(nameError: error);
      return;
    }

    state = state.copyWith(isSubmitting: true, nameError: null);

    final result = await AsyncValue.guard(() async {
      await ref.read(createPlayerUseCaseProvider).call(name);
    });

    result.when(
      data: (_) {
        state = state.copyWith(isSubmitting: false);
      },
      error: (e, _) {
        state = state.copyWith(
          isSubmitting: false,
          nameError: _playerFormErrorMessage(e),
        );
      },
      loading: () {},
    );
  }

  /// One-shot creation path used by widgets that manage their own local UI
  /// state (e.g. the inline new-player sheet on the player-selection screen).
  ///
  /// Returns the new [Player] on success. Throws [ValidationException] or
  /// [DuplicatePlayerNameException] on failure — callers translate to UI messages.
  /// Does not touch this notifier's form state.
  Future<Player> createPlayer(String name) =>
      ref.read(createPlayerUseCaseProvider).call(name);
}
