import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// Tracks the best single-game checkout percentage across all games.
class X01BestGameCheckoutPercentageProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.bestGameCheckoutPercentage',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'LegCompleted', 'GameCompleted'},
    scope: ProjectionScope.match,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;

  // Per-game counters
  int _gameAttempts = 0;
  int _gameSuccesses = 0;

  // Career best
  double? _bestGameCo;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _gameAttempts = 0;
    _gameSuccesses = 0;
    _bestGameCo = null;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final startingScore =
            (event.payload['starting_score'] as num?)?.toInt() ?? 9999;
        if (startingScore <= 170) _gameAttempts++;
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId) _gameSuccesses++;
      case 'GameCompleted':
        if (_gameAttempts > 0) {
          final gameCo = _gameSuccesses / _gameAttempts * 100;
          if (_bestGameCo == null || gameCo > _bestGameCo!) {
            _bestGameCo = gameCo;
          }
        }
        _gameAttempts = 0;
        _gameSuccesses = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.match) {
      _gameAttempts = 0;
      _gameSuccesses = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'bestGameCheckoutPercentage': _bestGameCo,
    };
  }
}
