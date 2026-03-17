import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

/// Counts high-mark turns: turns scoring 6+ marks or 9 marks (maximum).
class CricketMarkBucketsProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.markBuckets',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'DartThrown', 'TurnEnded'},
    scope: ProjectionScope.turn,
  );

  static const _cricketTargets = {15, 16, 17, 18, 19, 20, 25};

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _sixMarkTurns = 0;
  int _nineMarkTurns = 0;
  int _turnMarks = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _sixMarkTurns = 0;
    _nineMarkTurns = 0;
    _turnMarks = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final segment = event.payload['segment'] as String?;
        if (segment == null) return;
        final marks = _marksForSegment(segment);
        _turnMarks += marks;
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        if (_turnMarks >= 9) _nineMarkTurns++;
        if (_turnMarks >= 6) _sixMarkTurns++;
        _turnMarks = 0;
    }
  }

  int _marksForSegment(String segment) {
    if (segment == 'DB') return 2;
    if (segment == 'SB') return 1;
    if (segment == 'MISS') return 0;
    int multiplier = 1;
    String stripped = segment;
    if (segment.startsWith('T')) {
      multiplier = 3;
      stripped = segment.substring(1);
    } else if (segment.startsWith('D')) {
      multiplier = 2;
      stripped = segment.substring(1);
    }
    final n = int.tryParse(stripped);
    if (n == null || !_cricketTargets.contains(n)) return 0;
    return multiplier;
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _turnMarks = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'sixMarkTurns': _sixMarkTurns,
      'nineMarkTurns': _nineMarkTurns,
    };
  }
}
