import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'cricket_targets_mixin.dart';

/// Computes Marks Per Turn (MPT) — the primary cricket metric.
/// A mark is one hit on a valid cricket target (15–20, Bull).
/// Throwing T20 = 3 marks; DB = 2 marks (Bull = 25 → 1 mark, but hit value
/// is determined by multiplier on segment value).
/// MPT = total marks / total turns.
class CricketMarksPerTurnProjection extends ProjectionEngine
    with CricketTargetsTracker {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.mpt',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {
      'GameCreated',
      'CricketTargetsAssigned',
      'CrazyTargetsRolled',
      'DartThrown',
      'TurnEnded',
    },
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _totalMarks = 0;
  int _totalTurns = 0;
  int _turnMarks = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _totalMarks = 0;
    _totalTurns = 0;
    _turnMarks = 0;
    resetCricketTargets();
  }

  @override
  void apply(GameEvent event) {
    if (maybeApplyCricketTargets(event)) return;
    switch (event.eventType) {
      case 'DartThrown':
        // #638: dead-number-aware. Records every competitor's hit (kept
        // complete across players) and credits 0 for a hit on a number already
        // closed by all. Must run for ALL darts, so no player early-return.
        _turnMarks += cricketScopedMarksForDart(event, _context?.playerId);
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _totalMarks += _turnMarks;
        _totalTurns++;
        _turnMarks = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _turnMarks = 0;
    }
    if (scope == ProjectionScope.leg) {
      // Board resets each leg → reset the dead-number closure accumulator (#638).
      resetCricketClosureForLeg();
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    final mpt = _totalTurns > 0 ? _totalMarks / _totalTurns : 0.0;
    return {
      'marksPerTurn': mpt,
      'totalMarks': _totalMarks,
      'totalTurns': _totalTurns,
    };
  }
}

