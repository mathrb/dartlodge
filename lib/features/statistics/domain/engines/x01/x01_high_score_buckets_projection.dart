import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

class X01HighScoreBucketsProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.highScoreBuckets',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'DartThrown', 'TurnEnded'},
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _currentTurnScore = 0;
  int _sixtyPlus = 0;
  int _oneHundredPlus = 0;
  int _oneFortyPlus = 0;
  int _onEighty = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _currentTurnScore = 0;
    _sixtyPlus = 0;
    _oneHundredPlus = 0;
    _oneFortyPlus = 0;
    _onEighty = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final score = (event.payload['score'] as num?)?.toInt() ?? 0;
        _currentTurnScore += score;
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final reason = event.payload['reason'] as String?;
        if (reason != 'bust') {
          final s = _currentTurnScore;
          if (s == 180) {
            _onEighty++;
            _oneFortyPlus++;
            _oneHundredPlus++;
            _sixtyPlus++;
          } else if (s >= 140) {
            _oneFortyPlus++;
            _oneHundredPlus++;
            _sixtyPlus++;
          } else if (s >= 100) {
            _oneHundredPlus++;
            _sixtyPlus++;
          } else if (s >= 60) {
            _sixtyPlus++;
          }
        }
        _currentTurnScore = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _currentTurnScore = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'sixtyPlusTurns': _sixtyPlus,
      'oneHundredPlusTurns': _oneHundredPlus,
      'oneFortyPlusTurns': _oneFortyPlus,
      'oneEightyTurns': _onEighty,
    };
  }
}
