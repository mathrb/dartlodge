// Create Game Use Case
// Business logic for initializing a new darts game

import '../entities/game.dart';
import '../entities/competitor.dart';
import '../entities/game_event.dart';
import '../models/game_config.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_event_repository.dart';
import '../../../players/domain/repositories/player_repository.dart';
import '../../../../core/error/repository_exception.dart';
import '../../../../core/utils/constants.dart';
import 'package:uuid/uuid.dart';

class CreateGameUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;
  final PlayerRepository _playerRepository;

  CreateGameUseCase(
    this._gameRepository,
    this._eventRepository,
    this._playerRepository,
  );

  static final Set<int> _validX01StartingScores =
      GameConfigurationConstants.x01StartingScores.toSet();
  static final Set<String> _validStrategies = {
    ...GameConfigurationConstants.x01InStrategies,
    ...GameConfigurationConstants.x01OutStrategies,
  };

  Future<Game> execute(Game game, List<Competitor> competitors) async {
    _validate(game, competitors);

    // 1. Write the game row and all competitors atomically
    await _gameRepository.createGame(game, competitors);

    // 2. Determine starting local sequence
    final latestSeq = await _eventRepository.getLatestSequence(game.gameId);

    // 3. Append GameCreated — must come before TurnStarted
    final gameCreatedEvent = GameEvent(
      eventId: const Uuid().v4(),
      gameId: game.gameId,
      eventType: 'GameCreated',
      localSequence: latestSeq + 1,
      occurredAt: DateTime.now(),
      payload: {
        'ruleset': game.gameType.name.toUpperCase(),
        'rules_payload': game.config.toJson(),
        'competitors': competitors.map((c) => c.competitorId).toList(),
      },
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );
    await _eventRepository.appendEvent(gameCreatedEvent);

    // 4. Append TurnStarted for the first competitor (index 0 goes first)
    final firstPlayerId = competitors.first.players.isNotEmpty
        ? competitors.first.players.first.playerId
        : 'system';
    final startingScore = game.config.maybeMap(
      x01: (c) => c.startingScore,
      orElse: () => null,
    );
    final turnStartedEvent = GameEvent(
      eventId: const Uuid().v4(),
      gameId: game.gameId,
      eventType: 'TurnStarted',
      localSequence: latestSeq + 2,
      occurredAt: DateTime.now(),
      payload: {
        'game_id': game.gameId,
        'competitor_id': competitors.first.competitorId,
        'player_id': firstPlayerId,
        if (startingScore != null) 'starting_score': startingScore,
        'turn_index': 0,
        'leg_index': 0,
      },
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );
    await _eventRepository.appendEvent(turnStartedEvent);

    final playerIds = <String>{
      for (final c in competitors) for (final cp in c.players) cp.playerId,
    };
    for (final playerId in playerIds) {
      try {
        await _playerRepository.touchPlayer(playerId);
      } on PlayerNotFoundException {
        // touchPlayer is best-effort — a missing row must not abort game creation.
      }
    }

    return game;
  }

  void _validate(Game game, List<Competitor> competitors) {
    if (competitors.isEmpty) {
      throw const ValidationException(
        'Game must have at least 1 competitor (2 for a normal game, 1 for practice).',
      );
    }

    if (game.gameType == GameType.x01) {
      final config = game.config;
      if (config is! X01GameConfig) {
        throw const ValidationException('X01 game must have an X01 config.');
      }

      if (!_validX01StartingScores.contains(config.startingScore)) {
        throw ValidationException(
          'Invalid starting score: ${config.startingScore}. '
          'Must be one of: ${_validX01StartingScores.toList()..sort()}.',
        );
      }

      if (!_validStrategies.contains(config.inStrategy)) {
        throw ValidationException(
          'Invalid in-strategy: "${config.inStrategy}". '
          'Must be one of: ${_validStrategies.join(', ')}.',
        );
      }

      if (!_validStrategies.contains(config.outStrategy)) {
        throw ValidationException(
          'Invalid out-strategy: "${config.outStrategy}". '
          'Must be one of: ${_validStrategies.join(', ')}.',
        );
      }

      if (config.legsToWin < 1) {
        throw ValidationException(
          'Invalid legsToWin: ${config.legsToWin}. Must be at least 1.',
        );
      }
    }
  }
}
