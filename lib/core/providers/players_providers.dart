import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

part 'players_providers.g.dart';

/// Reactive stream of all players. Backed by drift's `.watch()`, so any
/// mutation through `PlayerRepository` automatically refreshes consumers.
///
/// Lives in `core/providers/` because it is consumed across multiple features
/// (game player-selection, statistics tab, settings, players list). The
/// per-feature form notifiers (`CreatePlayerNotifier`, `EditPlayerNotifier`)
/// stay in `features/players/presentation/providers/`.
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
