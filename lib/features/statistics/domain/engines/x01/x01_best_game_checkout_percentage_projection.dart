import 'package:dart_lodge/core/utils/checkout_table.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// Tracks the best single-game checkout percentage across all games.
///
/// Uses the same "reached-a-finish" attempt definition as
/// [X01CheckoutProjection] (#637): a checkout attempt is a visit in which the
/// player threw at least one dart from a single-dart finish position for the
/// game's out strategy, not merely a visit that began ≤170.
class X01BestGameCheckoutPercentageProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.bestGameCheckoutPercentage',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {
      'TurnStarted',
      'DartThrown',
      'TurnEnded',
      'LegCompleted',
      'GameCompleted',
    },
    scope: ProjectionScope.match,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;

  // Per-game counters
  int _gameAttempts = 0;
  int _gameSuccesses = 0;

  // Per-visit scratch (see X01CheckoutProjection for the reconstruction rules).
  int? _currentTurnRemaining;
  bool _threwAtFinish = false;

  // Career best
  double? _bestGameCo;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _gameAttempts = 0;
    _gameSuccesses = 0;
    _currentTurnRemaining = null;
    _threwAtFinish = false;
    _bestGameCo = null;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _currentTurnRemaining =
            (event.payload['starting_score'] as num?)?.toInt();
        _threwAtFinish = false;
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final remaining = _currentTurnRemaining;
        if (remaining == null) return;
        if (isOnAFinish(remaining, _context?.outStrategy ?? 'double')) {
          _threwAtFinish = true;
        }
        final score = (event.payload['score'] as num?)?.toInt() ?? 0;
        _currentTurnRemaining = remaining - score;
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        if (_threwAtFinish) _gameAttempts++;
        _threwAtFinish = false;
        _currentTurnRemaining = null;
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
        _currentTurnRemaining = null;
        _threwAtFinish = false;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.match) {
      _gameAttempts = 0;
      _gameSuccesses = 0;
      _currentTurnRemaining = null;
      _threwAtFinish = false;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'bestGameCheckoutPercentage': _bestGameCo,
    };
  }
}
