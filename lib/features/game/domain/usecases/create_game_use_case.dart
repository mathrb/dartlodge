// Create Game Use Case
// Business logic for initializing a new darts game

import '../entities/game.dart';
import '../entities/competitor.dart';
import '../entities/game_event.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_event_repository.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/constants.dart';

class CreateGameUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;

  CreateGameUseCase(this._gameRepository, this._eventRepository);

  Future<Game> execute(Game game, List<Competitor> competitors) async {
    // 1. Create the game and competitors in the database
    await _gameRepository.createGame(game, competitors);

    // 2. Append the GameCreated event
    final event = GameEvent(
      eventId: const Uuid().v4(),
      gameId: game.gameId,
      eventType: 'GameCreated',
      localSequence: 0,
      occurredAt: DateTime.now(),
      payload: {
        'ruleset': game.gameType.name.toUpperCase(),
        'rules': game.config.toJson(),
        'competitors': competitors.map((c) => c.competitorId).toList(),
      },
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );

    await _eventRepository.appendEvent(event);

    // 3. Append TurnStarted event for the first competitor
    final turnStartedEvent = GameEvent(
      eventId: const Uuid().v4(),
      gameId: game.gameId,
      eventType: 'TurnStarted',
      localSequence: 1,
      occurredAt: DateTime.now(),
      payload: {
        'competitor_id': competitors.first.competitorId,
        'turn_index': 0,
      },
      synced: false,
      actorId: 'system',
      source: EventSource.client,
    );

    await _eventRepository.appendEvent(turnStartedEvent);

    return game;
  }
}
