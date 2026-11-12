import 'dart:math';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_finish_tracker.dart';

/// Highest checkout: the largest visit starting score the player finished a
/// leg from. A leg won on the round cap is not a checkout ([X01FinishTracker]).
class X01HighestCheckoutProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01_highest_checkout',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {
      'TurnStarted',
      'DartThrown',
      'TurnEnded',
      'LegCompleted',
    },
    scope: ProjectionScope.match,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _highestCheckout = 0;
  X01FinishTracker _finish = X01FinishTracker(null);

  @override
  void init(ProjectionContext context) {
    _context = context;
    _highestCheckout = 0;
    _finish = X01FinishTracker(context.playerId);
  }

  @override
  void apply(GameEvent event) {
    _finish.apply(event);
    if (event.eventType != 'LegCompleted') return;
    final winnerId = event.payload['winner_player_id'] as String?;
    if (winnerId != _context?.playerId) return;
    if (!_finish.lastVisitCheckedOut) return;
    _highestCheckout =
        max(_highestCheckout, _finish.lastVisitStartingScore ?? 0);
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative career stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'highestCheckout': _highestCheckout > 0 ? _highestCheckout : null,
    };
  }
}
