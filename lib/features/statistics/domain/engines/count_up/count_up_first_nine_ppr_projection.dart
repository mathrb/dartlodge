import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// First-9 PPR for count-up — average score over the player's first 3 turns
/// of each leg. Mirrors `X01FirstNinePprProjection`. Count-up always has
/// exactly 1 leg, but the LegCompleted reset semantic keeps the per-leg
/// tally clean across replay.
class CountUpFirstNinePprProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'count_up.firstNineAverage',
    supportedGameTypes: {GameType.countUp},
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
        final seg = (event.payload['segment'] as num?)?.toInt();
        final mult = (event.payload['multiplier'] as num?)?.toInt();
        final score = (seg != null && mult != null)
            ? seg * mult
            : (event.payload['score'] as num?)?.toInt() ?? 0;
        _currentTurnScore += score;
      case 'TurnEnded':
        if (!_inFirstNine) return;
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _totalFirstNinePoints += _currentTurnScore;
        _currentTurnScore = 0;
      case 'LegCompleted':
        if (_turnIndexInLeg >= 1) {
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
      // `_inFirstNine` is derived state (set by `apply(TurnStarted)` based on
      // `_turnIndexInLeg`); intentionally NOT cleared here to avoid depending
      // on runner reset/apply ordering. `apply` is the only writer.
      _currentTurnScore = 0;
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
