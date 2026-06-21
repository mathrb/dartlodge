import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'cricket_targets_mixin.dart';

/// Computes Marks Per Round (MPR) for the first 9 darts (first 3 turns) of each leg.
/// Mirrors X01FirstNinePprProjection but counts cricket marks instead of score.
class CricketFirstNineMprProjection extends ProjectionEngine
    with CricketTargetsTracker {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.firstNineMpr',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {
      'GameCreated',
      'CricketTargetsAssigned',
      'CrazyTargetsRolled',
      'TurnStarted',
      'DartThrown',
      'TurnEnded',
      'LegCompleted',
    },
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
    resetCricketTargets();
  }

  @override
  void apply(GameEvent event) {
    if (maybeApplyCricketTargets(event)) return;
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _turnIndexInLeg++;
        _inFirstNine = _turnIndexInLeg <= 3;
        _currentTurnMarks = 0;
      case 'DartThrown':
        // #638: record closure for EVERY dart (keeps the cross-competitor
        // accumulator complete), but credit dead-aware marks only inside the
        // first-nine window. cricketScopedMarksForDart returns 0 for other
        // players and for hits on a number already closed by all.
        final marks = cricketScopedMarksForDart(event, _context?.playerId);
        if (_inFirstNine) _currentTurnMarks += marks;
      case 'TurnEnded':
        if (!_inFirstNine) return;
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _totalFirstNineMarks += _currentTurnMarks;
        _currentTurnMarks = 0;
      case 'LegCompleted':
        // First-9 MPR divides total first-nine marks by `legs × 3`. Only
        // count a leg when at least 3 turns were started — otherwise the
        // denominator credits the player with darts they never had a
        // chance to throw, inflating the MPR. Mirrors the
        // `X01FirstNinePprProjection` gate from #290.
        if (_turnIndexInLeg >= 3) {
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
      // `_inFirstNine` is derived state (set by `apply(TurnStarted)` based on
      // `_turnIndexInLeg`); intentionally NOT cleared here to avoid depending
      // on runner reset/apply ordering. `apply` is the only writer.
      _currentTurnMarks = 0;
    }
    if (scope == ProjectionScope.leg) {
      _turnIndexInLeg = 0;
      _inFirstNine = false;
      _currentTurnMarks = 0;
      resetCricketClosureForLeg(); // #638
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
