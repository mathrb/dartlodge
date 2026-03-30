import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';
import 'cricket_segment_utils.dart';

/// Counts high-mark turns: turns scoring 6+ marks or 9 marks (maximum).
class CricketMarkBucketsProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.markBuckets',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'DartThrown', 'TurnEnded'},
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _sixMarkTurns = 0;
  int _nineMarkTurns = 0;
  int _turnMarks = 0;
  int _fiveMarkExact = 0;
  int _sixMarkExact = 0;
  int _sevenMarkExact = 0;
  int _eightMarkExact = 0;
  int _nineMarkExact = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _sixMarkTurns = 0;
    _nineMarkTurns = 0;
    _turnMarks = 0;
    _fiveMarkExact = 0;
    _sixMarkExact = 0;
    _sevenMarkExact = 0;
    _eightMarkExact = 0;
    _nineMarkExact = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final segment = event.payload['segment'] as String?;
        if (segment == null) return;
        _turnMarks += cricketMarksForSegment(segment);
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        if (_turnMarks >= 9) _nineMarkTurns++;
        if (_turnMarks >= 6) _sixMarkTurns++;
        switch (_turnMarks) {
          case 5: _fiveMarkExact++;
          case 6: _sixMarkExact++;
          case 7: _sevenMarkExact++;
          case 8: _eightMarkExact++;
          case 9: _nineMarkExact++;
        }
        _turnMarks = 0;
    }
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
      'fiveMarkExact': _fiveMarkExact,
      'sixMarkExact': _sixMarkExact,
      'sevenMarkExact': _sevenMarkExact,
      'eightMarkExact': _eightMarkExact,
      'nineMarkExact': _nineMarkExact,
    };
  }
}
