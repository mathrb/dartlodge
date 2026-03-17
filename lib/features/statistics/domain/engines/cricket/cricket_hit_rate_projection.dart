import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

/// Computes hit rate: fraction of darts that land on a valid cricket target.
/// hitRate = cricketDarts / totalDarts (0.0–1.0).
class CricketHitRateProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.hitRate',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'DartThrown'},
    scope: ProjectionScope.career,
  );

  static const _cricketTargets = {15, 16, 17, 18, 19, 20, 25};

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _totalDarts = 0;
  int _cricketDarts = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _totalDarts = 0;
    _cricketDarts = 0;
  }

  @override
  void apply(GameEvent event) {
    if (event.eventType != 'DartThrown') return;
    final playerId = event.payload['player_id'] as String?;
    if (playerId != _context?.playerId) return;
    _totalDarts++;
    final segment = event.payload['segment'] as String?;
    if (segment != null && _isTargetSegment(segment)) {
      _cricketDarts++;
    }
  }

  bool _isTargetSegment(String segment) {
    if (segment == 'DB' || segment == 'SB') return true;
    if (segment == 'MISS') return false;
    String stripped = segment;
    if (segment.startsWith('T') || segment.startsWith('D')) {
      stripped = segment.substring(1);
    }
    final n = int.tryParse(stripped);
    return n != null && _cricketTargets.contains(n);
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative lifetime stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    final rate = _totalDarts > 0 ? _cricketDarts / _totalDarts : 0.0;
    return {
      'hitRate': rate,
      'cricketDarts': _cricketDarts,
      'totalDarts': _totalDarts,
    };
  }
}
