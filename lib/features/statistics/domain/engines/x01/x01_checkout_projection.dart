import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

class X01CheckoutProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01_checkout',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _checkoutAttempts = 0;
  int _successfulCheckouts = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _checkoutAttempts = 0;
    _successfulCheckouts = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final startingScore =
            (event.payload['starting_score'] as num?)?.toInt() ?? 9999;
        if (startingScore <= 170) _checkoutAttempts++;
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId) _successfulCheckouts++;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative career stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    final checkoutPercentage = _checkoutAttempts > 0
        ? (_successfulCheckouts / _checkoutAttempts * 100)
        : null;
    return {
      'checkoutPercentage': checkoutPercentage,
      'checkoutAttempts': _checkoutAttempts,
      'successfulCheckouts': _successfulCheckouts,
    };
  }
}
