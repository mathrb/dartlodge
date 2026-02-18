// Player Repository Interface
// Defines the contract for player data access

import '../entities/player.dart';

abstract interface class PlayerRepository {
  /// Returns all players ordered by [lastActive] descending.
  Future<List<Player>> getAllPlayers();

  /// Returns the player with [playerId], or null if not found.
  Future<Player?> getPlayer(String playerId);

  /// Inserts a new player. Throws [DuplicatePlayerException] if [player.playerId]
  /// already exists.
  Future<void> createPlayer(Player player);

  /// Updates [name] and [lastActive] for the player with [playerId].
  /// Throws [PlayerNotFoundException] if the player does not exist.
  Future<void> updatePlayerName(String playerId, String name);

  /// Updates [lastActive] to now for the player with [playerId].
  /// Throws [PlayerNotFoundException] if the player does not exist.
  Future<void> touchPlayer(String playerId);

  /// Emits the full player list whenever any player row changes.
  /// Used by player selection screens to stay reactive without polling.
  Stream<List<Player>> watchAllPlayers();
}