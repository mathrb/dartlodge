import 'dart:math';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// Tracks best single-leg PPR and best single-leg First 9 PPR across all legs.
///
/// Both metrics use the per-turn `turn_score` delta (`turn_start - turn_end`,
/// 0 on a bust) — the SAME convention as `X01AverageProjection` per
/// docs/statistics/x01.projections.md §5.2 (#318/#610). Leg PPR is NOT derived
/// from the leg's starting score: an X01 handicap is baked into the
/// `starting_score` payload, so a starting-score-based PPR would credit points
/// the handicap granted rather than threw. The `turn_score` delta is equally
/// handicap-independent (it is the turn's own start-minus-end), and additionally
/// scores busted turns as 0 so best-leg PPR matches the player's 3-dart average.
/// Legacy events lacking `turn_score` fall back to the dart-score sum, keeping
/// pre-#318 game numbers unchanged. See issues #246 / #318 / #610.
class X01BestLegPprProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.bestLegPpr',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {
      'TurnStarted',
      'DartThrown',
      'TurnEnded',
      'LegCompleted',
    },
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;

  // Per-leg state.
  int _legScore = 0;
  int _legDartsCount = 0;
  int _turnIndex = 0;
  int _firstNineScore = 0;
  int _currentTurnScore = 0;

  // Career bests.
  double? _bestLegPpr;
  double? _bestFirstNinePpr;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _resetLeg();
    _bestLegPpr = null;
    _bestFirstNinePpr = null;
  }

  void _resetLeg() {
    _legScore = 0;
    _legDartsCount = 0;
    _turnIndex = 0;
    _firstNineScore = 0;
    _currentTurnScore = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _turnIndex++;
        _currentTurnScore = 0;
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _legDartsCount++;
        final seg = (event.payload['segment'] as num?)?.toInt();
        final mult = (event.payload['multiplier'] as num?)?.toInt();
        final score = (seg != null && mult != null)
            ? seg * mult
            : (event.payload['score'] as num?)?.toInt() ?? 0;
        _currentTurnScore += score;
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        // Prefer the `turn_score` delta (0 on a bust / Double-In not-in turn),
        // matching X01AverageProjection per §5.2; fall back to the dart-sum for
        // legacy events that predate the field (#318/#610).
        final delta =
            (event.payload['turn_score'] as num?)?.toInt() ?? _currentTurnScore;
        _legScore += delta;
        if (_turnIndex <= 3) {
          _firstNineScore += delta;
        }
        _currentTurnScore = 0;
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId && _legDartsCount > 0) {
          final legPpr = _legScore / _legDartsCount * 3;
          _bestLegPpr =
              _bestLegPpr == null ? legPpr : max(_bestLegPpr!, legPpr);
          if (_turnIndex >= 3) {
            final firstNinePpr = _firstNineScore / 9 * 3;
            _bestFirstNinePpr = _bestFirstNinePpr == null
                ? firstNinePpr
                : max(_bestFirstNinePpr!, firstNinePpr);
          }
        }
        _resetLeg();
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // Reset on both leg and match boundaries: abandoned X01 games end with
    // GameCompleted (match scope) but no LegCompleted (leg scope). Without
    // the match-scope reset, an abandoned game's per-turn dart scores stay
    // accumulated in _legScore/_legDartsCount and bleed into the next game's
    // legPpr — yielding a "best leg PPR" that's actually a multi-game
    // weighted average. See #280.
    if (scope == ProjectionScope.leg || scope == ProjectionScope.match) {
      _resetLeg();
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
