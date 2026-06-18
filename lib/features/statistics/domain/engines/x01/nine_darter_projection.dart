import 'dart:math';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// Detects a "nine-darter": a 501 X01 leg the player finished in exactly 9
/// darts (#521/#524). Career-cumulative — it never forgets a past nine-darter.
///
/// Per leg it captures the leg's starting score (the max `starting_score` seen
/// on the player's `TurnStarted`s — the leg opener is 501) and counts the
/// player's `DartThrown`s. On `LegCompleted`, a leg counts when the player won
/// it, threw exactly 9 darts, and started from 501. Per-leg state resets on the
/// leg (and match) boundary; the cumulative result persists.
///
/// Solo-game filtering (`ProjectionContext.soloGameIds`) is deliberately NOT
/// applied: a nine-darter is a shot-quality feat, valid in solo practice too.
class NineDarterProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.nineDarter',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'DartThrown', 'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  bool _hasNineDarter = false;
  int _count = 0;
  int _dartsInLeg = 0;
  int? _legStartingScore;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _hasNineDarter = false;
    _count = 0;
    _dartsInLeg = 0;
    _legStartingScore = null;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final startingScore = (event.payload['starting_score'] as num?)?.toInt();
        if (startingScore != null) {
          _legStartingScore = max(_legStartingScore ?? 0, startingScore);
        }
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _dartsInLeg++;
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId &&
            _dartsInLeg == 9 &&
            _legStartingScore == 501) {
          _hasNineDarter = true;
          _count++;
        }
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // Per-leg counters reset on the leg boundary; the cumulative result lives
    // on. Also clear on the match boundary so a game abandoned mid-leg (a
    // GameCompleted with no preceding LegCompleted) can't bleed darts into the
    // next game's first leg.
    if (scope == ProjectionScope.leg || scope == ProjectionScope.match) {
      _dartsInLeg = 0;
      _legStartingScore = null;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'hasNineDarter': _hasNineDarter,
      'nineDarterCount': _count,
    };
  }
}
