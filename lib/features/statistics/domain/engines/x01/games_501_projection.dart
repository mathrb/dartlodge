import 'dart:math';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// Counts completed X01 games started at 501 (#521/#524).
///
/// The starting score is read from `TurnStarted.starting_score` (the leg opener
/// is the full game start). On `GameCompleted` the game counts when that start
/// was 501. The per-game start resets on the match boundary; the cumulative
/// count persists. Events fed here are the player's own games (the bundle loads
/// per-player), so this is "501 games played".
class Games501Projection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.games501',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'GameCompleted'},
    scope: ProjectionScope.match,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  int? _gameStartingScore;
  int _games501 = 0;

  @override
  void init(ProjectionContext context) {
    _gameStartingScore = null;
    _games501 = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final startingScore = (event.payload['starting_score'] as num?)?.toInt();
        if (startingScore != null) {
          _gameStartingScore = max(_gameStartingScore ?? 0, startingScore);
        }
      case 'GameCompleted':
        if (_gameStartingScore == 501) _games501++;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.match) {
      _gameStartingScore = null;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {'games501Played': _games501};
  }
}
