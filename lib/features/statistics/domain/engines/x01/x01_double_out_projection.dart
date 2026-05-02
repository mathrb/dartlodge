import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/segment_utils.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class X01DoubleOutProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.doubleOut',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'DartThrown', 'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _doubleAttempts = 0;
  int _doubleSuccesses = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _doubleAttempts = 0;
    _doubleSuccesses = 0;
  }

  bool get _isActive => _context?.outStrategy != 'Straight Out';

  bool _isDoubleAttemptMultiplier(int multiplier) {
    final strategy = _context?.outStrategy ?? '';
    if (strategy == 'Double Out') return multiplier == 2;
    if (strategy == 'Master Out') return multiplier == 2 || multiplier == 3;
    return false;
  }

  @override
  void apply(GameEvent event) {
    if (!_isActive) return;
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final remainingAfter =
            (event.payload['remaining_after'] as num?)?.toInt() ?? -1;
        final score = (event.payload['score'] as num?)?.toInt() ?? 0;
        final preDartRemaining = remainingAfter + score;
        if (preDartRemaining <= 50) {
          final s = readSegmentFromPayload(event.payload);
          if (_isDoubleAttemptMultiplier(s.multiplier)) _doubleAttempts++;
        }
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId) _doubleSuccesses++;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative lifetime stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    if (!_isActive) return {};
    final rate = _doubleAttempts > 0
        ? (_doubleSuccesses / _doubleAttempts * 100)
        : null;
    return {
      'doubleOutSuccessRate': rate,
      'doubleAttempts': _doubleAttempts,
      'doubleSuccesses': _doubleSuccesses,
    };
  }
}
