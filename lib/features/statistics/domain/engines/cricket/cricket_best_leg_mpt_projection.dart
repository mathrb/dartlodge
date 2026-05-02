import 'dart:math';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'cricket_segment_utils.dart';

/// Tracks the best single-leg MPT (Marks Per Turn) across all legs.
class CricketBestLegMptProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.bestLegMpt',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'DartThrown', 'TurnEnded', 'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;

  // Per-leg state
  int _legMarks = 0;
  int _legTurns = 0;
  int _turnMarks = 0;

  // Career best
  double? _bestLegMpt;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _legMarks = 0;
    _legTurns = 0;
    _turnMarks = 0;
    _bestLegMpt = null;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final s = readSegmentFromPayload(event.payload);
        _turnMarks += cricketMarksFromPayload(s.segment, s.multiplier);
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _legMarks += _turnMarks;
        _legTurns++;
        _turnMarks = 0;
      case 'LegCompleted':
        if (_legTurns > 0) {
          final legMpt = _legMarks / _legTurns;
          _bestLegMpt =
              _bestLegMpt == null ? legMpt : max(_bestLegMpt!, legMpt);
        }
        // Reset per-leg state
        _legMarks = 0;
        _legTurns = 0;
        _turnMarks = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.leg) {
      _legMarks = 0;
      _legTurns = 0;
      _turnMarks = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {'bestLegMpt': _bestLegMpt};
  }
}
