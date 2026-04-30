import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'cricket_segment_utils.dart';

/// Tracks the best single-game hit rate across all games.
/// Hit rate = cricket darts (darts on valid targets) / total darts thrown.
class CricketBestGameHitRateProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.bestGameHitRate',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'DartThrown', 'GameCompleted'},
    scope: ProjectionScope.match,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;

  // Per-game counters
  int _gameTotalDarts = 0;
  int _gameCricketDarts = 0;

  // Career best
  double? _bestGameHitRate;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _gameTotalDarts = 0;
    _gameCricketDarts = 0;
    _bestGameHitRate = null;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _gameTotalDarts++;
        final s = readSegmentFromPayload(event.payload);
        if (isCricketTargetNumeric(s.segment)) {
          _gameCricketDarts++;
        }
      case 'GameCompleted':
        if (_gameTotalDarts > 0) {
          final gameHitRate = _gameCricketDarts / _gameTotalDarts;
          if (_bestGameHitRate == null || gameHitRate > _bestGameHitRate!) {
            _bestGameHitRate = gameHitRate;
          }
        }
        _gameTotalDarts = 0;
        _gameCricketDarts = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.match) {
      _gameTotalDarts = 0;
      _gameCricketDarts = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {'bestGameHitRate': _bestGameHitRate};
  }
}
