import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

/// Career-level accumulator for cricket legs played and won.
class CricketLegsProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.legs',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _legsPlayed = 0;
  int _legsWon = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _legsPlayed = 0;
    _legsWon = 0;
  }

  @override
  void apply(GameEvent event) {
    if (event.eventType != 'LegCompleted') return;
    _legsPlayed++;
    final winnerId = event.payload['winner_player_id'] as String?;
    if (winnerId == _context?.playerId) _legsWon++;
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative lifetime stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'legsWon': _legsWon,
      'legsPlayed': _legsPlayed,
    };
  }
}
