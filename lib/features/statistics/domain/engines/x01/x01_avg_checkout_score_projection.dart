import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// Tracks average checkout score (mean of all successful checkout values).
class X01AvgCheckoutScoreProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.avgCheckoutScore',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'LegCompleted'},
    scope: ProjectionScope.career,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _lastPlayerTurnStartingScore = 0;
  int _checkoutScoreSum = 0;
  int _checkoutCount = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _lastPlayerTurnStartingScore = 0;
    _checkoutScoreSum = 0;
    _checkoutCount = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _lastPlayerTurnStartingScore =
            (event.payload['starting_score'] as num?)?.toInt() ?? 0;
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId != _context?.playerId) return;
        _checkoutScoreSum += _lastPlayerTurnStartingScore;
        _checkoutCount++;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative career stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'avgCheckoutScore':
          _checkoutCount > 0 ? _checkoutScoreSum / _checkoutCount : null,
    };
  }
}
