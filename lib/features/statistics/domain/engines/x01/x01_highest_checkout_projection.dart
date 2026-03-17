import 'dart:math';

import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

class X01HighestCheckoutProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01_highest_checkout',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'LegCompleted'},
    scope: ProjectionScope.match,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _highestCheckout = 0;
  int _lastPlayerTurnStartingScore = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _highestCheckout = 0;
    _lastPlayerTurnStartingScore = 0;
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
        _highestCheckout = max(_highestCheckout, _lastPlayerTurnStartingScore);
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative career stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'highestCheckout': _highestCheckout > 0 ? _highestCheckout : null,
    };
  }
}
