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
import 'game_use_case_helpers.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

class CreateGameUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;
  final PlayerRepository _playerRepository;
  // Pluggable for deterministic tests. Production calls use `math.Random()`.
  final math.Random _random;

  CreateGameUseCase(
    this._gameRepository,
    this._eventRepository,
    this._playerRepository, {
    math.Random? random,
  }) : _random = random ?? math.Random();

  static final Set<int> _validX01StartingScores =
      GameConfigurationConstants.x01StartingScores.toSet();
  static final Set<String> _validInStrategies =
      GameConfigurationConstants.x01InStrategies.toSet();
  static final Set<String> _validOutStrategies =
      GameConfigurationConstants.x01OutStrategies.toSet();

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

    // 3a. Random Cricket: emit `CricketTargetsAssigned` with 6 distinct
    // numbers drawn uniformly from 1–20. RNG runs here once at game
    // creation; the engine's `apply()` is pure and just reads the payload
    // — replay is therefore deterministic by construction (no replay-time
    // RNG). Game-scoped: targets stay fixed across all legs. Bull is
    // implicit as a 7th target and never randomised.
    // See `docs/plans/2026-05-19-cricket-target-modes-design.md` §3.
    var sequenceCursor = latestSeq + 1;
    final randomCricketTargets = game.config.maybeMap(
      cricket: (c) => c.targetMode == 'random' ? _rollRandomTargets() : null,
      orElse: () => null,
    );
    if (randomCricketTargets != null) {
      sequenceCursor += 1;
      final targetsAssignedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: game.gameId,
        eventType: 'CricketTargetsAssigned',
        localSequence: sequenceCursor,
        occurredAt: DateTime.now(),
        payload: {'targets': randomCricketTargets},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );
      await _eventRepository.appendEvent(targetsAssignedEvent);
    }

    // 4. Append TurnStarted for the first competitor (index 0 goes first)
    final firstPlayerId = competitors.first.players.isNotEmpty
        ? competitors.first.players.first.playerId
        : 'system';
    final startingScore = game.config.maybeMap(
      x01: (c) => c.startingScore,
      orElse: () => null,
    );
    sequenceCursor += 1;
    final turnStartedEvent = GameEvent(
      eventId: const Uuid().v4(),
      gameId: game.gameId,
      eventType: 'TurnStarted',
      localSequence: sequenceCursor,
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

    // 4a. Crazy Cricket: emit `CrazyTargetsRolled` right after the first
    // `TurnStarted` with the freshly rolled active set (no locks yet, so
    // 6 fresh numbers from 1–20). Subsequent TurnStarteds emit their own
    // CrazyTargetsRolled at the respective sites (process_cricket_dart
    // use case, active_cricket_game_provider). See design §4.
    final isCrazy = game.config.maybeMap(
      cricket: (c) => c.targetMode == 'crazy',
      orElse: () => false,
    );
    if (isCrazy) {
      sequenceCursor += 1;
      final crazyTargets = rollCrazyOpenTargets(
        locked: const <int>{},
        random: _random,
      );
      final rollEvent = buildCrazyTargetsRolledEvent(
        gameId: game.gameId,
        competitorId: competitors.first.competitorId,
        round: 1,
        openTargets: crazyTargets,
        localSequence: sequenceCursor,
      );
      await _eventRepository.appendEvent(rollEvent);
    }

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

      if (!_validInStrategies.contains(config.inStrategy)) {
        throw ValidationException(
          'Invalid in-strategy: "${config.inStrategy}". '
          'Must be one of: ${_validInStrategies.join(', ')}.',
        );
      }

      if (!_validOutStrategies.contains(config.outStrategy)) {
        throw ValidationException(
          'Invalid out-strategy: "${config.outStrategy}". '
          'Must be one of: ${_validOutStrategies.join(', ')}.',
        );
      }

      if (config.legsToWin < 1) {
        throw ValidationException(
          'Invalid legsToWin: ${config.legsToWin}. Must be at least 1.',
        );
      }
    }
  }

  /// Draw 6 distinct numbers from 1..20 (uniform without replacement).
  /// Bull is always implicit as a 7th target and never randomised.
  List<int> _rollRandomTargets() {
    final pool = [for (var i = 1; i <= 20; i++) i];
    final picked = <int>[];
    for (var i = 0; i < 6; i++) {
      final idx = _random.nextInt(pool.length);
      picked.add(pool.removeAt(idx));
    }
    return picked;
  }
}
