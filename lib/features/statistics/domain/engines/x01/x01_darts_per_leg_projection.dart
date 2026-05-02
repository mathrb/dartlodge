import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class X01DartsPerLegProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.dartsPerLeg',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'DartThrown', 'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _totalDartsThrown = 0;
  int _legsWon = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _totalDartsThrown = 0;
    _legsWon = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _totalDartsThrown++;
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId) _legsWon++;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative lifetime stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    final dartsPerLeg =
        _legsWon > 0 ? (_totalDartsThrown / _legsWon) : null;
    return {
      'dartsPerLeg': dartsPerLeg,
      'totalDartsThrown': _totalDartsThrown,
      'legsWon': _legsWon,
    };
  }
}
