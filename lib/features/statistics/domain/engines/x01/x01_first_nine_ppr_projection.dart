import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

class X01FirstNinePprProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.firstNinePpr',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'DartThrown', 'TurnEnded', 'LegCompleted'},
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _turnIndexInLeg = 0;
  bool _inFirstNine = false;
  int _currentTurnScore = 0;
  int _totalFirstNinePoints = 0;
  int _totalFirstNineLegs = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _turnIndexInLeg = 0;
    _inFirstNine = false;
    _currentTurnScore = 0;
    _totalFirstNinePoints = 0;
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
        _currentTurnScore = 0;
      case 'DartThrown':
        if (!_inFirstNine) return;
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final score = (event.payload['score'] as num?)?.toInt() ?? 0;
        _currentTurnScore += score;
      case 'TurnEnded':
        if (!_inFirstNine) return;
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final reason = event.payload['reason'] as String?;
        if (reason != 'bust') {
          _totalFirstNinePoints += _currentTurnScore;
        }
        _currentTurnScore = 0;
      case 'LegCompleted':
        if (_turnIndexInLeg >= 3) {
          _totalFirstNineLegs++;
        }
        _turnIndexInLeg = 0;
        _inFirstNine = false;
        _currentTurnScore = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _currentTurnScore = 0;
      _inFirstNine = false;
    }
    if (scope == ProjectionScope.leg) {
      _turnIndexInLeg = 0;
      _inFirstNine = false;
      _currentTurnScore = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    final ppr = _totalFirstNineLegs > 0
        ? (_totalFirstNinePoints / (_totalFirstNineLegs * 9)) * 3
        : null;
    return {
      'firstNinePpr': ppr,
      'totalFirstNineLegs': _totalFirstNineLegs,
    };
  }
}
