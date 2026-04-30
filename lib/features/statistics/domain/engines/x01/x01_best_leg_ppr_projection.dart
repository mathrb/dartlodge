import 'dart:math';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// Tracks best single-leg PPR and best single-leg First 9 PPR across all legs.
class X01BestLegPprProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.bestLegPpr',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'DartThrown', 'TurnEnded', 'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;

  // Per-leg state (null legStartingScore means not yet captured)
  int? _legStartingScore;
  int _legDartsCount = 0;
  int _turnIndex = 0;
  int _firstNineScore = 0;
  int _currentTurnScore = 0;

  // Career bests
  double? _bestLegPpr;
  double? _bestFirstNinePpr;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _legStartingScore = null;
    _legDartsCount = 0;
    _turnIndex = 0;
    _firstNineScore = 0;
    _currentTurnScore = 0;
    _bestLegPpr = null;
    _bestFirstNinePpr = null;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _turnIndex++;
        _currentTurnScore = 0;
        _legStartingScore ??=
            (event.payload['starting_score'] as num?)?.toInt() ?? 0;
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _legDartsCount++;
        if (_turnIndex <= 3) {
          final seg = (event.payload['segment'] as num?)?.toInt();
          final mult = (event.payload['multiplier'] as num?)?.toInt();
          final score = (seg != null && mult != null)
              ? seg * mult
              : (event.payload['score'] as num?)?.toInt() ?? 0;
          _currentTurnScore += score;
        }
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        if (_turnIndex <= 3) {
          final reason = event.payload['reason'] as String?;
          if (reason != 'bust') {
            _firstNineScore += _currentTurnScore;
          }
          _currentTurnScore = 0;
        }
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId &&
            _legStartingScore != null &&
            _legDartsCount > 0) {
          final legPpr = _legStartingScore! / _legDartsCount * 3;
          _bestLegPpr =
              _bestLegPpr == null ? legPpr : max(_bestLegPpr!, legPpr);
          if (_turnIndex >= 3) {
            final firstNinePpr = _firstNineScore / 9 * 3;
            _bestFirstNinePpr = _bestFirstNinePpr == null
                ? firstNinePpr
                : max(_bestFirstNinePpr!, firstNinePpr);
          }
        }
        // Reset per-leg state
        _legStartingScore = null;
        _legDartsCount = 0;
        _turnIndex = 0;
        _firstNineScore = 0;
        _currentTurnScore = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.leg) {
      _legStartingScore = null;
      _legDartsCount = 0;
      _turnIndex = 0;
      _firstNineScore = 0;
      _currentTurnScore = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'bestLegPpr': _bestLegPpr,
      'bestFirstNinePpr': _bestFirstNinePpr,
    };
  }
}
