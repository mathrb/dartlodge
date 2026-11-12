import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_finish_tracker.dart';

/// Tracks average checkout score (mean of all successful checkout values).
/// A leg won on the round cap is not a checkout ([X01FinishTracker]).
class X01AvgCheckoutScoreProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.avgCheckoutScore',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {
      'TurnStarted',
      'DartThrown',
      'TurnEnded',
      'LegCompleted',
    },
    scope: ProjectionScope.career,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  X01FinishTracker _finish = X01FinishTracker(null);
  int _checkoutScoreSum = 0;
  int _checkoutCount = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _finish = X01FinishTracker(context.playerId);
    _checkoutScoreSum = 0;
    _checkoutCount = 0;
  }

  @override
  void apply(GameEvent event) {
    _finish.apply(event);
    if (event.eventType != 'LegCompleted') return;
    final winnerId = event.payload['winner_player_id'] as String?;
    if (winnerId != _context?.playerId) return;
    if (!_finish.lastVisitCheckedOut) return;
    _checkoutScoreSum += _finish.lastVisitStartingScore ?? 0;
    _checkoutCount++;
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative career stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'avgCheckoutScore':
          _checkoutCount > 0 ? _checkoutScoreSum / _checkoutCount : null,
    };
  }
}
