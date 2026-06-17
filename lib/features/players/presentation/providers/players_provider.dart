import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/features/players/domain/validators.dart';
import 'package:dart_lodge/features/players/presentation/state/player_form_state.dart';

part 'players_provider.g.dart';

/// Outcome of `EditPlayerNotifier.deletePlayer`. Sealed so callers must
/// exhaustively distinguish success from the two failure modes:
/// the player has saved game history (expected, common path → show the
/// "cannot delete a player with game history" SnackBar) versus an
/// unexpected error (DB issue, missing player, etc. → show a generic
/// retry SnackBar). Pre-`DeletePlayerResult` (the bool return type used
/// up to #214) the two cases collapsed into a single `false`, so
/// callers showed the wrong-but-plausible "has game history" message
/// for every failure.
sealed class DeletePlayerResult {
  const DeletePlayerResult();
}

final class DeletePlayerSuccess extends DeletePlayerResult {
  const DeletePlayerSuccess();
}

final class DeletePlayerHasGameHistory extends DeletePlayerResult {
  const DeletePlayerHasGameHistory();
}

final class DeletePlayerUnexpectedError extends DeletePlayerResult {
  final Object error;
  const DeletePlayerUnexpectedError(this.error);
}

PlayerNameError _playerFormError(Object e) =>
    (e is DuplicatePlayerException || e is DuplicatePlayerNameException)
        ? PlayerNameError.duplicate
        : PlayerNameError.unknown;

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
          nameError: _playerFormError(e),
        );
      },
      loading: () {},
    );
  }

  /// Deletes a player. Returns a sealed [DeletePlayerResult] so callers
  /// can show targeted feedback per case (see the type's docstring).
  ///
  /// Catches only `Exception` so Dart `Error` subclasses (assertion
  /// failures, stack overflow, etc.) still propagate to Riverpod's
  /// error boundary and Sentry — matching the previous
  /// `AsyncValue.guard` semantics. Wrapping them silently would mask
  /// programming errors as a generic "Failed to delete player" SnackBar.
  Future<DeletePlayerResult> deletePlayer(String playerId) async {
    try {
      await ref.read(playerRepositoryProvider).deletePlayer(playerId);
      ref.invalidate(allPlayersProvider);
      return const DeletePlayerSuccess();
    } on PlayerHasGameHistoryException {
      return const DeletePlayerHasGameHistory();
    } on Exception catch (e) {
      return DeletePlayerUnexpectedError(e);
    }
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
          nameError: _playerFormError(e),
        );
      },
      loading: () {},
    );
  }
}
