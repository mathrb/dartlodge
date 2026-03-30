import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';
import 'cricket_segment_utils.dart';

/// Computes Marks Per Round (MPR) for the first 9 darts (first 3 turns) of each leg.
/// Mirrors X01FirstNinePprProjection but counts cricket marks instead of score.
class CricketFirstNineMprProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.firstNineMpr',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'TurnStarted', 'DartThrown', 'TurnEnded', 'LegCompleted'},
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _turnIndexInLeg = 0;
  bool _inFirstNine = false;
  int _currentTurnMarks = 0;
  int _totalFirstNineMarks = 0;
  int _totalFirstNineLegs = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _turnIndexInLeg = 0;
    _inFirstNine = false;
    _currentTurnMarks = 0;
    _totalFirstNineMarks = 0;
    _totalFirstNineLegs = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _turnIndexInLeg++;
        _inFirstNine = _turnIndexInLeg <= 3;
        _currentTurnMarks = 0;
      case 'DartThrown':
        if (!_inFirstNine) return;
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final segment = event.payload['segment'] as String?;
        if (segment == null) return;
        _currentTurnMarks += cricketMarksForSegment(segment);
      case 'TurnEnded':
        if (!_inFirstNine) return;
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _totalFirstNineMarks += _currentTurnMarks;
        _currentTurnMarks = 0;
      case 'LegCompleted':
        if (_turnIndexInLeg >= 1) {
          _totalFirstNineLegs++;
        }
        _turnIndexInLeg = 0;
        _inFirstNine = false;
        _currentTurnMarks = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _currentTurnMarks = 0;
      _inFirstNine = false;
    }
    if (scope == ProjectionScope.leg) {
      _turnIndexInLeg = 0;
      _inFirstNine = false;
      _currentTurnMarks = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    final mpr = _totalFirstNineLegs > 0
        ? _totalFirstNineMarks / (_totalFirstNineLegs * 3)
        : null;
    return {
      'firstNineMpr': mpr,
      'totalFirstNineMarks': _totalFirstNineMarks,
      'totalFirstNineLegs': _totalFirstNineLegs,
    };
  }
}
