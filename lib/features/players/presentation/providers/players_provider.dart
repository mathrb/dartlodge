import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/players/domain/validators.dart';
import 'package:my_darts/features/players/presentation/state/player_form_state.dart';

part 'players_provider.g.dart';

String _playerFormErrorMessage(Object e) => e is DuplicatePlayerException
    ? 'A player with this name already exists'
    : e.toString();

@riverpod
class AllPlayers extends _$AllPlayers {
  @override
  Stream<List<Player>> build() {
    return ref.watch(playerRepositoryProvider).watchAllPlayers();
  }
}

@riverpod
Future<Player?> player(Ref ref, String id) async {
  final players = await ref.watch(allPlayersProvider.future);
  try {
    return players.firstWhere((p) => p.playerId == id);
  } on StateError {
    return null;
  }
}

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
        throw DuplicatePlayerException(name);
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

  Future<void> submit() async {
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
      if (existing.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
        throw DuplicatePlayerException(name);
      }
      final now = DateTime.now().toUtc();
      final player = Player(
        playerId: const Uuid().v4(),
        name: name,
        createdAt: now,
        lastActive: now,
      );
      await repo.createPlayer(player);
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
}
