import 'package:uuid/uuid.dart';

import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import 'package:dart_lodge/features/players/domain/validators.dart';

/// Creates a new [Player] with a generated id and current timestamps.
///
/// Validates the name and ensures it does not duplicate an existing player's
/// name (case-insensitive). Returns the newly created [Player].
///
/// Throws:
/// * [ValidationException] when [name] is invalid (empty or too long).
/// * [DuplicatePlayerNameException] when another player already has the same name.
class CreatePlayerUseCase {
  final PlayerRepository _playerRepository;
  final Uuid _uuid;

  CreatePlayerUseCase(this._playerRepository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  Future<Player> call(String name) async {
    final trimmed = name.trim();
    if (validatePlayerName(trimmed) != null) {
      // Internal message only: the form providers pre-validate and surface a
      // localized error, so this exception path is a safety net for direct
      // callers and never reaches the UI.
      throw ValidationException('Invalid player name');
    }

    final existing = await _playerRepository.getAllPlayers();
    if (existing.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) {
      throw DuplicatePlayerNameException(trimmed);
    }

    final now = DateTime.now().toUtc();
    final player = Player(
      playerId: _uuid.v4(),
      name: trimmed,
      createdAt: now,
      lastActive: now,
    );
    await _playerRepository.createPlayer(player);
    return player;
  }
}
