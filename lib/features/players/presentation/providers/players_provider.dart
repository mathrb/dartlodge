import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/players/presentation/state/player_form_state.dart';

part 'players_provider.g.dart';

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

    if (name.isEmpty) {
      state = state.copyWith(nameError: 'Name cannot be empty');
      return;
    }
    if (name.length > 30) {
      state = state.copyWith(nameError: 'Name must be 30 characters or fewer');
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
        final msg = e is DuplicatePlayerException
            ? 'A player with this name already exists'
            : e.toString();
        state = state.copyWith(isSubmitting: false, nameError: msg);
      },
      loading: () {},
    );
  }
}
