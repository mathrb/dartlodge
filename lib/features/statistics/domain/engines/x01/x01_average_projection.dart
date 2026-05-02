import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class X01AverageProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01_average',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'DartThrown', 'TurnEnded'},
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _totalScoredPoints = 0;
  int _totalDartsThrown = 0;
  int _turnScore = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _totalScoredPoints = 0;
    _totalDartsThrown = 0;
    _turnScore = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final seg = (event.payload['segment'] as num?)?.toInt();
        final mult = (event.payload['multiplier'] as num?)?.toInt();
        final score = (seg != null && mult != null)
            ? seg * mult
            : (event.payload['score'] as num?)?.toInt() ?? 0;
        _turnScore += score;
        _totalDartsThrown++;
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final reason = event.payload['reason'] as String?;
        if (reason != 'bust') {
          _totalScoredPoints += _turnScore;
        }
        _turnScore = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _turnScore = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    final avg = _totalDartsThrown > 0
        ? (_totalScoredPoints / _totalDartsThrown * 3)
        : 0.0;
    return {
      'threeDartAverage': avg,
      'totalScoredPoints': _totalScoredPoints,
      'totalDartsThrown': _totalDartsThrown,
    };
  }
}
